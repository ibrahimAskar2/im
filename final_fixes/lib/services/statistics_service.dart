import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على الموظفين المتواجدين حالياً
  Future<List<Map<String, dynamic>>> getPresentEmployees() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .where('checkOutTime', isNull: true)
          .get();

      List<Map<String, dynamic>> presentEmployees = [];
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final userId = data['userId'];
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        
        if (userData != null) {
          presentEmployees.add({
            'userId': userId,
            'name': userData['name'],
            'profileImage': userData['profileImage'],
            'checkInTime': data['checkInTime'],
          });
        }
      }

      return presentEmployees;
    } catch (e) {
      print('Error getting present employees: $e');
      return [];
    }
  }

  // الحصول على عدد الغياب لليوم الحالي
  Future<int> getAbsentCount() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // الحصول على إجمالي عدد الموظفين
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      
      final totalEmployees = usersQuery.docs.length;
      
      // الحصول على عدد الموظفين الحاضرين
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .get();
      
      // تحديد المستخدمين الفريدين الذين سجلوا حضورهم اليوم
      final Set<String> presentUserIds = {};
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        presentUserIds.add(data['userId']);
      }
      
      // حساب عدد الغياب
      return totalEmployees - presentUserIds.length;
    } catch (e) {
      print('Error getting absent count: $e');
      return 0;
    }
  }

  // الحصول على الموظف المميز (أول من يدخل)
  Future<Map<String, dynamic>?> getFeaturedEmployee() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final featuredDoc = await _firestore
          .collection('settings')
          .doc('featured_employee')
          .get();
      
      if (!featuredDoc.exists || featuredDoc.data()?['date'] != dateStr) {
        return null;
      }
      
      final userId = featuredDoc.data()?['userId'];
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        return {
          'userId': userId,
          'name': userData['name'],
          'profileImage': userData['profileImage'],
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting featured employee: $e');
      return null;
    }
  }

  // الحصول على إحصائيات الدوام لموظف معين
  Future<Map<String, dynamic>> getEmployeeAttendanceStats(String userId, String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      // تحديد تاريخ البداية بناءً على الفترة المطلوبة
      switch (period) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          // بداية الأسبوع (الأحد)
          startDate = now.subtract(Duration(days: now.weekday % 7));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }
      
      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();
      
      int presentCount = 0;
      int lateCount = 0;
      
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'present') {
          presentCount++;
        } else if (data['status'] == 'late') {
          lateCount++;
        }
      }
      
      return {
        'present': presentCount,
        'late': lateCount,
        'total': presentCount + lateCount,
      };
    } catch (e) {
      print('Error getting employee attendance stats: $e');
      return {
        'present': 0,
        'late': 0,
        'total': 0,
      };
    }
  }

  // الحصول على إحصائيات الدوام لجميع الموظفين
  Future<Map<String, dynamic>> getAllEmployeesAttendanceStats(String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      // تحديد تاريخ البداية بناءً على الفترة المطلوبة
      switch (period) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          // بداية الأسبوع (الأحد)
          startDate = now.subtract(Duration(days: now.weekday % 7));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }
      
      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // الحصول على جميع الموظفين
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      
      final totalEmployees = usersQuery.docs.length;
      
      // الحصول على سجلات الحضور للفترة المحددة
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();
      
      int presentCount = 0;
      int lateCount = 0;
      Map<String, int> employeeAttendance = {};
      
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final userId = data['userId'];
        
        if (data['status'] == 'present') {
          presentCount++;
        } else if (data['status'] == 'late') {
          lateCount++;
        }
        
        // حساب عدد أيام الحضور لكل موظف
        if (employeeAttendance.containsKey(userId)) {
          employeeAttendance[userId] = employeeAttendance[userId]! + 1;
        } else {
          employeeAttendance[userId] = 1;
        }
      }
      
      // حساب متوسط الحضور
      double averageAttendance = 0;
      if (employeeAttendance.isNotEmpty) {
        int totalDays = 0;
        for (var count in employeeAttendance.values) {
          totalDays += count;
        }
        averageAttendance = totalDays / employeeAttendance.length;
      }
      
      return {
        'totalEmployees': totalEmployees,
        'presentCount': presentCount,
        'lateCount': lateCount,
        'averageAttendance': averageAttendance,
        'employeeAttendance': employeeAttendance,
      };
    } catch (e) {
      print('Error getting all employees attendance stats: $e');
      return {
        'totalEmployees': 0,
        'presentCount': 0,
        'lateCount': 0,
        'averageAttendance': 0,
        'employeeAttendance': {},
      };
    }
  }

  // الحصول على تقرير الحضور والغياب
  Future<List<Map<String, dynamic>>> getAttendanceReport(String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      // تحديد تاريخ البداية بناءً على الفترة المطلوبة
      switch (period) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          // بداية الأسبوع (الأحد)
          startDate = now.subtract(Duration(days: now.weekday % 7));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }
      
      final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // الحصول على جميع الموظفين
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'employee')
          .get();
      
      // إنشاء قاموس للموظفين
      Map<String, Map<String, dynamic>> employeesMap = {};
      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        employeesMap[doc.id] = {
          'userId': doc.id,
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'],
          'presentDays': 0,
          'lateDays': 0,
          'absentDays': 0,
        };
      }
      
      // حساب عدد الأيام في الفترة المحددة
      int totalDays = 0;
      DateTime currentDate = startDate;
      while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
        // لا نحسب أيام العطلة (الجمعة والسبت)
        if (currentDate.weekday != DateTime.friday && currentDate.weekday != DateTime.saturday) {
          totalDays++;
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // الحصول على سجلات الحضور للفترة المحددة
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();
      
      // تجميع سجلات الحضور حسب المستخدم والتاريخ
      Map<String, Set<String>> employeeAttendanceDates = {};
      for (var doc in attendanceQuery.docs) {
        final data = doc.data();
        final userId = data['userId'];
        final date = data['date'];
        final status = data['status'];
        
        if (employeesMap.containsKey(userId)) {
          // تسجيل يوم الحضور
          if (!employeeAttendanceDates.containsKey(userId)) {
            employeeAttendanceDates[userId] = {};
          }
          employeeAttendanceDates[userId]!.add(date);
          
          // تحديث عدد أيام الحضور/التأخير
          if (status == 'present') {
            employeesMap[userId]!['presentDays']++;
          } else if (status == 'late') {
            employeesMap[userId]!['lateDays']++;
          }
        }
      }
      
      // حساب أيام الغياب
      for (var userId in employeesMap.keys) {
        final attendedDays = employeeAttendanceDates[userId]?.length ?? 0;
        employeesMap[userId]!['absentDays'] = totalDays - attendedDays;
      }
      
      // تحويل القاموس إلى قائمة
      List<Map<String, dynamic>> report = employeesMap.values.toList();
      
      return report;
    } catch (e) {
      print('Error getting attendance report: $e');
      return [];
    }
  }

  // الحصول على عدد دوام موظف معين
  Future<Map<String, dynamic>> getEmployeeAttendanceCount(String userId, String period) async {
    try {
      final stats = await getEmployeeAttendanceStats(userId, period);
      
      // الحصول على معلومات الموظف
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        return {
          'userId': userId,
          'name': userData['name'],
          'email': userData['email'],
          'phone': userData['phone'],
          'presentDays': stats['present'],
          'lateDays': stats['late'],
          'totalDays': stats['total'],
        };
      }
      
      return {
        'userId': userId,
        'name': 'غير معروف',
        'email': '',
        'phone': '',
        'presentDays': stats['present'],
        'lateDays': stats['late'],
        'totalDays': stats['total'],
      };
    } catch (e) {
      print('Error getting employee attendance count: $e');
      return {
        'userId': userId,
        'name': 'غير معروف',
        'email': '',
        'phone': '',
        'presentDays': 0,
        'lateDays': 0,
        'totalDays': 0,
      };
    }
  }
}
