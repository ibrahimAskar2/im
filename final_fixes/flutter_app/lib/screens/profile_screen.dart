import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.userData?['name'] ?? '');
    _phoneController = TextEditingController(text: userProvider.userData?['phone'] ?? '');
    _bioController = TextEditingController(text: userProvider.userData?['bio'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // حفظ التغييرات
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
      };
      
      final success = await userProvider.updateUserData(userData);
      
      if (success && mounted) {
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات بنجاح')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ التغييرات')),
        );
      }
    }
  }

  // تحديث صورة الملف الشخصي
  Future<void> _updateProfileImage() async {
    // في التطبيق الفعلي، سيتم هنا فتح معرض الصور لاختيار صورة جديدة
    // ثم رفعها إلى Firebase Storage وتحديث رابط الصورة في Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userProvider.user;
          final userData = userProvider.userData;
          
          if (user == null || userData == null) {
            return const Center(
              child: Text('لم يتم العثور على بيانات المستخدم'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // صورة الملف الشخصي
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: userData['profileImage'] != null
                            ? NetworkImage(userData['profileImage'])
                            : null,
                        child: userData['profileImage'] == null
                            ? Text(
                                userData['name']?.isNotEmpty == true
                                    ? userData['name'][0]
                                    : 'م',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: _updateProfileImage,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // معلومات المستخدم
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المعلومات الشخصية',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // الاسم
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'الرجاء إدخال الاسم';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // البريد الإلكتروني
                          TextFormField(
                            initialValue: user.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // رقم الهاتف
                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // نبذة شخصية
                          TextFormField(
                            controller: _bioController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'نبذة شخصية',
                              prefixIcon: Icon(Icons.info),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // معلومات إضافية
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'معلومات العمل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // المسمى الوظيفي
                          ListTile(
                            leading: const Icon(Icons.work),
                            title: const Text('المسمى الوظيفي'),
                            subtitle: Text(userData['jobTitle'] ?? 'غير محدد'),
                          ),
                          
                          const Divider(),
                          
                          // القسم
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('القسم'),
                            subtitle: Text(userData['department'] ?? 'غير محدد'),
                          ),
                          
                          const Divider(),
                          
                          // تاريخ الانضمام
                          ListTile(
                            leading: const Icon(Icons.date_range),
                            title: const Text('تاريخ الانضمام'),
                            subtitle: Text(userData['joinDate'] ?? 'غير محدد'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
