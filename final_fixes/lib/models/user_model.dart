import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String department;
  final String position;
  final String imageUrl;
  final bool isOnline;
  final DateTime lastActive;
  final Map<String, dynamic> settings;
  final String role; // إضافة حقل الدور

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    this.position = '',
    this.imageUrl = '',
    this.isOnline = false,
    DateTime? lastActive,
    this.settings = const {},
    this.role = 'employee', // القيمة الافتراضية هي موظف
  }) : lastActive = lastActive ?? DateTime.now();

  // تحويل المستخدم إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'department': department,
      'position': position,
      'imageUrl': imageUrl,
      'isOnline': isOnline,
      'lastActive': Timestamp.fromDate(lastActive),
      'settings': settings,
      'role': role, // إضافة الدور إلى البيانات المخزنة
    };
  }

  // إنشاء مستخدم من Map من Firestore
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      position: map['position'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: map['settings'] ?? {},
      role: map['role'] ?? 'employee', // استخراج الدور من البيانات
    );
  }

  // إنشاء نسخة معدلة من المستخدم
  User copyWith({
    String? name,
    String? email,
    String? department,
    String? position,
    String? imageUrl,
    bool? isOnline,
    DateTime? lastActive,
    Map<String, dynamic>? settings,
    String? role,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      position: position ?? this.position,
      imageUrl: imageUrl ?? this.imageUrl,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      settings: settings ?? this.settings,
      role: role ?? this.role, // إضافة الدور إلى نسخة معدلة
    );
  }

  // تحديث حالة الاتصال
  User updateOnlineStatus(bool isOnline) {
    return copyWith(
      isOnline: isOnline,
      lastActive: isOnline ? null : DateTime.now(),
    );
  }

  // تحديث إعدادات المستخدم
  User updateSettings(Map<String, dynamic> newSettings) {
    return copyWith(
      settings: {
        ...settings,
        ...newSettings,
      },
    );
  }

  // الحصول على الحروف الأولى من اسم المستخدم
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    } else {
      return '';
    }
  }

  // التحقق مما إذا كان المستخدم نشطًا مؤخرًا
  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    return difference.inMinutes < 5;
  }

  // الحصول على حالة المستخدم كنص
  String get statusText {
    if (isOnline) {
      return 'متصل الآن';
    } else if (isRecentlyActive) {
      return 'نشط مؤخرًا';
    } else {
      return 'غير متصل';
    }
  }
  
  // التحقق مما إذا كان المستخدم مشرفًا
  bool get isAdmin {
    return role == 'admin';
  }
}
