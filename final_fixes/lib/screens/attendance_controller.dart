import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/user_provider.dart';

class AttendanceController extends StatefulWidget {
  const AttendanceController({super.key});

  @override
  State<AttendanceController> createState() => _AttendanceControllerState();
}

class _AttendanceControllerState extends State<AttendanceController> {
  @override
  void initState() {
    super.initState();
    // تحديث بيانات لوحة المعلومات عند تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).refreshDashboardData();
    });
  }

  // تأكيد تسجيل الدخول
  Future<void> _confirmCheckIn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الدخول'),
        content: const Text('هل أنت متأكد من تسجيل الدخول؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attendanceProvider.checkIn();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم تسجيل الدخول بنجاح' : 'فشل تسجيل الدخول'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // تأكيد تسجيل الخروج
  Future<void> _confirmCheckOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final success = await attendanceProvider.checkOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم تسجيل الخروج بنجاح' : 'فشل تسجيل الخروج'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AttendanceProvider>(
      builder: (context, userProvider, attendanceProvider, child) {
        final user = userProvider.user;
        final userData = userProvider.userData;
        
        if (user == null || userData == null) {
          return const Center(
            child: Text('يرجى تسجيل الدخول أولاً'),
          );
        }
        
        return Column(
          children: [
            // أزرار تسجيل الدخول والخروج
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: attendanceProvider.isLoading ? null : _confirmCheckIn,
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
                      onPressed: attendanceProvider.isLoading ? null : _confirmCheckOut,
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
            ),
            
            // لوحة المعلومات
            Expanded(
              child: attendanceProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDashboard(context, attendanceProvider),
            ),
          ],
        );
      },
    );
  }

  // بناء لوحة المعلومات
  Widget _buildDashboard(BuildContext context, AttendanceProvider attendanceProvider) {
    return RefreshIndicator(
      onRefresh: () => attendanceProvider.refreshDashboardData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لوحة المعلومات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // بطاقات المعلومات
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // بطاقة الموظفين المتواجدين
                _buildInfoCard(
                  context,
                  title: 'المتواجدون الآن',
                  value: attendanceProvider.presentEmployees.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                
                // بطاقة عدد الغياب
                _buildInfoCard(
                  context,
                  title: 'الغياب اليوم',
                  value: attendanceProvider.absentCount.toString(),
                  icon: Icons.person_off,
                  color: Colors.orange,
                ),
                
                // بطاقة الموظف المميز
                _buildInfoCard(
                  context,
                  title: 'الموظف المميز',
                  value: attendanceProvider.featuredEmployee?['name'] ?? '-',
                  subtitle: 'أول من حضر',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
                
                // بطاقة إجمالي الحضور
                _buildInfoCard(
                  context,
                  title: 'إجمالي الحضور',
                  value: (attendanceProvider.presentEmployees.length + attendanceProvider.absentCount).toString(),
                  subtitle: 'هذا اليوم',
                  icon: Icons.calendar_month,
                  color: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // قائمة الموظفين المتواجدين
            const Text(
              'الموظفون المتواجدون حالياً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            attendanceProvider.presentEmployees.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('لا يوجد موظفون متواجدون حالياً'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendanceProvider.presentEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = attendanceProvider.presentEmployees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: employee['profileImage']?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(employee['name'] ?? 'موظف'),
                        subtitle: Text('منذ ${_formatTime(employee['checkInTime'])}'),
                      );
                    },
                  ),
          ],
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

  // تنسيق الوقت
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) {
      return 'غير معروف';
    }
    
    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 + (timestamp.nanoseconds ~/ 1000000),
            );
      
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير معروف';
    }
  }
}
