// Comment model class for task comments
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.timestamp,
  });

  // تحويل التعليق إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // إنشاء تعليق من Map من Firestore
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // إنشاء تعليق جديد
  factory Comment.create({
    required String userId,
    required String userName,
    String userImage = '',
    required String text,
  }) {
    return Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      userImage: userImage,
      text: text,
      timestamp: DateTime.now(),
    );
  }
}
