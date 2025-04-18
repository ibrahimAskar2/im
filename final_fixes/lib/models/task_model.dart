import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String assignerId;
  final String assignerName;
  final String assigneeId;
  final String assigneeName;
  final DateTime createdAt;
  final DateTime dueDate;
  final String status; // 'pending', 'in_progress', 'completed', 'canceled'
  final int priority; // 1 (منخفضة), 2 (متوسطة), 3 (عالية)
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> attachments;
  final Map<String, dynamic>? metadata;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignerId,
    required this.assignerName,
    required this.assigneeId,
    required this.assigneeName,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    this.priority = 2,
    this.comments = const [],
    this.attachments = const [],
    this.metadata,
  });

  // تحويل المهمة إلى Map لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignerId': assignerId,
      'assignerName': assignerName,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'priority': priority,
      'comments': comments,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  // إنشاء مهمة من Map من Firestore
  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignerId: map['assignerId'] ?? '',
      assignerName: map['assignerName'] ?? '',
      assigneeId: map['assigneeId'] ?? '',
      assigneeName: map['assigneeName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 2,
      comments: List<Map<String, dynamic>>.from(map['comments'] ?? []),
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
      metadata: map['metadata'],
    );
  }

  // إنشاء مهمة جديدة
  factory Task.create({
    required String title,
    required String description,
    required String assignerId,
    required String assignerName,
    required String assigneeId,
    required String assigneeName,
    required DateTime dueDate,
    int priority = 2,
  }) {
    return Task(
      id: FirebaseFirestore.instance.collection('tasks').doc().id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      status: 'pending',
      priority: priority,
    );
  }

  // تحديث حالة المهمة
  Task updateStatus(String newStatus) {
    return Task(
      id: id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: createdAt,
      dueDate: dueDate,
      status: newStatus,
      priority: priority,
      comments: comments,
      attachments: attachments,
      metadata: metadata,
    );
  }

  // إضافة تعليق جديد
  Task addComment({
    required String userId,
    required String userName,
    required String text,
  }) {
    final newComment = {
      'userId': userId,
      'userName': userName,
      'text': text,
      'timestamp': Timestamp.now(),
    };
    
    final updatedComments = List<Map<String, dynamic>>.from(comments);
    updatedComments.add(newComment);
    
    return Task(
      id: id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: createdAt,
      dueDate: dueDate,
      status: status,
      priority: priority,
      comments: updatedComments,
      attachments: attachments,
      metadata: metadata,
    );
  }

  // إضافة مرفق جديد
  Task addAttachment({
    required String name,
    required String url,
    required String type,
    required String size,
    required String uploaderId,
    required String uploaderName,
  }) {
    final newAttachment = {
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'timestamp': Timestamp.now(),
    };
    
    final updatedAttachments = List<Map<String, dynamic>>.from(attachments);
    updatedAttachments.add(newAttachment);
    
    return Task(
      id: id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: createdAt,
      dueDate: dueDate,
      status: status,
      priority: priority,
      comments: comments,
      attachments: updatedAttachments,
      metadata: metadata,
    );
  }

  // تحديث تاريخ الاستحقاق
  Task updateDueDate(DateTime newDueDate) {
    return Task(
      id: id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: createdAt,
      dueDate: newDueDate,
      status: status,
      priority: priority,
      comments: comments,
      attachments: attachments,
      metadata: metadata,
    );
  }

  // تحديث الأولوية
  Task updatePriority(int newPriority) {
    return Task(
      id: id,
      title: title,
      description: description,
      assignerId: assignerId,
      assignerName: assignerName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: createdAt,
      dueDate: dueDate,
      status: status,
      priority: newPriority,
      comments: comments,
      attachments: attachments,
      metadata: metadata,
    );
  }

  // التحقق مما إذا كانت المهمة متأخرة
  bool get isOverdue {
    final now = DateTime.now();
    return dueDate.isBefore(now) && status != 'completed' && status != 'canceled';
  }

  // الحصول على الوقت المتبقي للمهمة
  Duration get remainingTime {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return Duration.zero;
    }
    return dueDate.difference(now);
  }

  // الحصول على نص حالة المهمة
  String get statusText {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'canceled':
        return 'ملغاة';
      default:
        return status;
    }
  }

  // الحصول على نص أولوية المهمة
  String get priorityText {
    switch (priority) {
      case 1:
        return 'منخفضة';
      case 2:
        return 'متوسطة';
      case 3:
        return 'عالية';
      default:
        return 'متوسطة';
    }
  }

  // الحصول على لون أولوية المهمة
  int get priorityColor {
    switch (priority) {
      case 1:
        return 0xFF4CAF50; // أخضر
      case 2:
        return 0xFFFFC107; // أصفر
      case 3:
        return 0xFFF44336; // أحمر
      default:
        return 0xFFFFC107; // أصفر
    }
  }
}
