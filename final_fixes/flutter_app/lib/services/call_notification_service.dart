import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';
import '../widgets/incoming_call_widget.dart';

class CallNotificationService {
  // Singleton pattern
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  // Services
  final CallService _callService = CallService();
  
  // Notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Streams
  final _incomingCallController = StreamController<Call>.broadcast();
  Stream<Call> get incomingCallStream => _incomingCallController.stream;
  
  // تهيئة خدمة الإشعارات
  Future<void> initialize(BuildContext context) async {
    // تهيئة إشعارات Firebase
    await _initializeFirebaseMessaging();
    
    // تهيئة الإشعارات المحلية
    await _initializeLocalNotifications(context);
    
    // الاستماع للمكالمات الواردة
    _listenForIncomingCalls(context);
  }

  // تهيئة إشعارات Firebase
  Future<void> _initializeFirebaseMessaging() async {
    // طلب إذن الإشعارات
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // الاستماع للإشعارات في الخلفية
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // الاستماع للإشعارات في المقدمة
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleFirebaseMessage(message);
      });
      
      // الاستماع للإشعارات عند النقر عليها
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleFirebaseMessageOpenedApp(message);
      });
    }
  }

  // تهيئة الإشعارات المحلية
  Future<void> _initializeLocalNotifications(BuildContext context) async {
    // تهيئة إعدادات الإشعارات المحلية
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response, context);
      },
    );
  }

  // الاستماع للمكالمات الواردة
  void _listenForIncomingCalls(BuildContext context) {
    // الاستماع للمكالمات الواردة من خدمة المكالمات
    // في التطبيق الفعلي، سيتم استخدام Firestore لتتبع المكالمات الواردة
  }

  // معالجة رسائل Firebase في الخلفية
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // معالجة الإشعارات في الخلفية
    if (message.data['type'] == 'call') {
      // عرض إشعار مكالمة واردة
      // في التطبيق الفعلي، سيتم استخدام إشعارات عالية الأولوية
    }
  }

  // معالجة رسائل Firebase في المقدمة
  void _handleFirebaseMessage(RemoteMessage message) {
    if (message.data['type'] == 'call') {
      // استخراج بيانات المكالمة
      final callId = message.data['callId'];
      final callerId = message.data['callerId'];
      final callerName = message.data['callerName'];
      final callerImage = message.data['callerImage'] ?? '';
      final receiverId = message.data['receiverId'];
      final receiverName = message.data['receiverName'];
      final receiverImage = message.data['receiverImage'] ?? '';
      
      // إنشاء كائن المكالمة
      final call = Call(
        id: callId,
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverImage: receiverImage,
        startTime: DateTime.now(),
        status: 'ongoing',
      );
      
      // إرسال المكالمة إلى تدفق المكالمات الواردة
      _incomingCallController.add(call);
      
      // عرض إشعار مكالمة واردة
      _showIncomingCallNotification(call);
    }
  }

  // معالجة النقر على رسائل Firebase
  void _handleFirebaseMessageOpenedApp(RemoteMessage message) {
    if (message.data['type'] == 'call') {
      // استخراج بيانات المكالمة
      final callId = message.data['callId'];
      
      // الحصول على تفاصيل المكالمة من Firestore
      // في التطبيق الفعلي، سيتم استخدام Firestore للحصول على تفاصيل المكالمة
    }
  }

  // معالجة النقر على الإشعارات المحلية
  void _handleLocalNotificationTap(NotificationResponse response, BuildContext context) {
    final payload = response.payload;
    if (payload != null && payload.startsWith('call:')) {
      final callId = payload.substring(5);
      
      // الحصول على تفاصيل المكالمة من Firestore
      // في التطبيق الفعلي، سيتم استخدام Firestore للحصول على تفاصيل المكالمة
    }
  }

  // عرض إشعار مكالمة واردة
  Future<void> _showIncomingCallNotification(Call call) async {
    // تعريف قنوات الإشعارات للأندرويد
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'call_channel',
      'المكالمات',
      channelDescription: 'إشعارات المكالمات الواردة',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('ringtone'),
      playSound: true,
      ongoing: true,
      autoCancel: false,
    );
    
    // تعريف إعدادات الإشعارات للـ iOS
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ringtone.aiff',
    );
    
    // تعريف إعدادات الإشعارات
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // عرض الإشعار
    await _flutterLocalNotificationsPlugin.show(
      call.id.hashCode,
      'مكالمة واردة',
      'مكالمة واردة من ${call.callerName}',
      platformChannelSpecifics,
      payload: 'call:${call.id}',
    );
  }

  // عرض نافذة المكالمة الواردة
  void showIncomingCallDialog(BuildContext context, Call call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncomingCallWidget(
        call: call,
        onCallAccepted: () {
          // إلغاء الإشعار
          _flutterLocalNotificationsPlugin.cancel(call.id.hashCode);
        },
        onCallRejected: () {
          // إلغاء الإشعار
          _flutterLocalNotificationsPlugin.cancel(call.id.hashCode);
        },
      ),
    );
  }

  // إلغاء إشعار المكالمة
  Future<void> cancelCallNotification(String callId) async {
    await _flutterLocalNotificationsPlugin.cancel(callId.hashCode);
  }

  // التخلص من الموارد
  void dispose() {
    _incomingCallController.close();
  }
}
