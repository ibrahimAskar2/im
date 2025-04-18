import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class PaginatedNotificationsScreen extends StatefulWidget {
  const PaginatedNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<PaginatedNotificationsScreen> createState() => _PaginatedNotificationsScreenState();
}

class _PaginatedNotificationsScreenState extends State<PaginatedNotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  // عدد الإشعارات في كل تحميل
  final int _notificationsPerLoad = 20;
  
  // قائمة الإشعارات غير المقروءة
  final List<String> _unreadNotificationIds = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    
    // إضافة مستمع للتمرير لتحميل المزيد من الإشعارات
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    
    // تعليم الإشعارات غير المقروءة كمقروءة عند الخروج من الشاشة
    if (_unreadNotificationIds.isNotEmpty) {
      _firestoreService.markNotificationsAsRead(_unreadNotificationIds);
    }
    
    super.dispose();
  }

  // مستمع التمرير لتحميل المزيد من الإشعارات
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreNotifications();
      }
    }
  }

  // تحميل الإشعارات الأولية
  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notifications = await _firestoreService.getNotifications(
        limit: _notificationsPerLoad,
      );
      
      // جمع معرفات الإشعارات غير المقروءة
      _collectUnreadNotificationIds(notifications);
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _hasMore = notifications.length >= _notificationsPerLoad;
        
        if (notifications.isNotEmpty) {
          // الحصول على آخر وثيقة للتحميل المتدرج
          _lastDocument = FirebaseFirestore.instance
              .collection('notifications')
              .doc(notifications.last['id']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل الإشعارات: $e')),
      );
    }
  }

  // تحميل المزيد من الإشعارات
  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final moreNotifications = await _firestoreService.getNotifications(
        limit: _notificationsPerLoad,
        lastDocument: _lastDocument,
      );
      
      // جمع معرفات الإشعارات غير المقروءة
      _collectUnreadNotificationIds(moreNotifications);
      
      setState(() {
        _notifications.addAll(moreNotifications);
        _isLoading = false;
        _hasMore = moreNotifications.length >= _notificationsPerLoad;
        
        if (moreNotifications.isNotEmpty) {
          // تحديث آخر وثيقة للتحميل المتدرج
          _lastDocument = FirebaseFirestore.instance
              .collection('notifications')
              .doc(moreNotifications.last['id']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل المزيد من الإشعارات: $e')),
      );
    }
  }

  // جمع معرفات الإشعارات غير المقروءة
  void _collectUnreadNotificationIds(List<Map<String, dynamic>> notifications) {
    for (var notification in notifications) {
      if (notification['isRead'] == false) {
        _unreadNotificationIds.add(notification['id']);
      }
    }
  }

  // تعليم جميع الإشعارات كمقروءة
  Future<void> _markAllAsRead() async {
    if (_unreadNotificationIds.isEmpty) return;
    
    try {
      await _firestoreService.markNotificationsAsRead(_unreadNotificationIds);
      
      setState(() {
        // تحديث حالة الإشعارات في القائمة المحلية
        for (var i = 0; i < _notifications.length; i++) {
          if (_notifications[i]['isRead'] == false) {
            _notifications[i] = {
              ..._notifications[i],
              'isRead': true,
            };
          }
        }
        
        // مسح قائمة الإشعارات غير المقروءة
        _unreadNotificationIds.clear();
      });
      
      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعليم جميع الإشعارات كمقروءة')),
      );
    } catch (e) {
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تعليم الإشعارات كمقروءة: $e')),
      );
    }
  }

  // معالجة النقر على الإشعار
  void _handleNotificationTap(Map<String, dynamic> notification) {
    // تعليم الإشعار كمقروء إذا لم يكن مقروءاً بالفعل
    if (notification['isRead'] == false) {
      _firestoreService.markNotificationsAsRead([notification['id']]);
      
      // إزالة معرف الإشعار من قائمة الإشعارات غير المقروءة
      _unreadNotificationIds.remove(notification['id']);
      
      // تحديث حالة الإشعار في القائمة المحلية
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notification['id']);
        if (index != -1) {
          _notifications[index] = {
            ..._notifications[index],
            'isRead': true,
          };
        }
      });
    }
    
    // التنقل إلى الشاشة المناسبة حسب نوع الإشعار
    final type = notification['type'];
    final targetId = notification['targetId'];
    
    switch (type) {
      case 'message':
        // التنقل إلى شاشة الدردشة
        // في التطبيق الفعلي، سيتم التنقل إلى شاشة الدردشة المناسبة
        break;
      case 'task':
        // التنقل إلى شاشة المهمة
        // في التطبيق الفعلي، سيتم التنقل إلى شاشة المهمة المناسبة
        break;
      case 'call':
      case 'call_missed':
      case 'call_rejected':
        // التنقل إلى شاشة المكالمة أو سجل المكالمات
        // في التطبيق الفعلي، سيتم التنقل إلى الشاشة المناسبة
        break;
      default:
        // لا شيء
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          // زر تعليم الكل كمقروء
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _unreadNotificationIds.isEmpty ? null : _markAllAsRead,
            tooltip: 'تعليم الكل كمقروء',
          ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('لا توجد إشعارات'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  // بناء عنصر الإشعار
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final timestamp = (notification['timestamp'] as Timestamp).toDate();
    final time = '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    final date = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    
    // تحديد الأيقونة حسب نوع الإشعار
    IconData icon;
    Color iconColor;
    
    switch (notification['type']) {
      case 'message':
        icon = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'task':
        icon = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case 'call':
        icon = Icons.call;
        iconColor = Colors.green;
        break;
      case 'call_missed':
        icon = Icons.call_missed;
        iconColor = Colors.red;
        break;
      case 'call_rejected':
        icon = Icons.call_end;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        notification['title'] ?? '',
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification['body'] ?? ''),
          Text(
            '$date $time',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: isRead
          ? null
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => _handleNotificationTap(notification),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
