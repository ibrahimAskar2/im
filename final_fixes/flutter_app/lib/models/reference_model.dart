import 'package:cloud_firestore/cloud_firestore.dart';

class Reference {
  final String id;
  final String title;
  final String content;
  final String category;
  final String department;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  Reference({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.department,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.metadata,
  });

  // تحويل المرجع إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'department': department,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'metadata': metadata,
    };
  }

  // إنشاء مرجع من Map من Firestore
  factory Reference.fromMap(String id, Map<String, dynamic> map) {
    return Reference(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      department: map['department'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'],
    );
  }

  // إنشاء مرجع جديد
  factory Reference.create({
    required String title,
    required String content,
    required String category,
    required String department,
    required String creatorId,
    required String creatorName,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return Reference(
      id: FirebaseFirestore.instance.collection('references').doc().id,
      title: title,
      content: content,
      category: category,
      department: department,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );
  }

  // تحديث محتوى المرجع
  Reference updateContent({
    required String title,
    required String content,
    required String category,
    required String department,
    List<String>? tags,
  }) {
    return Reference(
      id: id,
      title: title,
      content: content,
      category: category,
      department: department,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
      metadata: metadata,
    );
  }

  // إضافة وسم جديد
  Reference addTag(String tag) {
    if (tags.contains(tag)) {
      return this;
    }
    
    final updatedTags = List<String>.from(tags);
    updatedTags.add(tag);
    
    return Reference(
      id: id,
      title: title,
      content: content,
      category: category,
      department: department,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: updatedTags,
      metadata: metadata,
    );
  }

  // إزالة وسم
  Reference removeTag(String tag) {
    final updatedTags = List<String>.from(tags);
    updatedTags.remove(tag);
    
    return Reference(
      id: id,
      title: title,
      content: content,
      category: category,
      department: department,
      creatorId: creatorId,
      creatorName: creatorName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: updatedTags,
      metadata: metadata,
    );
  }

  // الحصول على وقت التحديث بتنسيق مقروء
  String get formattedUpdateTime {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
