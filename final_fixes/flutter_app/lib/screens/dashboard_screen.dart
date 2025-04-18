import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/period_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل بيانات لوحة المعلومات عند تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المعلومات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<StatisticsProvider>(context, listen: false).loadDashboardData();
            },
          ),
        ],
      ),
      body: Consumer2<StatisticsProvider, UserProvider>(
        builder: (context, statisticsProvider, userProvider, child) {
          if (statisticsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة الترحيب
                _buildWelcomeCard(userProvider),
                
                const SizedBox(height: 24),
                
                // بطاقات المعلومات
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'المتواجدون حالياً',
                        '${statisticsProvider.presentEmployees.length}',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'عدد الغياب',
                        '${statisticsProvider.absentCount}',
                        Icons.person_off,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // الموظف المميز
                _buildFeaturedEmployeeCard(statisticsProvider),
                
                const SizedBox(height: 24),
                
                // قسم الإحصائيات
                const Text(
                  'إحصائيات الدوام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // اختيار الفترة الزمنية
                PeriodSelector(
                  currentPeriod: statisticsProvider.currentPeriod,
                  onPeriodChanged: (period) {
                    statisticsProvider.loadAllEmployeesStats(period);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // قائمة الموظفين المتواجدين حالياً
                const Text(
                  'الموظفون المتواجدون حالياً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                _buildPresentEmployeesList(statisticsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  // بناء بطاقة الترحيب
  Widget _buildWelcomeCard(UserProvider userProvider) {
    final user = userProvider.user;
    final userName = userProvider.userData?['name'] ?? 'مستخدم';
    
    return Card(
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
              backgroundColor: Colors.blue.shade100,
              child: Text(
                userName.isNotEmpty ? userName[0] : 'م',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، $userName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نتمنى لك يوماً سعيداً!',
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
    );
  }

  // بناء بطاقة معلومات
  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء بطاقة الموظف المميز
  Widget _buildFeaturedEmployeeCard(StatisticsProvider statisticsProvider) {
    final featuredEmployee = statisticsProvider.featuredEmployee;
    
    if (featuredEmployee == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                SizedBox(width: 8),
                Text(
                  'الموظف المميز',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.amber.shade100,
                  child: Text(
                    featuredEmployee['name'].isNotEmpty ? featuredEmployee['name'][0] : 'م',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featuredEmployee['name'] ?? 'موظف',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'أول من حضر اليوم',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بناء قائمة الموظفين المتواجدين حالياً
  Widget _buildPresentEmployeesList(StatisticsProvider statisticsProvider) {
    final presentEmployees = statisticsProvider.presentEmployees;
    
    if (presentEmployees.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('لا يوجد موظفون متواجدون حالياً'),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: presentEmployees.length,
        itemBuilder: (context, index) {
          final employee = presentEmployees[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                employee['name'].isNotEmpty ? employee['name'][0] : 'م',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(employee['name'] ?? 'موظف'),
            subtitle: Text(
              'منذ ${_formatTime(employee['checkInTime'])}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            trailing: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  // تنسيق الوقت
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) {
      return '';
    }
    
    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 + (timestamp.nanoseconds ~/ 1000000),
            );
      
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
