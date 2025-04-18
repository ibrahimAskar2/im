import 'package:cloud_firestore/cloud_firestore.dart';

// Renamed from Notification to AppNotification to avoid conflict with Flutter's Notification class
class AppNotification {
  final String id;
  final String userId;
  final String senderId;
  final String senderName;
  final String type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String targetId;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    required this.targetId,
    this.data,
  });

  // تحويل الإشعار إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'targetId': targetId,
      'data': data,
    };
  }

  // إنشاء إشعار من Map من Firestore
  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      targetId: map['targetId'] ?? '',
      data: map['data'],
    );
  }

  // إنشاء إشعار رسالة جديد
  factory AppNotification.createMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) {
    return AppNotification(
      id: FirebaseFirestore.instance.collection('notifications').doc().id,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      type: 'message',
      title: 'رسالة جديدة',
      body: '$senderName: $messageText',
      timestamp: DateTime.now(),
      isRead: false,
      targetId: chatId,
      data: {
        'chatId': chatId,
        'messagePreview': messageText,
      },
    );
  }

  // إنشاء إشعار مهمة جديد
  factory AppNotification.createTaskNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String taskTitle,
    required String taskId,
    required String taskType,
  }) {
    String title;
    String body;
    
    switch (taskType) {
      case 'new':
        title = 'مهمة جديدة';
        body = 'تم تعيين مهمة جديدة لك: $taskTitle';
        break;
      case 'update':
        title = 'تحديث مهمة';
        body = 'تم تحديث المهمة: $taskTitle';
        break;
      case 'complete':
        title = 'اكتمال مهمة';
        body = 'تم إكمال المهمة: $taskTitle';
        break;
      case 'comment':
        title = 'تعليق جديد';
        body = '$senderName علق على المهمة: $taskTitle';
        break;
      default:
        title = 'إشعار مهمة';
        body = 'هناك تحديث في المهمة: $taskTitle';
    }
    
    return AppNotification(
      id: FirebaseFirestore.instance.collection('notifications').doc().id,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      type: 'task',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      targetId: taskId,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'taskType': taskType,
      },
    );
  }

  // إنشاء إشعار مكالمة جديد
  factory AppNotification.createCallNotification({
    required String userId,
    required String callerId,
    required String callerName,
    required String callId,
    required String callType,
  }) {
    String title;
    String body;
    
    switch (callType) {
      case 'incoming':
        title = 'مكالمة واردة';
        body = 'مكالمة واردة من $callerName';
        break;
      case 'missed':
        title = 'مكالمة فائتة';
        body = 'لديك مكالمة فائتة من $callerName';
        break;
      case 'rejected':
        title = 'مكالمة مرفوضة';
        body = '$callerName رفض المكالمة';
        break;
      default:
        title = 'إشعار مكالمة';
        body = 'هناك تحديث في المكالمة من $callerName';
    }
    
    return AppNotification(
      id: FirebaseFirestore.instance.collection('notifications').doc().id,
      userId: userId,
      senderId: callerId,
      senderName: callerName,
      type: 'call_$callType',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      targetId: callId,
      data: {
        'callId': callId,
        'callType': callType,
      },
    );
  }

  // تعليم الإشعار كمقروء
  AppNotification markAsRead() {
    if (isRead) {
      return this;
    }
    
    return AppNotification(
      id: id,
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: true,
      targetId: targetId,
      data: data,
    );
  }

  // الحصول على أيقونة الإشعار
  String get iconName {
    switch (type) {
      case 'message':
        return 'message';
      case 'task':
        return 'assignment';
      case 'call_incoming':
      case 'call_missed':
      case 'call_rejected':
        return 'call';
      default:
        return 'notifications';
    }
  }

  // التحقق مما إذا كان الإشعار حديثًا (أقل من ساعة)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 1;
  }
}
