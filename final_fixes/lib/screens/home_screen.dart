import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // قائمة الشاشات التي سيتم عرضها في التبويبات
  final List<Widget> _screens = [
    const MainDashboard(),
    const ChatsList(),
    const StatisticsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'الدردشات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'الإحصائيات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// شاشة لوحة المعلومات الرئيسية
class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فريق الأنصار'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // عرض الإشعارات
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة ترحيب
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مرحباً، أحمد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'آخر تسجيل دخول: اليوم 08:30 صباحاً',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // أزرار تسجيل الدخول والخروج
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // عرض مربع حوار للتأكيد
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تأكيد تسجيل الدخول'),
                            content: const Text('هل أنت متأكد من تسجيل الدخول؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // تسجيل الدخول
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تسجيل الدخول بنجاح'),
                                    ),
                                  );
                                },
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('تسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // عرض مربع حوار للتأكيد
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تأكيد تسجيل الخروج'),
                            content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // تسجيل الخروج
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم تسجيل الخروج بنجاح'),
                                    ),
                                  );
                                },
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('تسجيل الخروج'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // عنوان لوحة المعلومات
              const Text(
                'لوحة المعلومات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // بطاقات المعلومات
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // بطاقة الموظفين المتواجدين
                    _buildInfoCard(
                      context,
                      title: 'المتواجدون الآن',
                      value: '5',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    
                    // بطاقة عدد الغياب
                    _buildInfoCard(
                      context,
                      title: 'الغياب اليوم',
                      value: '2',
                      icon: Icons.person_off,
                      color: Colors.orange,
                    ),
                    
                    // بطاقة الموظف المميز
                    _buildInfoCard(
                      context,
                      title: 'الموظف المميز',
                      value: 'محمد',
                      subtitle: 'أول من حضر',
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                    
                    // بطاقة إجمالي الحضور
                    _buildInfoCard(
                      context,
                      title: 'إجمالي الحضور',
                      value: '22',
                      subtitle: 'هذا الشهر',
                      icon: Icons.calendar_month,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء بطاقة معلومات
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// شاشة قائمة الدردشات
class ChatsList extends StatelessWidget {
  const ChatsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // البحث في الدردشات
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // إنشاء دردشة جديدة
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // قسم المجموعات
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'المجموعات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildChatItem(
            context,
            name: 'مجموعة الإدارة',
            lastMessage: 'أحمد: الاجتماع غداً الساعة 10 صباحاً',
            time: '10:30 ص',
            isGroup: true,
          ),
          _buildChatItem(
            context,
            name: 'فريق التسويق',
            lastMessage: 'محمد: تم إرسال التقرير',
            time: 'أمس',
            isGroup: true,
          ),
          
          // قسم الدردشات الفردية
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'الدردشات الفردية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildChatItem(
            context,
            name: 'أحمد محمد',
            lastMessage: 'شكراً لك',
            time: '12:45 م',
            isOnline: true,
          ),
          _buildChatItem(
            context,
            name: 'سارة أحمد',
            lastMessage: 'سأكون في المكتب غداً',
            time: 'أمس',
            isRead: false,
          ),
          _buildChatItem(
            context,
            name: 'محمد علي',
            lastMessage: 'تم إرسال الملف',
            time: '2023/4/7',
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء عنصر دردشة
  Widget _buildChatItem(
    BuildContext context, {
    required String name,
    required String lastMessage,
    required String time,
    bool isGroup = false,
    bool isOnline = false,
    bool isRead = true,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: isGroup ? Colors.green : Colors.blue,
            child: Icon(
              isGroup ? Icons.group : Icons.person,
              color: Colors.white,
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRead ? Colors.grey : Colors.black,
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (!isRead)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // فتح الدردشة
      },
    );
  }
}

// شاشة الإحصائيات
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم إحصائيات الدوام
            const Text(
              'إحصائيات الدوام',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // أزرار تصفية الإحصائيات
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, label: 'اليوم', isSelected: true),
                  _buildFilterChip(context, label: 'الأسبوع'),
                  _buildFilterChip(context, label: 'الشهر'),
                  _buildFilterChip(context, label: 'العام'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // بطاقة إحصائيات الدوام
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'ملخص الدوام اليومي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // رسم بياني وهمي (سيتم استبداله برسم بياني حقيقي)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('رسم بياني للدوام'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // تفاصيل الإحصائيات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          label: 'الحضور',
                          value: '7',
                          color: Colors.green,
                        ),
                        _buildStatItem(
                          context,
                          label: 'الغياب',
                          value: '2',
                          color: Colors.red,
                        ),
                        _buildStatItem(
                          context,
                          label: 'المتأخرون',
                          value: '1',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // قسم البحث عن موظف
            const Text(
              'بحث عن موظف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // حقل البحث
            TextField(
              decoration: InputDecoration(
                hintText: 'اسم الموظف',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // زر البحث
            ElevatedButton(
              onPressed: () {
                // البحث عن الموظف
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('بحث'),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإنشاء شريحة تصفية
  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          // تغيير التصفية
        },
      ),
    );
  }

  // دالة لإنشاء عنصر إحصائية
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// شاشة الملف الشخصي
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // تعديل الملف الشخصي
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // صورة الملف الشخصي
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // اسم المستخدم
            const Text(
              'أحمد محمد',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'موظف',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // بطاقة المعلومات الشخصية
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
                    _buildProfileInfoItem(
                      icon: Icons.email,
                      title: 'البريد الإلكتروني',
                      subtitle: 'ahmed@example.com',
                    ),
                    const Divider(),
                    _buildProfileInfoItem(
                      icon: Icons.phone,
                      title: 'رقم الهاتف',
                      subtitle: '0123456789',
                    ),
                    const Divider(),
                    _buildProfileInfoItem(
                      icon: Icons.calendar_today,
                      title: 'تاريخ الانضمام',
                      subtitle: '2023/1/15',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // بطاقة إحصائيات الدوام
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
                      'إحصائيات الدوام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceStatItem(
                          context,
                          title: 'أيام الحضور',
                          value: '22',
                          color: Colors.green,
                        ),
                        _buildAttendanceStatItem(
                          context,
                          title: 'أيام الغياب',
                          value: '3',
                          color: Colors.red,
                        ),
                        _buildAttendanceStatItem(
                          context,
                          title: 'أيام التأخير',
                          value: '5',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإنشاء عنصر معلومات الملف الشخصي
  Widget _buildProfileInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء عنصر إحصائية الدوام
  Widget _buildAttendanceStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// شاشة الإعدادات
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _language = 'العربية';

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
          const ListTile(
            title: Text(
              'المظهر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('الوضع الليلي'),
            subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          const Divider(),
          
          // قسم اللغة
          const ListTile(
            title: Text(
              'اللغة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('لغة التطبيق'),
            subtitle: Text(_language),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // تغيير اللغة
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('اختر اللغة'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() {
                          _language = 'العربية';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('العربية'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        setState(() {
                          _language = 'English';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('English'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          
          // قسم الحساب
          const ListTile(
            title: Text(
              'الحساب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('تغيير كلمة المرور'),
            leading: const Icon(Icons.lock),
            onTap: () {
              // تغيير كلمة المرور
            },
          ),
          ListTile(
            title: const Text('تسجيل الخروج'),
            leading: const Icon(Icons.logout),
            onTap: () {
              // تسجيل الخروج
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج من التطبيق؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        // تسجيل الخروج
                        Navigator.pop(context);
                      },
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          
          // قسم حول التطبيق
          const ListTile(
            title: Text(
              'حول التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('الإصدار'),
            subtitle: const Text('1.0.0'),
          ),
          const ListTile(
            title: Text('مطور التطبيق'),
            subtitle: Text('إبراهيم عسكر'),
          ),
        ],
      ),
    );
  }
}
