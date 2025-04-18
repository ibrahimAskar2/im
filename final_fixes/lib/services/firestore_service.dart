import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // معرف المستخدم الحالي
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  
  // تعيين معرف المستخدم الحالي
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // الحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return docSnapshot.data();
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  // الحصول على قائمة المستخدمين
  Future<List<Map<String, dynamic>>> getUsers({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? department,
  }) async {
    try {
      Query query = _firestore.collection('users');
      
      // تصفية حسب القسم إذا تم تحديده
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }
      
      // تصفية حسب البحث إذا تم تحديده
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // استخدام مؤشر مركب للبحث في الاسم والبريد الإلكتروني
        query = query.where('searchKeywords', arrayContains: searchQuery.toLowerCase());
      }
      
      // ترتيب النتائج حسب الاسم
      query = query.orderBy('name');
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }

  // الحصول على رسائل الدردشة
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String chatId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true);
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      // تعليم الرسائل كمقروءة
      if (_currentUserId != null) {
        final batch = _firestore.batch();
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['senderId'] != _currentUserId && !(data['readBy'] as List<dynamic>).contains(_currentUserId)) {
            batch.update(doc.reference, {
              'readBy': FieldValue.arrayUnion([_currentUserId]),
              'isRead': true,
            });
          }
        }
        
        await batch.commit();
      }
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting chat messages: $e');
      rethrow;
    }
  }

  // البحث في رسائل الدردشة
  Future<List<Map<String, dynamic>>> searchChatMessages({
    required String chatId,
    required String searchText,
    int limit = 50,
  }) async {
    try {
      // استخدام مؤشر نصي للبحث في الرسائل
      // ملاحظة: هذا يتطلب إنشاء مؤشر في Firestore
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('textLowerCase', arrayContains: searchText.toLowerCase())
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error searching chat messages: $e');
      rethrow;
    }
  }

  // الحصول على الإشعارات
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true);
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  // تعليم الإشعارات كمقروءة
  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    try {
      // استخدام معاملة كتابة دفعية لتحديث عدة وثائق في عملية واحدة
      final batch = _firestore.batch();
      
      for (var notificationId in notificationIds) {
        final docRef = _firestore.collection('notifications').doc(notificationId);
        batch.update(docRef, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات المستخدم
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // استخدام استعلام واحد للحصول على الإحصائيات
      final statsDoc = await _firestore
          .collection('user_statistics')
          .doc(userId)
          .get();
      
      if (!statsDoc.exists) {
        // إنشاء إحصائيات جديدة إذا لم تكن موجودة
        final newStats = {
          'totalMessages': 0,
          'totalTasks': 0,
          'completedTasks': 0,
          'attendanceDays': 0,
          'lastUpdated': Timestamp.now(),
        };
        
        await _firestore
            .collection('user_statistics')
            .doc(userId)
            .set(newStats);
        
        return newStats;
      }
      
      return statsDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user statistics: $e');
      rethrow;
    }
  }

  // تحديث إحصائيات المستخدم
  Future<void> updateUserStatistics(String userId, Map<String, dynamic> updates) async {
    try {
      // تحديث الإحصائيات مع تسجيل وقت التحديث
      updates['lastUpdated'] = Timestamp.now();
      
      await _firestore
          .collection('user_statistics')
          .doc(userId)
          .update(updates);
    } catch (e) {
      print('Error updating user statistics: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات الحضور
  Future<Map<String, dynamic>> getAttendanceStatistics(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId);
      
      // تصفية حسب تاريخ البداية
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      // تصفية حسب تاريخ النهاية
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      final querySnapshot = await query.get();
      
      // حساب الإحصائيات
      int totalDays = querySnapshot.docs.length;
      int onTimeDays = 0;
      int lateDays = 0;
      int earlyLeaveDays = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['isLate'] == true) {
          lateDays++;
        } else {
          onTimeDays++;
        }
        
        if (data['isEarlyLeave'] == true) {
          earlyLeaveDays++;
        }
      }
      
      return {
        'totalDays': totalDays,
        'onTimeDays': onTimeDays,
        'lateDays': lateDays,
        'earlyLeaveDays': earlyLeaveDays,
        'attendanceRate': totalDays > 0 ? (onTimeDays / totalDays) * 100 : 0,
      };
    } catch (e) {
      print('Error getting attendance statistics: $e');
      rethrow;
    }
  }

  // إنشاء مؤشرات البحث للمستخدم
  Future<void> createUserSearchKeywords(String userId, String name, String email) async {
    try {
      // إنشاء كلمات مفتاحية للبحث
      final List<String> keywords = [];
      
      // إضافة الاسم الكامل
      keywords.add(name.toLowerCase());
      
      // إضافة أجزاء الاسم
      final nameParts = name.split(' ');
      for (var part in nameParts) {
        if (part.isNotEmpty) {
          keywords.add(part.toLowerCase());
        }
      }
      
      // إضافة البريد الإلكتروني
      keywords.add(email.toLowerCase());
      
      // إضافة اسم المستخدم من البريد الإلكتروني
      final username = email.split('@').first;
      keywords.add(username.toLowerCase());
      
      // تحديث وثيقة المستخدم بالكلمات المفتاحية
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'searchKeywords': keywords});
    } catch (e) {
      print('Error creating user search keywords: $e');
      rethrow;
    }
  }

  // إنشاء مؤشرات البحث للرسالة
  Future<void> createMessageSearchKeywords(String chatId, String messageId, String text) async {
    try {
      // إنشاء كلمات مفتاحية للبحث
      final List<String> keywords = [];
      
      // إضافة النص الكامل
      keywords.add(text.toLowerCase());
      
      // إضافة كلمات النص
      final words = text.split(' ');
      for (var word in words) {
        if (word.isNotEmpty && word.length > 2) {
          keywords.add(word.toLowerCase());
        }
      }
      
      // تحديث وثيقة الرسالة بالكلمات المفتاحية
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'textLowerCase': keywords,
          });
    } catch (e) {
      print('Error creating message search keywords: $e');
      rethrow;
    }
  }
}
