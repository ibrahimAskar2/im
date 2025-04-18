import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // تسجيل الدخول للموظف
  Future<bool> checkIn() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // التحقق مما إذا كان الموظف قد سجل دخوله بالفعل اليوم
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateStr)
          .get();

      if (attendanceQuery.docs.isNotEmpty) {
        // إذا كان هناك سجل حضور لهذا اليوم، تحقق مما إذا كان قد سجل خروجه
        final attendanceDoc = attendanceQuery.docs.first;
        final attendanceData = attendanceDoc.data();
        
        if (attendanceData['checkOutTime'] != null) {
          // إذا كان قد سجل خروجه، يمكنه تسجيل الدخول مرة أخرى
          await _firestore.collection('attendance').add({
            'userId': user.uid,
            'date': dateStr,
            'checkInTime': FieldValue.serverTimestamp(),
            'checkOutTime': null,
            'status': _getAttendanceStatus(today),
            'notes': '',
          });
        } else {
          // إذا لم يسجل خروجه بعد، لا يمكنه تسجيل الدخول مرة أخرى
          return false;
        }
      } else {
        // إذا لم يكن هناك سجل حضور لهذا اليوم، قم بإنشاء سجل جديد
        await _firestore.collection('attendance').add({
          'userId': user.uid,
          'date': dateStr,
          'checkInTime': FieldValue.serverTimestamp(),
          'checkOutTime': null,
          'status': _getAttendanceStatus(today),
          'notes': '',
        });
      }

      // إرسال إشعار عام
      await _sendPublicNotification('تسجيل دخول', 'قام ${await _getUserName(user.uid)} بتسجيل الدخول');
      
      // التحقق من وقت الدخول وإرسال إشعار للتأخير إذا لزم الأمر
      if (_isLate(today)) {
        await _sendPrivateNotification(
          user.uid,
          'تأخير في الحضور',
          'أنت بالمكتبة خويي ؟',
        );
      }

      // تحديث الموظف المميز إذا كان أول من يدخل اليوم
      await _updateFeaturedEmployee(user.uid, dateStr);

      return true;
    } catch (e) {
      print('Error checking in: $e');
      return false;
    }
  }

  // تسجيل الخروج للموظف
  Future<bool> checkOut() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // التحقق من وجود سجل دخول لهذا اليوم
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateStr)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        // إذا لم يكن هناك سجل دخول، لا يمكن تسجيل الخروج
        return false;
      }

      // تحديث سجل الدخول بوقت الخروج
      final attendanceDoc = attendanceQuery.docs.first;
      await _firestore.collection('attendance').doc(attendanceDoc.id).update({
        'checkOutTime': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار عام
      await _sendPublicNotification('تسجيل خروج', 'قام ${await _getUserName(user.uid)} بتسجيل الخروج');

      return true;
    } catch (e) {
      print('Error checking out: $e');
      return false;
    }
  }

  // الحصول على حالة الحضور بناءً على وقت الدخول
  String _getAttendanceStatus(DateTime time) {
    if (time.hour < 9) {
      return 'present';
    } else {
      return 'late';
    }
  }

  // التحقق مما إذا كان الوقت متأخرًا (بعد الساعة 9 صباحًا)
  bool _isLate(DateTime time) {
    return time.hour >= 9;
  }

  // الحصول على اسم المستخدم
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData.containsKey('name')) {
        return userData['name'];
      }
      return 'موظف';
    } catch (e) {
      return 'موظف';
    }
  }

  // إرسال إشعار عام لجميع المستخدمين
  Future<void> _sendPublicNotification(String title, String body) async {
    try {
      // إضافة الإشعار إلى قاعدة البيانات
      await _firestore.collection('notifications').add({
        'type': 'public',
        'title': title,
        'body': body,
        'senderId': _auth.currentUser?.uid ?? '',
        'receiverId': 'all',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // في التطبيق الفعلي، سيتم هنا إرسال إشعار FCM لجميع المستخدمين
    } catch (e) {
      print('Error sending public notification: $e');
    }
  }

  // إرسال إشعار خاص لمستخدم محدد
  Future<void> _sendPrivateNotification(String userId, String title, String body) async {
    try {
      // إضافة الإشعار إلى قاعدة البيانات
      await _firestore.collection('notifications').add({
        'type': 'private',
        'title': title,
        'body': body,
        'senderId': 'system',
        'receiverId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // في التطبيق الفعلي، سيتم هنا إرسال إشعار FCM للمستخدم المحدد
    } catch (e) {
      print('Error sending private notification: $e');
    }
  }

  // تحديث الموظف المميز (أول من يدخل)
  Future<void> _updateFeaturedEmployee(String userId, String dateStr) async {
    try {
      // التحقق من عدد سجلات الحضور لهذا اليوم
      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .get();

      // إذا كان هذا هو أول سجل حضور لهذا اليوم، قم بتحديث الموظف المميز
      if (attendanceQuery.docs.length == 1) {
        await _firestore.collection('settings').doc('featured_employee').set({
          'date': dateStr,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating featured employee: $e');
    }
  }

  // الحصول على الموظفين المتواجدين حاليًا
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
      
      final presentEmployees = attendanceQuery.docs.length;
      
      // حساب عدد الغياب
      return totalEmployees - presentEmployees;
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
  Future<Map<String, dynamic>> getAttendanceStats(String userId, String period) async {
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
      print('Error getting attendance stats: $e');
      return {
        'present': 0,
        'late': 0,
        'total': 0,
      };
    }
  }
}
