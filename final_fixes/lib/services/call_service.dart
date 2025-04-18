import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_models.dart';

class CallService {
  // Singleton pattern
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCDataChannel? _dataChannel;
  
  // Streams
  final _callStateController = StreamController<Call>.broadcast();
  Stream<Call> get callStateStream => _callStateController.stream;
  
  // Current call
  Call? _currentCall;
  Call? get currentCall => _currentCall;
  
  // ICE servers
  final List<Map<String, dynamic>> _iceServers = [
    {
      'urls': [
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302',
      ]
    }
  ];

  // تهيئة WebRTC
  Future<void> _initializePeerConnection() async {
    if (_peerConnection != null) return;
    
    final configuration = {
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    };
    
    _peerConnection = await createPeerConnection(configuration);
    
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // إرسال مرشح ICE إلى الطرف الآخر
      _sendIceCandidate(candidate);
    };
    
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE Connection State: $state');
    };
    
    _peerConnection!.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      // إشعار واجهة المستخدم بتغيير حالة المكالمة
      if (_currentCall != null) {
        _callStateController.add(_currentCall!);
      }
    };
  }

  // الحصول على إذن الميكروفون
  Future<bool> _getMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // إنشاء تدفق الوسائط المحلي
  Future<MediaStream> _createLocalStream() async {
    final mediaConstraints = {
      'audio': true,
      'video': false,
    };
    
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream = stream;
    return stream;
  }

  // بدء مكالمة جديدة
  Future<Call?> startCall({
    required String callerId,
    required String callerName,
    String callerImage = '',
    required String receiverId,
    required String receiverName,
    String receiverImage = '',
  }) async {
    try {
      // التحقق من إذن الميكروفون
      final hasPermission = await _getMicrophonePermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح إذن الميكروفون');
      }
      
      // إنشاء كائن المكالمة
      final call = Call.create(
        callerId: callerId,
        callerName: callerName,
        callerImage: callerImage,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverImage: receiverImage,
      );
      
      // حفظ المكالمة في Firestore
      await _firestore.collection('calls').doc(call.id).set(call.toMap());
      
      // تهيئة WebRTC
      await _initializePeerConnection();
      
      // إنشاء تدفق الوسائط المحلي
      final localStream = await _createLocalStream();
      
      // إضافة التدفق المحلي إلى اتصال الند للند
      localStream.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, localStream);
      });
      
      // إنشاء عرض SDP
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      // تحويل عرض SDP إلى تنسيق JSON
      final sdpOffer = parse(offer.sdp!);
      
      // إنشاء جلسة المكالمة
      final callSession = CallSession(
        sessionId: _firestore.collection('call_sessions').doc().id,
        callId: call.id,
        sdpOffer: sdpOffer,
        createdAt: DateTime.now(),
      );
      
      // حفظ جلسة المكالمة في Firestore
      await _firestore
          .collection('call_sessions')
          .doc(callSession.sessionId)
          .set(callSession.toMap());
      
      // إرسال إشعار إلى المستقبل
      await _sendCallNotification(call);
      
      // تحديث المكالمة الحالية
      _currentCall = call;
      _callStateController.add(call);
      
      return call;
    } catch (e) {
      print('Error starting call: $e');
      return null;
    }
  }

  // الرد على مكالمة واردة
  Future<bool> answerCall(Call call) async {
    try {
      // التحقق من إذن الميكروفون
      final hasPermission = await _getMicrophonePermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح إذن الميكروفون');
      }
      
      // تهيئة WebRTC
      await _initializePeerConnection();
      
      // إنشاء تدفق الوسائط المحلي
      final localStream = await _createLocalStream();
      
      // إضافة التدفق المحلي إلى اتصال الند للند
      localStream.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, localStream);
      });
      
      // الحصول على جلسة المكالمة
      final querySnapshot = await _firestore
          .collection('call_sessions')
          .where('callId', isEqualTo: call.id)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('لم يتم العثور على جلسة المكالمة');
      }
      
      final sessionDoc = querySnapshot.docs.first;
      final callSession = CallSession.fromMap(sessionDoc.id, sessionDoc.data());
      
      // تعيين وصف العرض البعيد
      final sdpOffer = callSession.sdpOffer;
      final offer = RTCSessionDescription(
        write(sdpOffer),
        'offer',
      );
      
      await _peerConnection!.setRemoteDescription(offer);
      
      // إنشاء إجابة SDP
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      // تحويل إجابة SDP إلى تنسيق JSON
      final sdpAnswer = parse(answer.sdp!);
      
      // تحديث جلسة المكالمة بإجابة SDP
      final updatedSession = callSession.addSdpAnswer(sdpAnswer);
      
      await _firestore
          .collection('call_sessions')
          .doc(callSession.sessionId)
          .update({
            'sdpAnswer': sdpAnswer,
            'updatedAt': Timestamp.now(),
          });
      
      // تحديث المكالمة الحالية
      _currentCall = call;
      _callStateController.add(call);
      
      return true;
    } catch (e) {
      print('Error answering call: $e');
      return false;
    }
  }

  // رفض مكالمة واردة
  Future<bool> rejectCall(Call call) async {
    try {
      // تحديث حالة المكالمة إلى "مرفوضة"
      final rejectedCall = call.rejectCall();
      
      await _firestore
          .collection('calls')
          .doc(call.id)
          .update({
            'status': 'rejected',
            'endTime': Timestamp.now(),
          });
      
      // إرسال إشعار إلى المتصل
      await _sendCallRejectedNotification(rejectedCall);
      
      return true;
    } catch (e) {
      print('Error rejecting call: $e');
      return false;
    }
  }

  // إنهاء المكالمة الحالية
  Future<bool> endCall() async {
    try {
      if (_currentCall == null) return false;
      
      // تحديث حالة المكالمة إلى "منتهية"
      final endedCall = _currentCall!.endCall();
      
      await _firestore
          .collection('calls')
          .doc(_currentCall!.id)
          .update({
            'status': 'ended',
            'endTime': Timestamp.now(),
            'duration': endedCall.duration,
          });
      
      // إغلاق اتصال WebRTC
      await _closeConnection();
      
      // تحديث المكالمة الحالية
      _currentCall = endedCall;
      _callStateController.add(endedCall);
      
      // إعادة تعيين المكالمة الحالية
      _currentCall = null;
      
      return true;
    } catch (e) {
      print('Error ending call: $e');
      return false;
    }
  }

  // إغلاق اتصال WebRTC
  Future<void> _closeConnection() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream!.dispose();
      _localStream = null;
    }
    
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) => track.stop());
      _remoteStream!.dispose();
      _remoteStream = null;
    }
    
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    
    if (_dataChannel != null) {
      _dataChannel!.close();
      _dataChannel = null;
    }
  }

  // إرسال مرشح ICE إلى الطرف الآخر
  Future<void> _sendIceCandidate(RTCIceCandidate candidate) async {
    if (_currentCall == null) return;
    
    try {
      final candidateMap = {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };
      
      // إرسال مرشح ICE عبر Firebase Realtime Database للتبادل السريع
      await _database
          .ref('call_ice_candidates/${_currentCall!.id}')
          .push()
          .set(candidateMap);
    } catch (e) {
      print('Error sending ICE candidate: $e');
    }
  }

  // إرسال إشعار مكالمة إلى المستقبل
  Future<void> _sendCallNotification(Call call) async {
    try {
      // إنشاء إشعار للمستقبل
      final notification = {
        'userId': call.receiverId,
        'senderId': call.callerId,
        'senderName': call.callerName,
        'type': 'call',
        'title': 'مكالمة واردة',
        'body': 'مكالمة واردة من ${call.callerName}',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'targetId': call.id,
        'data': {
          'callId': call.id,
          'isVideoCall': call.isVideoCall,
        },
      };
      
      await _firestore
          .collection('notifications')
          .add(notification);
    } catch (e) {
      print('Error sending call notification: $e');
    }
  }

  // إرسال إشعار رفض المكالمة إلى المتصل
  Future<void> _sendCallRejectedNotification(Call call) async {
    try {
      // إنشاء إشعار للمتصل
      final notification = {
        'userId': call.callerId,
        'senderId': call.receiverId,
        'senderName': call.receiverName,
        'type': 'call_rejected',
        'title': 'مكالمة مرفوضة',
        'body': '${call.receiverName} رفض المكالمة',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'targetId': call.id,
        'data': {
          'callId': call.id,
        },
      };
      
      await _firestore
          .collection('notifications')
          .add(notification);
    } catch (e) {
      print('Error sending call rejected notification: $e');
    }
  }

  // كتم/إلغاء كتم الميكروفون
  Future<bool> toggleMute() async {
    try {
      if (_localStream == null) return false;
      
      final audioTrack = _localStream!.getAudioTracks().first;
      final enabled = !audioTrack.enabled;
      audioTrack.enabled = enabled;
      
      return enabled;
    } catch (e) {
      print('Error toggling mute: $e');
      return false;
    }
  }

  // تشغيل/إيقاف مكبر الصوت
  Future<bool> toggleSpeaker() async {
    try {
      // تنفيذ تبديل مكبر الصوت
      // ملاحظة: هذا يتطلب استخدام مكتبات إضافية مثل flutter_sound
      return true;
    } catch (e) {
      print('Error toggling speaker: $e');
      return false;
    }
  }

  // الحصول على سجل المكالمات للمستخدم
  Future<List<Call>> getCallHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('calls')
          .where(Filter.or(
            Filter('callerId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ))
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();
      
      final calls = querySnapshot.docs.map((doc) {
        return Call.fromMap(doc.id, doc.data());
      }).toList();
      
      return calls;
    } catch (e) {
      print('Error getting call history: $e');
      return [];
    }
  }

  // التخلص من الموارد
  void dispose() {
    _closeConnection();
    _callStateController.close();
  }
}
