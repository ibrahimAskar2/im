import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdmin = false;
  String? _userId;
  String? _userName;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      setState(() {
        _isAdmin = userProvider.user?.role == 'admin';
        _userId = userProvider.user?.id;
        _userName = userProvider.user?.name;
      });
      
      if (_isAdmin) {
        taskProvider.loadAllTasks();
      }
      
      if (_userId != null) {
        taskProvider.loadUserTasks(_userId!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _isAdmin ? 'جميع المهام' : 'مهامي'),
            const Tab(text: 'سجل المهام'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddTaskDialog(context);
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // علامة التبويب الأولى: المهام النشطة
          _buildActiveTasksTab(),
          
          // علامة التبويب الثانية: سجل المهام
          _buildTasksHistoryTab(),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showAddTaskDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // بناء علامة تبويب المهام النشطة
  Widget _buildActiveTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (taskProvider.error != null) {
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
                  taskProvider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_isAdmin) {
                      taskProvider.loadAllTasks();
                    } else if (_userId != null) {
                      taskProvider.loadUserTasks(_userId!);
                    }
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final tasks = _isAdmin
            ? taskProvider.tasks
            : taskProvider.userTasks;
        
        // تصفية المهام حسب الحالة
        List<Task> filteredTasks = [];
        if (_selectedFilter == 'all') {
          filteredTasks = tasks.where((task) => 
            task.status != 'completed' && task.status != 'canceled'
          ).toList();
        } else if (_selectedFilter == 'pending') {
          filteredTasks = tasks.where((task) => task.status == 'pending').toList();
        } else if (_selectedFilter == 'in_progress') {
          filteredTasks = tasks.where((task) => task.status == 'in_progress').toList();
        } else if (_selectedFilter == 'urgent') {
          filteredTasks = tasks.where((task) {
            final isUrgent = task.metadata?['isUrgent'] == true;
            return isUrgent && task.status != 'completed' && task.status != 'canceled';
          }).toList();
        }

        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.task_alt,
                  color: Colors.grey,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد مهام متاحة',
                  style: TextStyle(color: Colors.grey),
                ),
                if (_isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddTaskDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة مهمة جديدة'),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            final isUrgent = task.metadata?['isUrgent'] == true;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isUrgent
                    ? const BorderSide(color: Colors.red, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title.isEmpty ? 'مهمة بدون عنوان' : task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isUrgent)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.priority_high,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(task.priorityColor).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.priorityText,
                            style: TextStyle(
                              color: Color(task.priorityColor),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.statusText,
                            style: TextStyle(
                              color: _getStatusColor(task.status),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: task.isOverdue ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isOverdue ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  _showTaskDetailsDialog(context, task);
                },
              ),
            );
          },
        );
      },
    );
  }

  // بناء علامة تبويب سجل المهام
  Widget _buildTasksHistoryTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final tasks = _isAdmin
            ? taskProvider.tasks
            : taskProvider.userTasks;
        
        // تصفية المهام المكتملة أو الملغاة
        final completedTasks = tasks.where((task) => 
          task.status == 'completed' || task.status == 'canceled'
        ).toList();

        if (completedTasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: Colors.grey,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  'لا يوجد سجل للمهام',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: completedTasks.length,
          itemBuilder: (context, index) {
            final task = completedTasks[index];
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: task.status == 'canceled' 
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: ListTile(
                title: Text(
                  task.title.isEmpty ? 'مهمة بدون عنوان' : task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: task.status == 'canceled' ? Colors.grey : null,
                    decoration: task.status == 'canceled' 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.status == 'canceled' ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(task.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.statusText,
                            style: TextStyle(
                              color: _getStatusColor(task.status),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.assigneeName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: task.status == 'completed'
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.cancel,
                        color: Colors.grey,
                      ),
                onTap: () {
                  _showTaskDetailsDialog(context, task);
                },
              ),
            );
          },
        );
      },
    );
  }

  // عرض مربع حوار تفاصيل المهمة
  void _showTaskDetailsDialog(BuildContext context, Task task) {
    final isUrgent = task.metadata?['isUrgent'] == true;
    final completionDetails = task.metadata?['completionDetails'] as String? ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title.isEmpty ? 'مهمة بدون عنوان' : task.title,
                ),
              ),
              if (isUrgent)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // معلومات المهمة
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('المكلف: ${task.assigneeName}'),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text('تاريخ الاستحقاق: ${_formatDate(task.dueDate)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 16),
                          const SizedBox(width: 4),
                          Text('الأولوية: ${task.priorityText}'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(task.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.statusText,
                              style: TextStyle(
                                color: _getStatusColor(task.status),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // وصف المهمة
                const Text(
                  'الوصف:',
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
                  child: Text(task.description),
                ),
                
                // تفاصيل الإنجاز (إذا كانت المهمة مكتملة)
                if (task.status == 'completed' && completionDetails.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'تفاصيل الإنجاز:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(completionDetails),
                  ),
                ],
                
                // التعليقات
                if (task.comments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'التعليقات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...task.comments.map((comment) {
                    final timestamp = (comment['timestamp'] as Timestamp).toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment['userName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                _formatDateTime(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment['text']),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                
                // معلومات إضافية
                const SizedBox(height: 16),
                Text(
                  'تم الإنشاء بواسطة: ${task.assignerName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'تاريخ الإنشاء: ${_formatDateTime(task.createdAt)}',
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
            if (task.status != 'completed' && task.status != 'canceled' && !_isAdmin && _userId == task.assigneeId)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCompleteTaskDialog(context, task);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إنجاز المهمة'),
              ),
            if (_isAdmin && task.status != 'completed' && task.status != 'canceled')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showUpdateTaskStatusDialog(context, task);
                },
                child: const Text('تحديث الحالة'),
              ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار إضافة مهمة جديدة
  void _showAddTaskDialog(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    
    String? selectedAssigneeId;
    String selectedAssigneeName = '';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    int priority = 2;
    bool isUrgent = false;
    
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إضافة مهمة جديدة'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'العنوان (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال وصف المهمة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // اختيار الموظف المكلف
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'الموظف المكلف',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAssigneeId,
                        items: [
                          // هنا يجب إضافة قائمة الموظفين من قاعدة البيانات
                          // مثال:
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('اختر الموظف'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'user1',
                            child: Text('أحمد محمد'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'user2',
                            child: Text('محمد علي'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'user3',
                            child: Text('سارة أحمد'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedAssigneeId = value;
                            if (value == 'user1') {
                              selectedAssigneeName = 'أحمد محمد';
                            } else if (value == 'user2') {
                              selectedAssigneeName = 'محمد علي';
                            } else if (value == 'user3') {
                              selectedAssigneeName = 'سارة أحمد';
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'يرجى اختيار الموظف المكلف';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // اختيار تاريخ الاستحقاق
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          
                          if (pickedDate != null) {
                            setState(() {
                              dueDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الاستحقاق',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDate(dueDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // اختيار الأولوية
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'الأولوية',
                          border: OutlineInputBorder(),
                        ),
                        value: priority,
                        items: const [
                          DropdownMenuItem<int>(
                            value: 1,
                            child: Text('منخفضة'),
                          ),
                          DropdownMenuItem<int>(
                            value: 2,
                            child: Text('متوسطة'),
                          ),
                          DropdownMenuItem<int>(
                            value: 3,
                            child: Text('عالية'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            priority = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // خيار المهمة المستعجلة
                      CheckboxListTile(
                        title: const Text('مهمة مستعجلة'),
                        value: isUrgent,
                        onChanged: (value) {
                          setState(() {
                            isUrgent = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
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
                      final success = await taskProvider.addTask(
                        title: titleController.text,
                        description: descriptionController.text,
                        assignerId: userProvider.user!.id,
                        assignerName: userProvider.user!.name,
                        assigneeId: selectedAssigneeId!,
                        assigneeName: selectedAssigneeName,
                        dueDate: dueDate,
                        priority: priority,
                        isUrgent: isUrgent,
                      );
                      
                      if (success != null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إضافة المهمة بنجاح')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(taskProvider.error ?? 'حدث خطأ أثناء إضافة المهمة')),
                        );
                      }
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // عرض مربع حوار تحديث حالة المهمة (للمشرف)
  void _showUpdateTaskStatusDialog(BuildContext context, Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    String newStatus = task.status;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحديث حالة المهمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('قيد الانتظار'),
                value: 'pending',
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value!;
                  Navigator.pop(context);
                  _confirmUpdateTaskStatus(context, task, newStatus);
                },
              ),
              RadioListTile<String>(
                title: const Text('قيد التنفيذ'),
                value: 'in_progress',
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value!;
                  Navigator.pop(context);
                  _confirmUpdateTaskStatus(context, task, newStatus);
                },
              ),
              RadioListTile<String>(
                title: const Text('مكتملة'),
                value: 'completed',
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value!;
                  Navigator.pop(context);
                  _confirmUpdateTaskStatus(context, task, newStatus);
                },
              ),
              RadioListTile<String>(
                title: const Text('ملغاة'),
                value: 'canceled',
                groupValue: newStatus,
                onChanged: (value) {
                  newStatus = value!;
                  Navigator.pop(context);
                  _confirmUpdateTaskStatus(context, task, newStatus);
                },
              ),
            ],
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

  // تأكيد تحديث حالة المهمة
  void _confirmUpdateTaskStatus(BuildContext context, Task task, String newStatus) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد تحديث الحالة'),
          content: Text('هل أنت متأكد من تغيير حالة المهمة إلى "${_getStatusText(newStatus)}"؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await taskProvider.updateTaskStatus(
                  taskId: task.id,
                  newStatus: newStatus,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث حالة المهمة بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(taskProvider.error ?? 'حدث خطأ أثناء تحديث حالة المهمة')),
                  );
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار إنجاز المهمة (للموظف)
  void _showCompleteTaskDialog(BuildContext context, Task task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final completionDetailsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إنجاز المهمة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يرجى إضافة تفاصيل إنجاز المهمة:'),
              const SizedBox(height: 16),
              TextField(
                controller: completionDetailsController,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل الإنجاز',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
            ],
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
                Navigator.pop(context);
                final success = await taskProvider.sendTaskCompletionNotification(
                  taskId: task.id,
                  completionDetails: completionDetailsController.text,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إنجاز المهمة وإرسال الإشعار بنجاح')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(taskProvider.error ?? 'حدث خطأ أثناء إنجاز المهمة')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('إنجاز المهمة'),
            ),
          ],
        );
      },
    );
  }

  // عرض مربع حوار التصفية
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تصفية المهام'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('جميع المهام النشطة'),
                value: 'all',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('قيد الانتظار'),
                value: 'pending',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('قيد التنفيذ'),
                value: 'in_progress',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('المهام المستعجلة'),
                value: 'urgent',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
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

  // تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  // تنسيق التاريخ والوقت
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }

  // الحصول على لون الحالة
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // الحصول على نص الحالة
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'canceled':
        return 'ملغاة';
      default:
        return status;
    }
  }
}
