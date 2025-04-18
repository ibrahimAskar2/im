import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.call,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCallConnected = false;
  
  late Call _call;
  late Timer _callDurationTimer;
  int _callDurationInSeconds = 0;
  String _callDurationText = '00:00';

  @override
  void initState() {
    super.initState();
    _call = widget.call;
    
    // إذا كانت مكالمة واردة، الرد عليها
    if (widget.isIncoming) {
      _answerCall();
    }
    
    // الاستماع لتغييرات حالة المكالمة
    _callService.callStateStream.listen((call) {
      if (call.id == _call.id) {
        setState(() {
          _call = call;
          
          // إذا انتهت المكالمة، العودة إلى الشاشة السابقة
          if (call.status == 'ended' || call.status == 'rejected' || call.status == 'missed') {
            Navigator.pop(context);
          }
          
          // إذا تم الاتصال بالمكالمة، بدء مؤقت مدة المكالمة
          if (!_isCallConnected && call.status == 'ongoing' && _callService.currentCall != null) {
            _isCallConnected = true;
            _startCallDurationTimer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // إيقاف مؤقت مدة المكالمة
    if (_callDurationTimer.isActive) {
      _callDurationTimer.cancel();
    }
    
    // إنهاء المكالمة إذا كانت لا تزال جارية
    if (_call.status == 'ongoing') {
      _callService.endCall();
    }
    
    super.dispose();
  }

  // الرد على المكالمة
  Future<void> _answerCall() async {
    final success = await _callService.answerCall(_call);
    if (!success) {
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الرد على المكالمة')),
      );
      
      // العودة إلى الشاشة السابقة
      Navigator.pop(context);
    }
  }

  // رفض المكالمة
  Future<void> _rejectCall() async {
    final success = await _callService.rejectCall(_call);
    if (!success) {
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل رفض المكالمة')),
      );
    }
    
    // العودة إلى الشاشة السابقة
    Navigator.pop(context);
  }

  // إنهاء المكالمة
  Future<void> _endCall() async {
    final success = await _callService.endCall();
    if (!success) {
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنهاء المكالمة')),
      );
    }
    
    // العودة إلى الشاشة السابقة
    Navigator.pop(context);
  }

  // كتم/إلغاء كتم الميكروفون
  Future<void> _toggleMute() async {
    final isMuted = await _callService.toggleMute();
    setState(() {
      _isMuted = isMuted;
    });
  }

  // تشغيل/إيقاف مكبر الصوت
  Future<void> _toggleSpeaker() async {
    final isSpeakerOn = await _callService.toggleSpeaker();
    setState(() {
      _isSpeakerOn = isSpeakerOn;
    });
  }

  // بدء مؤقت مدة المكالمة
  void _startCallDurationTimer() {
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationInSeconds++;
        _updateCallDurationText();
      });
    });
  }

  // تحديث نص مدة المكالمة
  void _updateCallDurationText() {
    final minutes = (_callDurationInSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDurationInSeconds % 60).toString().padLeft(2, '0');
    _callDurationText = '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // تحديد معلومات الطرف الآخر
    final String otherUserName;
    final String otherUserImage;
    
    if (_call.callerId == _callService.currentCall?.callerId) {
      // أنا المتصل
      otherUserName = _call.receiverName;
      otherUserImage = _call.receiverImage;
    } else {
      // أنا المستقبل
      otherUserName = _call.callerName;
      otherUserImage = _call.callerImage;
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // معلومات المكالمة
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Column(
                children: [
                  // صورة المستخدم
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: otherUserImage.isNotEmpty
                        ? NetworkImage(otherUserImage)
                        : null,
                    child: otherUserImage.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // اسم المستخدم
                  Text(
                    otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // حالة المكالمة
                  Text(
                    _isCallConnected
                        ? _callDurationText
                        : widget.isIncoming
                            ? 'مكالمة واردة...'
                            : 'جاري الاتصال...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // أزرار التحكم
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر كتم الصوت
                  if (_isCallConnected)
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.white,
                      onPressed: _toggleMute,
                      label: _isMuted ? 'إلغاء الكتم' : 'كتم',
                    ),
                  
                  // زر إنهاء المكالمة
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    backgroundColor: Colors.red.shade800,
                    onPressed: _isCallConnected ? _endCall : _rejectCall,
                    label: _isCallConnected ? 'إنهاء' : 'رفض',
                    large: true,
                  ),
                  
                  // زر مكبر الصوت
                  if (_isCallConnected)
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      color: _isSpeakerOn ? Theme.of(context).primaryColor : Colors.white,
                      onPressed: _toggleSpeaker,
                      label: _isSpeakerOn ? 'إيقاف السماعة' : 'تشغيل السماعة',
                    ),
                  
                  // زر الرد (للمكالمات الواردة فقط)
                  if (widget.isIncoming && !_isCallConnected)
                    _buildControlButton(
                      icon: Icons.call,
                      color: Colors.white,
                      backgroundColor: Colors.green,
                      onPressed: _answerCall,
                      label: 'رد',
                      large: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء زر التحكم
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
    required String label,
    bool large = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: large ? 70 : 60,
          height: large ? 70 : 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[850],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: color,
            iconSize: large ? 30 : 25,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
