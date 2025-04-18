import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reference_model.dart';
import '../providers/reference_provider.dart';
import '../providers/user_provider.dart';

class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  String? _selectedCategory;
  String? _selectedDepartment;
  String _searchQuery = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
      referenceProvider.loadReferences();
      
      // التحقق مما إذا كان المستخدم مشرفًا
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        _isAdmin = userProvider.user?.role == 'admin';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المرجعيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddEditReferenceDialog(context);
              },
            ),
        ],
      ),
      body: Consumer<ReferenceProvider>(
        builder: (context, referenceProvider, child) {
          if (referenceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (referenceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    referenceProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      referenceProvider.loadReferences();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final filteredReferences = referenceProvider.searchReferences(
            query: _searchQuery.isEmpty ? null : _searchQuery,
            category: _selectedCategory,
            department: _selectedDepartment,
          );

          if (filteredReferences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.folder_open,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد مرجعيات متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (_isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAddEditReferenceDialog(context);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة مرجع جديد'),
                      ),
                    ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // شريط التصفية
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('تصفية: '),
                      const SizedBox(width: 8),
                      
                      // تصفية حسب التصنيف
                      ChoiceChip(
                        label: Text(_selectedCategory ?? 'التصنيف'),
                        selected: _selectedCategory != null,
                        onSelected: (selected) {
                          if (selected) {
                            _showCategoryFilterDialog(context);
                          } else {
                            setState(() {
                              _selectedCategory = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      // تصفية حسب القسم
                      ChoiceChip(
                        label: Text(_selectedDepartment ?? 'القسم'),
                        selected: _selectedDepartment != null,
                        onSelected: (selected) {
                          if (selected) {
                            _showDepartmentFilterDialog(context);
                          } else {
                            setState(() {
                              _selectedDepartment = null;
                            });
                          }
                        },
                      ),
                      
                      // إعادة تعيين التصفية
                      if (_selectedCategory != null || _selectedDepartment != null || _searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedDepartment = null;
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('إعادة تعيين'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // قائمة المراجع
              Expanded(
                child: ListView.builder(
                  itemCount: filteredReferences.length,
                  itemBuilder: (context, index) {
                    final reference = filteredReferences[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(
                          reference.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'التصنيف: ${reference.category} | القسم: ${reference.department}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              'آخر تحديث: ${reference.formattedUpdateTime}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: _isAdmin
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showAddEditReferenceDialog(context, reference: reference);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmationDialog(context, reference);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('تعديل'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('حذف', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                        onTap: () {
                          _showReferenceDetailsDialog(context, reference);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showAddEditReferenceDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // عرض مربع حوار البحث
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          title: const Text('بحث في المرجعيات'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'أدخل كلمات البحث',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              searchText = value;
            },
            controller: TextEditingController(text: _searchQuery),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = searchText;
                });
                Navigator.pop(context);
              },
              child: const Text('بحث'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار تصفية التصنيفات
  void _showCategoryFilterDialog(BuildContext context) {
    final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
    final categories = ['الكل', ...referenceProvider.categories];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تصفية حسب التصنيف'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return RadioListTile<String?>(
                  title: Text(category == 'الكل' ? 'الكل' : category),
                  value: category == 'الكل' ? null : category,
                  groupValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // عرض مربع حوار تصفية الأقسام
  void _showDepartmentFilterDialog(BuildContext context) {
    final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
    final departments = ['الكل', ...referenceProvider.departments];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تصفية حسب القسم'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final department = departments[index];
                return RadioListTile<String?>(
                  title: Text(department == 'الكل' ? 'الكل' : department),
                  value: department == 'الكل' ? null : department,
                  groupValue: _selectedDepartment,
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // عرض مربع حوار تفاصيل المرجع
  void _showReferenceDetailsDialog(BuildContext context, Reference reference) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(reference.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 16),
                      const SizedBox(width: 4),
                      Text('التصنيف: ${reference.category}'),
                      const Spacer(),
                      const Icon(Icons.business, size: 16),
                      const SizedBox(width: 4),
                      Text('القسم: ${reference.department}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'المحتوى:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(reference.content),
                ),
                if (reference.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'الوسوم:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: reference.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue[100],
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'تم الإنشاء بواسطة: ${reference.creatorName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'آخر تحديث: ${reference.formattedUpdateTime}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إغلاق'),
            ),
            if (_isAdmin)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditReferenceDialog(context, reference: reference);
                },
                child: const Text('تعديل'),
              ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار إضافة/تعديل مرجع
  void _showAddEditReferenceDialog(BuildContext context, {Reference? reference}) {
    final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final titleController = TextEditingController(text: reference?.title ?? '');
    final contentController = TextEditingController(text: reference?.content ?? '');
    final categoryController = TextEditingController(text: reference?.category ?? '');
    final departmentController = TextEditingController(text: reference?.department ?? '');
    final tagsController = TextEditingController(
      text: reference?.tags.isNotEmpty == true ? reference!.tags.join(', ') : '',
    );
    
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(reference == null ? 'إضافة مرجع جديد' : 'تعديل المرجع'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال العنوان';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'المحتوى',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال المحتوى';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: categoryController,
                          decoration: const InputDecoration(
                            labelText: 'التصنيف',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.category),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال التصنيف';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: () {
                          _showCategoriesListDialog(context, categoryController);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: departmentController,
                          decoration: const InputDecoration(
                            labelText: 'القسم',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال القسم';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: () {
                          _showDepartmentsListDialog(context, departmentController);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'الوسوم (مفصولة بفواصل)',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: قواعد, إرشادات, مهم',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final tags = tagsController.text.isEmpty
                      ? <String>[]
                      : tagsController.text.split(',').map((e) => e.trim()).toList();
                  
                  if (reference == null) {
                    // إضافة مرجع جديد
                    final success = await referenceProvider.addReference(
                      title: titleController.text,
                      content: contentController.text,
                      category: categoryController.text,
                      department: departmentController.text,
                      creatorId: userProvider.user!.id,
                      creatorName: userProvider.user!.name,
                      tags: tags,
                    );
                    
                    if (success != null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إضافة المرجع بنجاح')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(referenceProvider.error ?? 'حدث خطأ أثناء إضافة المرجع')),
                      );
                    }
                  } else {
                    // تحديث مرجع موجود
                    final success = await referenceProvider.updateReference(
                      id: reference.id,
                      title: titleController.text,
                      content: contentController.text,
                      category: categoryController.text,
                      department: departmentController.text,
                      tags: tags,
                    );
                    
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديث المرجع بنجاح')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(referenceProvider.error ?? 'حدث خطأ أثناء تحديث المرجع')),
                      );
                    }
                  }
                }
              },
              child: Text(reference == null ? 'إضافة' : 'تحديث'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار قائمة التصنيفات
  void _showCategoriesListDialog(BuildContext context, TextEditingController controller) {
    final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
    final categories = referenceProvider.categories;
    
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تصنيفات متاحة')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر التصنيف'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    controller.text = category;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار قائمة الأقسام
  void _showDepartmentsListDialog(BuildContext context, TextEditingController controller) {
    final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
    final departments = referenceProvider.departments;
    
    if (departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أقسام متاحة')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر القسم'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: departments.length,
              itemBuilder: (context, index) {
                final department = departments[index];
                return ListTile(
                  title: Text(department),
                  onTap: () {
                    controller.text = department;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار تأكيد الحذف
  void _showDeleteConfirmationDialog(BuildContext context, Reference reference) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف المرجع "${reference.title}"؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final referenceProvider = Provider.of<ReferenceProvider>(context, listen: false);
                final success = await referenceProvider.deleteReference(reference.id);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المرجع بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(referenceProvider.error ?? 'حدث خطأ أثناء حذف المرجع')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}
