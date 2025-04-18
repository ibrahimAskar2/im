import 'package:flutter/material.dart';
import '../models/call_models.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';

class ChatHeader extends StatelessWidget {
  final String userId;
  final String userName;
  final String userImage;
  final bool isOnline;

  const ChatHeader({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userImage,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // صورة المستخدم
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: userImage.isNotEmpty
                    ? NetworkImage(userImage)
                    : null,
                child: userImage.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          
          // اسم المستخدم وحالة الاتصال
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isOnline ? 'متصل الآن' : 'غير متصل',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // زر المكالمة الصوتية
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () => _initiateCall(context),
          tooltip: 'مكالمة صوتية',
        ),
        // زر القائمة
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context),
          tooltip: 'المزيد من الخيارات',
        ),
      ],
    );
  }

  // بدء مكالمة صوتية
  void _initiateCall(BuildContext context) async {
    final callService = CallService();
    final call = await callService.initiateCall(userId);
    
    if (call != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            call: call,
            isIncoming: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل بدء المكالمة')),
      );
    }
  }

  // عرض خيارات إضافية
  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('بحث في المحادثة'),
            onTap: () {
              Navigator.pop(context);
              // تنفيذ البحث في المحادثة
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('حظر المستخدم'),
            onTap: () {
              Navigator.pop(context);
              // تنفيذ حظر المستخدم
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('حذف المحادثة'),
            onTap: () {
              Navigator.pop(context);
              // تنفيذ حذف المحادثة
            },
          ),
        ],
      ),
    );
  }
}
