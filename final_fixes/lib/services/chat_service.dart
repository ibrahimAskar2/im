import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  // الحصول على قائمة الدردشات للمستخدم
  Stream<QuerySnapshot> getChats() {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // الحصول على الدردشات التي يشارك فيها المستخدم الحالي
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting chats: $e');
      rethrow;
    }
  }

  // الحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  // إنشاء دردشة خاصة
  Future<String> createPrivateChat(String otherUserId) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // التحقق من وجود دردشة سابقة بين المستخدمين
      final querySnapshot = await _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }
      
      // إنشاء دردشة جديدة
      final chatRef = _firestore.collection('chats').doc();
      await chatRef.set({
        'type': 'private',
        'participants': [currentUserId, otherUserId],
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return chatRef.id;
    } catch (e) {
      print('Error creating private chat: $e');
      rethrow;
    }
  }

  // إنشاء دردشة جماعية
  Future<String> createGroupChat(String name, List<String> participants) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // التأكد من إضافة المستخدم الحالي إلى المشاركين
      if (!participants.contains(currentUserId)) {
        participants.add(currentUserId!);
      }
      
      // إنشاء دردشة جديدة
      final chatRef = _firestore.collection('chats').doc();
      await chatRef.set({
        'type': 'group',
        'name': name,
        'participants': participants,
        'admin': currentUserId, // المستخدم الحالي هو المسؤول
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return chatRef.id;
    } catch (e) {
      print('Error creating group chat: $e');
      rethrow;
    }
  }

  // إضافة مشاركين إلى مجموعة
  Future<void> addParticipantsToGroup(String chatId, List<String> newParticipants) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion(newParticipants),
      });
    } catch (e) {
      print('Error adding participants to group: $e');
      rethrow;
    }
  }

  // تعليم الرسالة كمستلمة
  Future<void> markMessageAsDelivered(String chatId, String messageId) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'deliveredTo': FieldValue.arrayUnion([currentUserId]),
          });
    } catch (e) {
      print('Error marking message as delivered: $e');
      rethrow;
    }
  }

  // تعليم الرسالة كمقروءة
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'readBy': FieldValue.arrayUnion([currentUserId]),
          });
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  // إرسال رسالة نصية
  Future<void> sendTextMessage(String chatId, String text) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'text',
        'text': text,
        'senderId': currentUserId,
        'timestamp': Timestamp.now(),
        'readBy': [],
        'deliveredTo': [],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending text message: $e');
      rethrow;
    }
  }

  // إرسال رسالة صوتية
  Future<void> sendVoiceMessage(String chatId, File audioFile) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // رفع الملف الصوتي إلى Firebase Storage
      final storageRef = _storage.ref().child('chats/$chatId/voice/${DateTime.now().millisecondsSinceEpoch}.m4a');
      await storageRef.putFile(audioFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      // إنشاء رسالة جديدة
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'voice',
        'url': downloadUrl,
        'senderId': currentUserId,
        'timestamp': Timestamp.now(),
        'readBy': [],
        'deliveredTo': [],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'رسالة صوتية',
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending voice message: $e');
      rethrow;
    }
  }

  // إرسال صورة
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // رفع الصورة إلى Firebase Storage
      final storageRef = _storage.ref().child('chats/$chatId/images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      // إنشاء رسالة جديدة
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      await messageRef.set({
        'type': 'image',
        'url': downloadUrl,
        'senderId': currentUserId,
        'timestamp': Timestamp.now(),
        'readBy': [],
        'deliveredTo': [],
      });
      
      // تحديث آخر رسالة في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': 'صورة',
        'lastMessageTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
  }

  // الحصول على رسائل الدردشة مع التحميل المتدرج
  Future<List<Message>> getChatMessages({
    required String chatId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final querySnapshot = await query.get();
      
      // تحويل البيانات إلى قائمة من كائنات Message
      final messages = querySnapshot.docs.map((doc) {
        return Message.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      return messages;
    } catch (e) {
      print('Error getting chat messages: $e');
      rethrow;
    }
  }

  // البحث في رسائل الدردشة
  Future<List<Message>> searchChatMessages({
    required String chatId,
    required String searchText,
    int limit = 20,
  }) async {
    try {
      // استخدام Firebase للبحث في الرسائل
      // ملاحظة: Firestore لا يدعم البحث النصي الكامل، لذلك نستخدم استعلاماً بسيطاً
      
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();
      
      // تصفية النتائج على جانب العميل
      final messages = querySnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((message) => message.text.toLowerCase().contains(searchText.toLowerCase()))
          .take(limit)
          .toList();
      
      return messages;
    } catch (e) {
      print('Error searching chat messages: $e');
      rethrow;
    }
  }

  // إنشاء دردشة جديدة
  Future<String> createChat({
    required List<User> participants,
    required String chatName,
    bool isGroup = false,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('لم يتم تسجيل الدخول');
      }
      
      // إنشاء وثيقة الدردشة
      final chatRef = _firestore.collection('chats').doc();
      
      // إعداد بيانات الدردشة
      final chatData = {
        'name': chatName,
        'isGroup': isGroup,
        'createdAt': Timestamp.now(),
        'participantIds': participants.map((user) => user.id).toList(),
        'participantCount': participants.length,
      };
      
      // حفظ بيانات الدردشة
      await chatRef.set(chatData);
      
      // إضافة المشاركين في الدردشة
      final batch = _firestore.batch();
      
      for (var user in participants) {
        final participantRef = _firestore.collection('chat_participants').doc();
        batch.set(participantRef, {
          'chatId': chatRef.id,
          'userId': user.id,
          'joinedAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
      
      return chatRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // إضافة مستخدم إلى دردشة جماعية
  Future<void> addUserToGroupChat({
    required String chatId,
    required User user,
  }) async {
    try {
      // التحقق من أن الدردشة هي دردشة جماعية
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        throw Exception('الدردشة غير موجودة');
      }
      
      final chatData = chatDoc.data();
      if (chatData == null || chatData['isGroup'] != true) {
        throw Exception('الدردشة ليست دردشة جماعية');
      }
      
      // التحقق من أن المستخدم ليس مشاركاً بالفعل
      final participantQuery = await _firestore
          .collection('chat_participants')
          .where('chatId', isEqualTo: chatId)
          .where('userId', isEqualTo: user.id)
          .get();
      
      if (participantQuery.docs.isNotEmpty) {
        throw Exception('المستخدم مشارك بالفعل في الدردشة');
      }
      
      // إضافة المستخدم إلى الدردشة
      final participantRef = _firestore.collection('chat_participants').doc();
      await participantRef.set({
        'chatId': chatId,
        'userId': user.id,
        'joinedAt': Timestamp.now(),
      });
      
      // تحديث عدد المشاركين في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'participantIds': FieldValue.arrayUnion([user.id]),
        'participantCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding user to group chat: $e');
      rethrow;
    }
  }

  // إزالة مستخدم من دردشة جماعية
  Future<void> removeUserFromGroupChat({
    required String chatId,
    required String userId,
  }) async {
    try {
      // التحقق من أن الدردشة هي دردشة جماعية
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        throw Exception('الدردشة غير موجودة');
      }
      
      final chatData = chatDoc.data();
      if (chatData == null || chatData['isGroup'] != true) {
        throw Exception('الدردشة ليست دردشة جماعية');
      }
      
      // البحث عن مشاركة المستخدم في الدردشة
      final participantQuery = await _firestore
          .collection('chat_participants')
          .where('chatId', isEqualTo: chatId)
          .where('userId', isEqualTo: userId)
          .get();
      
      if (participantQuery.docs.isEmpty) {
        throw Exception('المستخدم ليس مشاركاً في الدردشة');
      }
      
      // حذف مشاركة المستخدم
      final batch = _firestore.batch();
      
      for (var doc in participantQuery.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      // تحديث عدد المشاركين في الدردشة
      await _firestore.collection('chats').doc(chatId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
        'participantCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error removing user from group chat: $e');
      rethrow;
    }
  }
}
