import 'package:flutter/material.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallService _callService = CallService();
  
  List<Call> _calls = [];
  bool _isLoading = true;
  String _userId = ''; // سيتم تحديثه من خدمة المصادقة

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  // تحميل سجل المكالمات
  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    // الحصول على معرف المستخدم الحالي
    // في التطبيق الفعلي، سيتم الحصول عليه من خدمة المصادقة
    _userId = 'current_user_id';
    
    try {
      final calls = await _callService.getCallHistory(_userId);
      setState(() {
        _calls = calls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل سجل المكالمات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المكالمات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calls.isEmpty
              ? const Center(child: Text('لا توجد مكالمات سابقة'))
              : RefreshIndicator(
                  onRefresh: _loadCallHistory,
                  child: ListView.builder(
                    itemCount: _calls.length,
                    itemBuilder: (context, index) {
                      final call = _calls[index];
                      return _buildCallItem(call);
                    },
                  ),
                ),
    );
  }

  // بناء عنصر المكالمة
  Widget _buildCallItem(Call call) {
    // تحديد معلومات الطرف الآخر
    final bool isOutgoing = call.callerId == _userId;
    final String otherUserName = isOutgoing ? call.receiverName : call.callerName;
    final String otherUserImage = isOutgoing ? call.receiverImage : call.callerImage;
    
    // تحديد أيقونة ولون المكالمة
    IconData callIcon;
    Color iconColor;
    
    if (call.status == 'missed') {
      callIcon = Icons.call_missed;
      iconColor = Colors.red;
    } else if (call.status == 'rejected') {
      callIcon = Icons.call_end;
      iconColor = Colors.orange;
    } else if (isOutgoing) {
      callIcon = Icons.call_made;
      iconColor = Colors.green;
    } else {
      callIcon = Icons.call_received;
      iconColor = Colors.blue;
    }
    
    // تنسيق التاريخ والوقت
    final dateTime = call.startTime;
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final formattedTime = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    // تنسيق المدة
    String durationText = '';
    if (call.status == 'ended' && call.duration > 0) {
      final minutes = (call.duration ~/ 60).toString().padLeft(2, '0');
      final seconds = (call.duration % 60).toString().padLeft(2, '0');
      durationText = '$minutes:$seconds';
    } else if (call.status == 'missed') {
      durationText = 'فائتة';
    } else if (call.status == 'rejected') {
      durationText = 'مرفوضة';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: otherUserImage.isNotEmpty
            ? NetworkImage(otherUserImage)
            : null,
        child: otherUserImage.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(otherUserName),
      subtitle: Row(
        children: [
          Icon(callIcon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text('$formattedDate $formattedTime'),
          if (durationText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(durationText),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.call),
        color: Theme.of(context).primaryColor,
        onPressed: () => _startNewCall(call),
      ),
      onTap: () => _showCallDetails(call),
    );
  }

  // بدء مكالمة جديدة مع نفس المستخدم
  void _startNewCall(Call call) {
    // تحديد معلومات الطرف الآخر
    final bool isOutgoing = call.callerId == _userId;
    final String otherUserId = isOutgoing ? call.receiverId : call.callerId;
    final String otherUserName = isOutgoing ? call.receiverName : call.callerName;
    final String otherUserImage = isOutgoing ? call.receiverImage : call.callerImage;
    
    // بدء مكالمة جديدة
    _callService.startCall(
      callerId: _userId,
      callerName: 'اسم المستخدم الحالي', // في التطبيق الفعلي، سيتم الحصول عليه من خدمة المصادقة
      receiverId: otherUserId,
      receiverName: otherUserName,
      receiverImage: otherUserImage,
    ).then((newCall) {
      if (newCall != null) {
        // فتح شاشة المكالمة
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: newCall,
              isIncoming: false,
            ),
          ),
        );
      } else {
        // إظهار رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل بدء المكالمة')),
        );
      }
    });
  }

  // عرض تفاصيل المكالمة
  void _showCallDetails(Call call) {
    // تحديد معلومات الطرف الآخر
    final bool isOutgoing = call.callerId == _userId;
    final String otherUserName = isOutgoing ? call.receiverName : call.callerName;
    
    // تنسيق التاريخ والوقت
    final startDateTime = call.startTime;
    final formattedStartDate = '${startDateTime.day}/${startDateTime.month}/${startDateTime.year}';
    final formattedStartTime = '${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')}';
    
    // تنسيق المدة
    String durationText = '';
    if (call.status == 'ended' && call.duration > 0) {
      final minutes = (call.duration ~/ 60).toString().padLeft(2, '0');
      final seconds = (call.duration % 60).toString().padLeft(2, '0');
      durationText = '$minutes:$seconds';
    } else if (call.status == 'missed') {
      durationText = 'فائتة';
    } else if (call.status == 'rejected') {
      durationText = 'مرفوضة';
    }
    
    // تحديد نوع المكالمة
    final callTypeText = isOutgoing ? 'صادرة' : 'واردة';
    
    // عرض نافذة منبثقة بتفاصيل المكالمة
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل المكالمة مع $otherUserName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('النوع:', callTypeText),
            _buildDetailRow('التاريخ:', formattedStartDate),
            _buildDetailRow('الوقت:', formattedStartTime),
            if (durationText.isNotEmpty)
              _buildDetailRow('المدة:', durationText),
            _buildDetailRow('الحالة:', _getStatusText(call.status)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewCall(call);
            },
            child: const Text('اتصال جديد'),
          ),
        ],
      ),
    );
  }

  // بناء صف تفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // الحصول على نص حالة المكالمة
  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return 'جارية';
      case 'ended':
        return 'منتهية';
      case 'missed':
        return 'فائتة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return status;
    }
  }
}
