import 'package:flutter/material.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';

class IncomingCallWidget extends StatefulWidget {
  final Call call;
  final VoidCallback? onCallAccepted;
  final VoidCallback? onCallRejected;

  const IncomingCallWidget({
    Key? key,
    required this.call,
    this.onCallAccepted,
    this.onCallRejected,
  }) : super(key: key);

  @override
  State<IncomingCallWidget> createState() => _IncomingCallWidgetState();
}

class _IncomingCallWidgetState extends State<IncomingCallWidget> {
  final CallService _callService = CallService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // معلومات المتصل
          Row(
            children: [
              // صورة المتصل
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.call.callerImage.isNotEmpty
                    ? NetworkImage(widget.call.callerImage)
                    : null,
                child: widget.call.callerImage.isEmpty
                    ? const Icon(Icons.person, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // اسم المتصل وحالة المكالمة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.call.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.call,
                          size: 16,
                          color: Colors.green[300],
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'مكالمة صوتية واردة',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // أزرار الرد والرفض
          _isProcessing
              ? const CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // زر الرفض
                    _buildActionButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      label: 'رفض',
                      onPressed: _rejectCall,
                    ),
                    
                    // زر الرد
                    _buildActionButton(
                      icon: Icons.call,
                      color: Colors.green,
                      label: 'رد',
                      onPressed: _answerCall,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // بناء زر الإجراء
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 25,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // الرد على المكالمة
  Future<void> _answerCall() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // إغلاق النافذة المنبثقة
    Navigator.pop(context);
    
    // استدعاء دالة رد الاتصال إذا تم توفيرها
    if (widget.onCallAccepted != null) {
      widget.onCallAccepted!();
    }
    
    // فتح شاشة المكالمة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          call: widget.call,
          isIncoming: true,
        ),
      ),
    );
  }

  // رفض المكالمة
  Future<void> _rejectCall() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // رفض المكالمة
    await _callService.rejectCall(widget.call);
    
    // إغلاق النافذة المنبثقة
    Navigator.pop(context);
    
    // استدعاء دالة رفض الاتصال إذا تم توفيرها
    if (widget.onCallRejected != null) {
      widget.onCallRejected!();
    }
  }
}
