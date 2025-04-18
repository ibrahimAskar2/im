import 'package:cloud_firestore/cloud_firestore.dart';

class Call {
  final String id;
  final String callerId;
  final String callerName;
  final String callerImage;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'ongoing', 'ended', 'missed', 'rejected'
  final int duration; // بالثواني
  final bool isVideoCall; // للتوسع المستقبلي

  Call({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerImage = '',
    required this.receiverId,
    required this.receiverName,
    this.receiverImage = '',
    required this.startTime,
    this.endTime,
    required this.status,
    this.duration = 0,
    this.isVideoCall = false,
  });

  // تحويل المكالمة إلى Map لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerImage': callerImage,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverImage': receiverImage,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'duration': duration,
      'isVideoCall': isVideoCall,
    };
  }

  // إنشاء مكالمة من Map من Firestore
  factory Call.fromMap(String id, Map<String, dynamic> map) {
    return Call(
      id: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerImage: map['callerImage'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverImage: map['receiverImage'] ?? '',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'ongoing',
      duration: map['duration'] ?? 0,
      isVideoCall: map['isVideoCall'] ?? false,
    );
  }

  // إنشاء مكالمة جديدة
  factory Call.create({
    required String callerId,
    required String callerName,
    String callerImage = '',
    required String receiverId,
    required String receiverName,
    String receiverImage = '',
    bool isVideoCall = false,
  }) {
    return Call(
      id: FirebaseFirestore.instance.collection('calls').doc().id,
      callerId: callerId,
      callerName: callerName,
      callerImage: callerImage,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImage: receiverImage,
      startTime: DateTime.now(),
      status: 'ongoing',
      isVideoCall: isVideoCall,
    );
  }

  // تحديث حالة المكالمة إلى "منتهية"
  Call endCall() {
    final now = DateTime.now();
    final callDuration = now.difference(startTime).inSeconds;
    
    return Call(
      id: id,
      callerId: callerId,
      callerName: callerName,
      callerImage: callerImage,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImage: receiverImage,
      startTime: startTime,
      endTime: now,
      status: 'ended',
      duration: callDuration,
      isVideoCall: isVideoCall,
    );
  }

  // تحديث حالة المكالمة إلى "فائتة"
  Call missCall() {
    return Call(
      id: id,
      callerId: callerId,
      callerName: callerName,
      callerImage: callerImage,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImage: receiverImage,
      startTime: startTime,
      endTime: DateTime.now(),
      status: 'missed',
      duration: 0,
      isVideoCall: isVideoCall,
    );
  }

  // تحديث حالة المكالمة إلى "مرفوضة"
  Call rejectCall() {
    return Call(
      id: id,
      callerId: callerId,
      callerName: callerName,
      callerImage: callerImage,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverImage: receiverImage,
      startTime: startTime,
      endTime: DateTime.now(),
      status: 'rejected',
      duration: 0,
      isVideoCall: isVideoCall,
    );
  }
}

class CallSession {
  final String sessionId;
  final String callId;
  final Map<String, dynamic> sdpOffer;
  final Map<String, dynamic>? sdpAnswer;
  final List<Map<String, dynamic>> iceCandidates;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CallSession({
    required this.sessionId,
    required this.callId,
    required this.sdpOffer,
    this.sdpAnswer,
    this.iceCandidates = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // تحويل جلسة المكالمة إلى Map لتخزينها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'sdpOffer': sdpOffer,
      'sdpAnswer': sdpAnswer,
      'iceCandidates': iceCandidates,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // إنشاء جلسة مكالمة من Map من Firestore
  factory CallSession.fromMap(String sessionId, Map<String, dynamic> map) {
    return CallSession(
      sessionId: sessionId,
      callId: map['callId'] ?? '',
      sdpOffer: map['sdpOffer'] ?? {},
      sdpAnswer: map['sdpAnswer'],
      iceCandidates: List<Map<String, dynamic>>.from(map['iceCandidates'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // إضافة إجابة SDP
  CallSession addSdpAnswer(Map<String, dynamic> answer) {
    return CallSession(
      sessionId: sessionId,
      callId: callId,
      sdpOffer: sdpOffer,
      sdpAnswer: answer,
      iceCandidates: iceCandidates,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // إضافة مرشح ICE
  CallSession addIceCandidate(Map<String, dynamic> candidate) {
    final updatedCandidates = List<Map<String, dynamic>>.from(iceCandidates);
    updatedCandidates.add(candidate);
    
    return CallSession(
      sessionId: sessionId,
      callId: callId,
      sdpOffer: sdpOffer,
      sdpAnswer: sdpAnswer,
      iceCandidates: updatedCandidates,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
