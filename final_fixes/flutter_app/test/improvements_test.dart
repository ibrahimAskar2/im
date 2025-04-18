import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/user_model.dart';
import '../lib/models/message_model.dart';
import '../lib/models/notification_model.dart';
import '../lib/models/task_model.dart';
import '../lib/models/call_models.dart';

void main() {
  group('اختبار نماذج البيانات', () {
    test('اختبار نموذج المستخدم', () {
      final user = User(
        id: 'user123',
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        department: 'تقنية المعلومات',
        position: 'مطور برمجيات',
        isOnline: true,
      );
      
      expect(user.id, 'user123');
      expect(user.name, 'أحمد محمد');
      expect(user.email, 'ahmed@example.com');
      expect(user.department, 'تقنية المعلومات');
      expect(user.position, 'مطور برمجيات');
      expect(user.isOnline, true);
      
      // اختبار تحويل المستخدم إلى Map
      final userMap = user.toMap();
      expect(userMap['name'], 'أحمد محمد');
      expect(userMap['email'], 'ahmed@example.com');
      expect(userMap['department'], 'تقنية المعلومات');
      expect(userMap['position'], 'مطور برمجيات');
      expect(userMap['isOnline'], true);
      
      // اختبار إنشاء مستخدم من Map
      final userFromMap = User.fromMap('user123', userMap);
      expect(userFromMap.id, 'user123');
      expect(userFromMap.name, 'أحمد محمد');
      expect(userFromMap.email, 'ahmed@example.com');
      expect(userFromMap.department, 'تقنية المعلومات');
      expect(userFromMap.position, 'مطور برمجيات');
      expect(userFromMap.isOnline, true);
      
      // اختبار تحديث حالة الاتصال
      final offlineUser = user.updateOnlineStatus(false);
      expect(offlineUser.isOnline, false);
      
      // اختبار الحصول على الحروف الأولى من اسم المستخدم
      expect(user.initials, 'أم');
    });
    
    test('اختبار نموذج الرسالة', () {
      final message = Message(
        id: 'msg123',
        chatId: 'chat123',
        senderId: 'user123',
        text: 'مرحباً، كيف حالك؟',
        timestamp: DateTime(2025, 4, 11, 10, 30),
        isRead: false,
        readBy: ['user123'],
        type: 'text',
      );
      
      expect(message.id, 'msg123');
      expect(message.chatId, 'chat123');
      expect(message.senderId, 'user123');
      expect(message.text, 'مرحباً، كيف حالك؟');
      expect(message.timestamp, DateTime(2025, 4, 11, 10, 30));
      expect(message.isRead, false);
      expect(message.readBy, ['user123']);
      expect(message.type, 'text');
      
      // اختبار تحويل الرسالة إلى Map
      final messageMap = message.toMap();
      expect(messageMap['chatId'], 'chat123');
      expect(messageMap['senderId'], 'user123');
      expect(messageMap['text'], 'مرحباً، كيف حالك؟');
      expect(messageMap['isRead'], false);
      expect(messageMap['readBy'], ['user123']);
      expect(messageMap['type'], 'text');
      
      // اختبار إنشاء رسالة من Map
      final messageFromMap = Message.fromMap('msg123', messageMap);
      expect(messageFromMap.id, 'msg123');
      expect(messageFromMap.chatId, 'chat123');
      expect(messageFromMap.senderId, 'user123');
      expect(messageFromMap.text, 'مرحباً، كيف حالك؟');
      expect(messageFromMap.isRead, false);
      expect(messageFromMap.readBy, ['user123']);
      expect(messageFromMap.type, 'text');
      
      // اختبار تعليم الرسالة كمقروءة
      final readMessage = message.markAsReadBy('user456');
      expect(readMessage.isRead, true);
      expect(readMessage.readBy, ['user123', 'user456']);
      
      // اختبار إنشاء رسالة نصية
      final textMessage = Message.createText(
        chatId: 'chat123',
        senderId: 'user123',
        text: 'رسالة نصية جديدة',
      );
      expect(textMessage.chatId, 'chat123');
      expect(textMessage.senderId, 'user123');
      expect(textMessage.text, 'رسالة نصية جديدة');
      expect(textMessage.type, 'text');
      expect(textMessage.readBy, ['user123']);
    });
    
    test('اختبار نموذج الإشعار', () {
      final notification = Notification(
        id: 'notif123',
        userId: 'user456',
        senderId: 'user123',
        senderName: 'أحمد محمد',
        type: 'message',
        title: 'رسالة جديدة',
        body: 'أحمد محمد: مرحباً، كيف حالك؟',
        timestamp: DateTime(2025, 4, 11, 10, 30),
        isRead: false,
        targetId: 'chat123',
        data: {
          'chatId': 'chat123',
          'messagePreview': 'مرحباً، كيف حالك؟',
        },
      );
      
      expect(notification.id, 'notif123');
      expect(notification.userId, 'user456');
      expect(notification.senderId, 'user123');
      expect(notification.senderName, 'أحمد محمد');
      expect(notification.type, 'message');
      expect(notification.title, 'رسالة جديدة');
      expect(notification.body, 'أحمد محمد: مرحباً، كيف حالك؟');
      expect(notification.timestamp, DateTime(2025, 4, 11, 10, 30));
      expect(notification.isRead, false);
      expect(notification.targetId, 'chat123');
      expect(notification.data?['chatId'], 'chat123');
      expect(notification.data?['messagePreview'], 'مرحباً، كيف حالك؟');
      
      // اختبار تحويل الإشعار إلى Map
      final notificationMap = notification.toMap();
      expect(notificationMap['userId'], 'user456');
      expect(notificationMap['senderId'], 'user123');
      expect(notificationMap['senderName'], 'أحمد محمد');
      expect(notificationMap['type'], 'message');
      expect(notificationMap['title'], 'رسالة جديدة');
      expect(notificationMap['body'], 'أحمد محمد: مرحباً، كيف حالك؟');
      expect(notificationMap['isRead'], false);
      expect(notificationMap['targetId'], 'chat123');
      expect(notificationMap['data']?['chatId'], 'chat123');
      expect(notificationMap['data']?['messagePreview'], 'مرحباً، كيف حالك؟');
      
      // اختبار إنشاء إشعار من Map
      final notificationFromMap = Notification.fromMap('notif123', notificationMap);
      expect(notificationFromMap.id, 'notif123');
      expect(notificationFromMap.userId, 'user456');
      expect(notificationFromMap.senderId, 'user123');
      expect(notificationFromMap.senderName, 'أحمد محمد');
      expect(notificationFromMap.type, 'message');
      expect(notificationFromMap.title, 'رسالة جديدة');
      expect(notificationFromMap.body, 'أحمد محمد: مرحباً، كيف حالك؟');
      expect(notificationFromMap.isRead, false);
      expect(notificationFromMap.targetId, 'chat123');
      expect(notificationFromMap.data?['chatId'], 'chat123');
      expect(notificationFromMap.data?['messagePreview'], 'مرحباً، كيف حالك؟');
      
      // اختبار تعليم الإشعار كمقروء
      final readNotification = notification.markAsRead();
      expect(readNotification.isRead, true);
      
      // اختبار إنشاء إشعار رسالة
      final messageNotification = Notification.createMessageNotification(
        userId: 'user456',
        senderId: 'user123',
        senderName: 'أحمد محمد',
        messageText: 'رسالة جديدة للاختبار',
        chatId: 'chat123',
      );
      expect(messageNotification.userId, 'user456');
      expect(messageNotification.senderId, 'user123');
      expect(messageNotification.senderName, 'أحمد محمد');
      expect(messageNotification.type, 'message');
      expect(messageNotification.title, 'رسالة جديدة');
      expect(messageNotification.body.contains('أحمد محمد'), true);
      expect(messageNotification.body.contains('رسالة جديدة للاختبار'), true);
      expect(messageNotification.isRead, false);
      expect(messageNotification.targetId, 'chat123');
      expect(messageNotification.data?['chatId'], 'chat123');
      expect(messageNotification.data?['messagePreview'], 'رسالة جديدة للاختبار');
    });
    
    test('اختبار نموذج المهمة', () {
      final task = Task(
        id: 'task123',
        title: 'إعداد تقرير المبيعات',
        description: 'إعداد تقرير المبيعات الشهري لشهر أبريل 2025',
        assignerId: 'user123',
        assignerName: 'أحمد محمد',
        assigneeId: 'user456',
        assigneeName: 'محمد علي',
        createdAt: DateTime(2025, 4, 10),
        dueDate: DateTime(2025, 4, 15),
        status: 'pending',
        priority: 2,
        comments: [
          {
            'userId': 'user123',
            'userName': 'أحمد محمد',
            'text': 'يرجى إضافة الرسوم البيانية',
            'timestamp': Timestamp.fromDate(DateTime(2025, 4, 11, 9, 0)),
          }
        ],
        attachments: [],
      );
      
      expect(task.id, 'task123');
      expect(task.title, 'إعداد تقرير المبيعات');
      expect(task.description, 'إعداد تقرير المبيعات الشهري لشهر أبريل 2025');
      expect(task.assignerId, 'user123');
      expect(task.assignerName, 'أحمد محمد');
      expect(task.assigneeId, 'user456');
      expect(task.assigneeName, 'محمد علي');
      expect(task.createdAt, DateTime(2025, 4, 10));
      expect(task.dueDate, DateTime(2025, 4, 15));
      expect(task.status, 'pending');
      expect(task.priority, 2);
      expect(task.comments.length, 1);
      expect(task.comments[0]['userId'], 'user123');
      expect(task.comments[0]['text'], 'يرجى إضافة الرسوم البيانية');
      expect(task.attachments.length, 0);
      
      // اختبار تحويل المهمة إلى Map
      final taskMap = task.toMap();
      expect(taskMap['title'], 'إعداد تقرير المبيعات');
      expect(taskMap['description'], 'إعداد تقرير المبيعات الشهري لشهر أبريل 2025');
      expect(taskMap['assignerId'], 'user123');
      expect(taskMap['assignerName'], 'أحمد محمد');
      expect(taskMap['assigneeId'], 'user456');
      expect(taskMap['assigneeName'], 'محمد علي');
      expect(taskMap['status'], 'pending');
      expect(taskMap['priority'], 2);
      expect(taskMap['comments'].length, 1);
      expect(taskMap['comments'][0]['userId'], 'user123');
      expect(taskMap['comments'][0]['text'], 'يرجى إضافة الرسوم البيانية');
      expect(taskMap['attachments'].length, 0);
      
      // اختبار إنشاء مهمة من Map
      final taskFromMap = Task.fromMap('task123', taskMap);
      expect(taskFromMap.id, 'task123');
      expect(taskFromMap.title, 'إعداد تقرير المبيعات');
      expect(taskFromMap.description, 'إعداد تقرير المبيعات الشهري لشهر أبريل 2025');
      expect(taskFromMap.assignerId, 'user123');
      expect(taskFromMap.assignerName, 'أحمد محمد');
      expect(taskFromMap.assigneeId, 'user456');
      expect(taskFromMap.assigneeName, 'محمد علي');
      expect(taskFromMap.status, 'pending');
      expect(taskFromMap.priority, 2);
      expect(taskFromMap.comments.length, 1);
      expect(taskFromMap.comments[0]['userId'], 'user123');
      expect(taskFromMap.comments[0]['text'], 'يرجى إضافة الرسوم البيانية');
      expect(taskFromMap.attachments.length, 0);
      
      // اختبار تحديث حالة المهمة
      final completedTask = task.updateStatus('completed');
      expect(completedTask.status, 'completed');
      
      // اختبار إضافة تعليق
      final taskWithComment = task.addComment(
        userId: 'user456',
        userName: 'محمد علي',
        text: 'سأضيف الرسوم البيانية',
      );
      expect(taskWithComment.comments.length, 2);
      expect(taskWithComment.comments[1]['userId'], 'user456');
      expect(taskWithComment.comments[1]['userName'], 'محمد علي');
      expect(taskWithComment.comments[1]['text'], 'سأضيف الرسوم البيانية');
      
      // اختبار إضافة مرفق
      final taskWithAttachment = task.addAttachment(
        name: 'تقرير.pdf',
        url: 'https://example.com/report.pdf',
        type: 'application/pdf',
        size: '2.5MB',
        uploaderId: 'user456',
        uploaderName: 'محمد علي',
      );
      expect(taskWithAttachment.attachments.length, 1);
      expect(taskWithAttachment.attachments[0]['name'], 'تقرير.pdf');
      expect(taskWithAttachment.attachments[0]['url'], 'https://example.com/report.pdf');
      expect(taskWithAttachment.attachments[0]['type'], 'application/pdf');
      expect(taskWithAttachment.attachments[0]['size'], '2.5MB');
      expect(taskWithAttachment.attachments[0]['uploaderId'], 'user456');
      expect(taskWithAttachment.attachments[0]['uploaderName'], 'محمد علي');
      
      // اختبار الحصول على نص حالة المهمة
      expect(task.statusText, 'قيد الانتظار');
      expect(completedTask.statusText, 'مكتملة');
      
      // اختبار الحصول على نص أولوية المهمة
      expect(task.priorityText, 'متوسطة');
      
      // اختبار إنشاء مهمة جديدة
      final newTask = Task.create(
        title: 'مهمة جديدة',
        description: 'وصف المهمة الجديدة',
        assignerId: 'user123',
        assignerName: 'أحمد محمد',
        assigneeId: 'user456',
        assigneeName: 'محمد علي',
        dueDate: DateTime(2025, 4, 20),
        priority: 3,
      );
      expect(newTask.title, 'مهمة جديدة');
      expect(newTask.description, 'وصف المهمة الجديدة');
      expect(newTask.assignerId, 'user123');
      expect(newTask.assignerName, 'أحمد محمد');
      expect(newTask.assigneeId, 'user456');
      expect(newTask.assigneeName, 'محمد علي');
      expect(newTask.dueDate, DateTime(2025, 4, 20));
      expect(newTask.status, 'pending');
      expect(newTask.priority, 3);
      expect(newTask.priorityText, 'عالية');
    });
    
    test('اختبار نموذج المكالمة', () {
      final call = Call(
        id: 'call123',
        callerId: 'user123',
        callerName: 'أحمد محمد',
        callerImage: 'https://example.com/ahmed.jpg',
        receiverId: 'user456',
        receiverName: 'محمد علي',
        receiverImage: 'https://example.com/mohamed.jpg',
        status: CallStatus.ongoing,
        startTime: DateTime(2025, 4, 11, 10, 30),
        endTime: null,
      );
      
      expect(call.id, 'call123');
      expect(call.callerId, 'user123');
      expect(call.callerName, 'أحمد محمد');
      expect(call.callerImage, 'https://example.com/ahmed.jpg');
      expect(call.receiverId, 'user456');
      expect(call.receiverName, 'محمد علي');
      expect(call.receiverImage, 'https://example.com/mohamed.jpg');
      expect(call.status, CallStatus.ongoing);
      expect(call.startTime, DateTime(2025, 4, 11, 10, 30));
      expect(call.endTime, null);
      
      // اختبار تحويل المكالمة إلى Map
      final callMap = call.toMap();
      expect(callMap['callerId'], 'user123');
      expect(callMap['callerName'], 'أحمد محمد');
      expect(callMap['callerImage'], 'https://example.com/ahmed.jpg');
      expect(callMap['receiverId'], 'user456');
      expect(callMap['receiverName'], 'محمد علي');
      expect(callMap['receiverImage'], 'https://example.com/mohamed.jpg');
      expect(callMap['status'], 'ongoing');
      
      // اختبار إنشاء مكالمة من Map
      final callFromMap = Call.fromMap('call123', callMap);
      expect(callFromMap.id, 'call123');
      expect(callFromMap.callerId, 'user123');
      expect(callFromMap.callerName, 'أحمد محمد');
      expect(callFromMap.callerImage, 'https://example.com/ahmed.jpg');
      expect(callFromMap.receiverId, 'user456');
      expect(callFromMap.receiverName, 'محمد علي');
      expect(callFromMap.receiverImage, 'https://example.com/mohamed.jpg');
      expect(callFromMap.status, CallStatus.ongoing);
      
      // اختبار تحديث حالة المكالمة
      final endedCall = call.copyWith(
        status: CallStatus.ended,
        endTime: DateTime(2025, 4, 11, 10, 35),
      );
      expect(endedCall.status, CallStatus.ended);
      expect(endedCall.endTime, DateTime(2025, 4, 11, 10, 35));
      
      // اختبار حساب مدة المكالمة
      expect(endedCall.duration.inMinutes, 5);
      
      // اختبار الحصول على نص حالة المكالمة
      expect(call.statusText, 'جارية');
      expect(endedCall.statusText, 'منتهية');
    });
  });
}
