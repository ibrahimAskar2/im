import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'ar';

  @override
  void initState() {
    super.initState();
    // في التطبيق الفعلي، سيتم هنا تحميل الإعدادات المحفوظة
    _loadSettings();
  }

  // تحميل الإعدادات
  Future<void> _loadSettings() async {
    // في التطبيق الفعلي، سيتم هنا تحميل الإعدادات من SharedPreferences
    setState(() {
      _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }

  // تغيير وضع السمة (فاتح/داكن)
  void _toggleThemeMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    // في التطبيق الفعلي، سيتم هنا حفظ الإعداد وتغيير السمة
  }

  // تغيير اللغة
  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    // في التطبيق الفعلي، سيتم هنا حفظ الإعداد وتغيير اللغة
  }

  // تسجيل الخروج
  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // قسم المظهر
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
                    'المظهر',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // الوضع الليلي
                  SwitchListTile(
                    title: const Text('الوضع الليلي'),
                    subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
                    value: _isDarkMode,
                    onChanged: _toggleThemeMode,
                    secondary: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: _isDarkMode ? Colors.amber : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قسم اللغة
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
                    'اللغة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // اختيار اللغة
                  RadioListTile<String>(
                    title: const Text('العربية'),
                    value: 'ar',
                    groupValue: _selectedLanguage,
                    onChanged: (value) => _changeLanguage(value!),
                    secondary: const Icon(Icons.language),
                  ),
                  
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: _selectedLanguage,
                    onChanged: (value) => _changeLanguage(value!),
                    secondary: const Icon(Icons.language),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قسم الحساب
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
                    'الحساب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // تغيير كلمة المرور
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('تغيير كلمة المرور'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // في التطبيق الفعلي، سيتم هنا فتح شاشة تغيير كلمة المرور
                    },
                  ),
                  
                  const Divider(),
                  
                  // تسجيل الخروج
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قسم حول التطبيق
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
                    'حول التطبيق',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات التطبيق
                  ListTile(
                    title: const Text('فريق الأنصار'),
                    subtitle: const Text('الإصدار 1.0.0'),
                  ),
                  
                  const Divider(),
                  
                  // مطور التطبيق
                  const ListTile(
                    title: Text('مطور التطبيق'),
                    subtitle: Text('إبراهيم عسكر'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
