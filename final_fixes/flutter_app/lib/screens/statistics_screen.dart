import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/period_selector.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentPeriod = 'day';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // تحميل بيانات الإحصائيات عند تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
      statisticsProvider.loadAllEmployeesStats(_currentPeriod);
      statisticsProvider.loadAttendanceReport(_currentPeriod);
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
        title: const Text('الإحصائيات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ملخص'),
            Tab(text: 'تقارير الحضور'),
            Tab(text: 'إحصائيات الموظفين'),
          ],
        ),
      ),
      body: Column(
        children: [
          // اختيار الفترة الزمنية
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PeriodSelector(
              currentPeriod: _currentPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _currentPeriod = period;
                });
                
                final statisticsProvider = Provider.of<StatisticsProvider>(context, listen: false);
                statisticsProvider.loadAllEmployeesStats(period);
                statisticsProvider.loadAttendanceReport(period);
              },
            ),
          ),
          
          // محتوى التبويبات
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildAttendanceReportTab(),
                _buildEmployeeStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء تبويب الملخص
  Widget _buildSummaryTab() {
    return Consumer<StatisticsProvider>(
      builder: (context, statisticsProvider, child) {
        if (statisticsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = statisticsProvider.allEmployeesStats;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقات الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي الموظفين',
                      '${stats['totalEmployees'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'الحضور',
                      '${stats['presentCount'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'التأخير',
                      '${stats['lateCount'] ?? 0}',
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'متوسط الحضور',
                      '${(stats['averageAttendance'] ?? 0).toStringAsFixed(1)}',
                      Icons.analytics,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // رسم بياني للحضور (في التطبيق الفعلي)
              const Text(
                'رسم بياني للحضور',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('سيتم عرض رسم بياني هنا'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // أفضل الموظفين حضوراً
              const Text(
                'أفضل الموظفين حضوراً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              _buildTopEmployeesList(stats),
            ],
          ),
        );
      },
    );
  }

  // بناء تبويب تقارير الحضور
  Widget _buildAttendanceReportTab() {
    return Consumer<StatisticsProvider>(
      builder: (context, statisticsProvider, child) {
        if (statisticsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final report = statisticsProvider.attendanceReport;
        
        if (report.isEmpty) {
          return const Center(
            child: Text('لا توجد بيانات للعرض'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // جدول تقرير الحضور
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تقرير الحضور والغياب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // عناوين الجدول
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'الموظف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'الحضور',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'التأخير',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'الغياب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(),
                      
                      // بيانات الجدول
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: report.length,
                        itemBuilder: (context, index) {
                          final employee = report[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(employee['name'] ?? 'موظف'),
                                ),
                                Expanded(
                                  child: Text(
                                    '${employee['presentDays'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${employee['lateDays'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${employee['absentDays'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // بناء تبويب إحصائيات الموظفين
  Widget _buildEmployeeStatsTab() {
    return Consumer<StatisticsProvider>(
      builder: (context, statisticsProvider, child) {
        if (statisticsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = statisticsProvider.allEmployeesStats;
        final employeeAttendance = stats['employeeAttendance'] as Map<String, dynamic>? ?? {};
        
        if (employeeAttendance.isEmpty) {
          return const Center(
            child: Text('لا توجد بيانات للعرض'),
          );
        }
        
        // تحويل بيانات الحضور إلى قائمة وترتيبها تنازلياً
        final List<MapEntry<String, dynamic>> sortedEntries = employeeAttendance.entries.toList()
          ..sort((a, b) => (b.value as int).compareTo(a.value as int));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedEntries.length,
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final userId = entry.key;
            final attendanceCount = entry.value as int;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  // في التطبيق الفعلي، سيتم هنا فتح شاشة تفاصيل الموظف
                  statisticsProvider.loadEmployeeAttendanceCount(userId, _currentPeriod);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Text(
                          'م',
                          style: TextStyle(
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
                            const Text(
                              'موظف',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'عدد أيام الحضور: $attendanceCount',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // بناء بطاقة إحصائية
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              size: 32,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء قائمة أفضل الموظفين حضوراً
  Widget _buildTopEmployeesList(Map<String, dynamic> stats) {
    final employeeAttendance = stats['employeeAttendance'] as Map<String, dynamic>? ?? {};
    
    if (employeeAttendance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('لا توجد بيانات للعرض'),
          ),
        ),
      );
    }
    
    // تحويل بيانات الحضور إلى قائمة وترتيبها تنازلياً
    final List<MapEntry<String, dynamic>> sortedEntries = employeeAttendance.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    // أخذ أفضل 5 موظفين
    final topEntries = sortedEntries.take(5).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topEntries.length,
        itemBuilder: (context, index) {
          final entry = topEntries[index];
          final attendanceCount = entry.value as int;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: const Text('موظف'),
            subtitle: Text('عدد أيام الحضور: $attendanceCount'),
            trailing: index == 0
                ? const Icon(Icons.emoji_events, color: Colors.amber)
                : null,
          );
        },
      ),
    );
  }
}
