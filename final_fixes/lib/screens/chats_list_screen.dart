import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل قائمة الدردشات عند تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadChats();
    });
  }

  // إنشاء دردشة فردية جديدة
  Future<void> _createPrivateChat() async {
    // في التطبيق الفعلي، سيتم هنا فتح شاشة اختيار المستخدم
    // ثم إنشاء دردشة فردية مع المستخدم المختار
    
    // مثال:
    // final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // final chatId = await chatProvider.createPrivateChat(otherUserId);
    // if (chatId != null) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => ChatScreen(
    //         chatId: chatId,
    //         chatName: otherUserName,
    //       ),
    //     ),
    //   );
    // }
  }

  // إنشاء مجموعة دردشة جديدة
  Future<void> _createGroupChat() async {
    // في التطبيق الفعلي، سيتم هنا فتح شاشة إنشاء مجموعة
    // حيث يمكن للمستخدم إدخال اسم المجموعة واختيار المشاركين
    
    // مثال:
    // final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // final chatId = await chatProvider.createGroupChat(groupName, participants);
    // if (chatId != null) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => ChatScreen(
    //         chatId: chatId,
    //         chatName: groupName,
    //         isGroup: true,
    //       ),
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // البحث في الدردشات
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'private') {
                _createPrivateChat();
              } else if (value == 'group') {
                _createGroupChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'private',
                child: Text('دردشة جديدة'),
              ),
              const PopupMenuItem(
                value: 'group',
                child: Text('مجموعة جديدة'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<ChatProvider, UserProvider>(
        builder: (context, chatProvider, userProvider, child) {
          if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.chats.isEmpty) {
            return const Center(
              child: Text('لا توجد دردشات'),
            );
          }

          return ListView(
            children: [
              // قسم المجموعات
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'المجموعات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // قائمة المجموعات
              ...chatProvider.chats
                  .where((chat) => chat['type'] == 'group')
                  .map((chat) => _buildChatItem(
                        context,
                        chatId: chat['id'],
                        name: chat['name'] ?? 'مجموعة',
                        lastMessage: _getLastMessageText(chat['lastMessage']),
                        time: _formatTimestamp(chat['lastMessageTime']),
                        isGroup: true,
                      ))
                  .toList(),
              
              // قسم الدردشات الفردية
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'الدردشات الفردية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // قائمة الدردشات الفردية
              ...chatProvider.chats
                  .where((chat) => chat['type'] == 'private')
                  .map((chat) {
                    final currentUserId = userProvider.user?.uid;
                    final participants = List<String>.from(chat['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => participants.first,
                    );
                    
                    final otherUserInfo = chatProvider.usersInfo[otherUserId];
                    final name = otherUserInfo?['name'] ?? 'مستخدم';
                    final isOnline = otherUserInfo?['isOnline'] ?? false;
                    
                    return _buildChatItem(
                      context,
                      chatId: chat['id'],
                      name: name,
                      lastMessage: _getLastMessageText(chat['lastMessage']),
                      time: _formatTimestamp(chat['lastMessageTime']),
                      isOnline: isOnline,
                      isRead: _isLastMessageRead(chat['lastMessage'], currentUserId),
                    );
                  })
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  // بناء عنصر دردشة
  Widget _buildChatItem(
    BuildContext context, {
    required String chatId,
    required String name,
    required String lastMessage,
    required String time,
    bool isGroup = false,
    bool isOnline = false,
    bool isRead = true,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: isGroup ? Colors.green : Colors.blue,
            child: Icon(
              isGroup ? Icons.group : Icons.person,
              color: Colors.white,
            ),
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
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isRead ? Colors.grey : Colors.black,
                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (!isRead)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              chatName: name,
              isGroup: isGroup,
            ),
          ),
        );
      },
    );
  }

  // الحصول على نص آخر رسالة
  String _getLastMessageText(Map<String, dynamic>? lastMessage) {
    if (lastMessage == null) {
      return 'لا توجد رسائل';
    }

    final type = lastMessage['type'];
    if (type == 'text') {
      return lastMessage['text'] ?? '';
    } else if (type == 'image') {
      return 'صورة';
    } else if (type == 'voice') {
      return 'رسالة صوتية';
    } else {
      return 'رسالة';
    }
  }

  // التحقق مما إذا كانت آخر رسالة مقروءة
  bool _isLastMessageRead(Map<String, dynamic>? lastMessage, String? currentUserId) {
    if (lastMessage == null || currentUserId == null) {
      return true;
    }

    final senderId = lastMessage['senderId'];
    if (senderId == currentUserId) {
      return true;
    }

    final readBy = lastMessage['readBy'] as List<dynamic>?;
    return readBy != null && readBy.contains(currentUserId);
  }

  // تنسيق الوقت
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return '';
    }
    
    try {
      final DateTime dateTime = timestamp is DateTime
          ? timestamp
          : DateTime.fromMillisecondsSinceEpoch(
              timestamp.seconds * 1000 + (timestamp.nanoseconds ~/ 1000000),
            );
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'أمس';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} أيام';
      } else {
        return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
      }
    } catch (e) {
      return '';
    }
  }
}
