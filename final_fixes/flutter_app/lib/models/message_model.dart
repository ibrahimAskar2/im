import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String type;
  final Map<String, dynamic>? mediaData;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.type = 'text',
    this.mediaData,
  });

  // تحويل الرسالة إلى Map لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readBy': readBy,
      'type': type,
      'mediaData': mediaData,
    };
  }

  // إنشاء رسالة من Map من Firestore
  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      type: map['type'] ?? 'text',
      mediaData: map['mediaData'],
    );
  }

  // إنشاء رسالة نصية جديدة
  factory Message.createText({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      type: 'text',
    );
  }

  // إنشاء رسالة وسائط جديدة
  factory Message.createMedia({
    required String chatId,
    required String senderId,
    required String text,
    required String mediaType,
    required Map<String, dynamic> mediaData,
  }) {
    return Message(
      id: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').doc().id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [senderId],
      type: mediaType,
      mediaData: mediaData,
    );
  }

  // تعليم الرسالة كمقروءة من قبل مستخدم
  Message markAsReadBy(String userId) {
    if (readBy.contains(userId)) {
      return this;
    }
    
    final updatedReadBy = List<String>.from(readBy);
    updatedReadBy.add(userId);
    
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      isRead: true,
      readBy: updatedReadBy,
      type: type,
      mediaData: mediaData,
    );
  }

  // التحقق مما إذا كانت الرسالة تحتوي على وسائط
  bool get hasMedia => type != 'text';

  // الحصول على نوع الوسائط
  String get mediaType => type;

  // الحصول على رابط الوسائط
  String get mediaUrl => mediaData?['url'] ?? '';

  // الحصول على حجم الوسائط
  String get mediaSize => mediaData?['size'] ?? '';

  // الحصول على مدة الوسائط (للصوت والفيديو)
  int get mediaDuration => mediaData?['duration'] ?? 0;
}
