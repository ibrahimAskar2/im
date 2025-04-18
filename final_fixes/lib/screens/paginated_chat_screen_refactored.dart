import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import '../screens/call_screen.dart';

class PaginatedChatScreenRefactored extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String receiverId;

  const PaginatedChatScreenRefactored({
    Key? key,
    required this.chatId,
    required this.chatName,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<PaginatedChatScreenRefactored> createState() => _PaginatedChatScreenRefactoredState();
}

class _PaginatedChatScreenRefactoredState extends State<PaginatedChatScreenRefactored> {
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();
  final CallService _callService = CallService();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  // عدد الرسائل في كل تحميل
  final int _messagesPerLoad = 20;
  
  // معلومات المستخدم الحالي
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    
    // إضافة مستمع للتمرير لتحميل المزيد من الرسائل
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // تحميل معلومات المستخدم الحالي
  Future<void> _loadCurrentUser() async {
    try {
      final userId = _firestoreService.currentUserId;
      if (userId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      final userInfo = await _firestoreService.getUserInfo(userId);
      if (userInfo != null) {
        setState(() {
          _currentUser = User.fromMap(userId, userInfo);
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // مستمع التمرير لتحميل المزيد من الرسائل
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreMessages();
      }
    }
  }

  // تحميل الرسائل الأولية
  Future<void> _loadMessages() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final messagesData = await _firestoreService.getChatMessages(
        chatId: widget.chatId,
        limit: _messagesPerLoad,
      );
      
      final messages = messagesData.map((data) {
        return Message.fromMap(data['id'], data);
      }).toList();
      
      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMore = messages.length >= _messagesPerLoad;
        
        if (messages.isNotEmpty) {
          // الحصول على آخر وثيقة للتحميل المتدرج
          _lastDocument = messagesData.last['docSnapshot'] as DocumentSnapshot?;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الرسائل: $e')),
        );
      }
    }
  }

  // تحميل المزيد من الرسائل
  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final moreMessagesData = await _firestoreService.getChatMessages(
        chatId: widget.chatId,
        limit: _messagesPerLoad,
        lastDocument: _lastDocument,
      );
      
      final moreMessages = moreMessagesData.map((data) {
        return Message.fromMap(data['id'], data);
      }).toList();
      
      setState(() {
        _messages.addAll(moreMessages);
        _isLoading = false;
        _hasMore = moreMessages.length >= _messagesPerLoad;
        
        if (moreMessages.isNotEmpty) {
          // تحديث آخر وثيقة للتحميل المتدرج
          _lastDocument = moreMessagesData.last['docSnapshot'] as DocumentSnapshot?;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل المزيد من الرسائل: $e')),
        );
      }
    }
  }

  // إرسال رسالة جديدة
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    try {
      final currentUserId = _firestoreService.currentUserId;
      if (currentUserId == null || _currentUser == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      // إنشاء رسالة جديدة باستخدام نموذج الرسالة
      final message = Message.createText(
        chatId: widget.chatId,
        senderId: currentUserId,
        text: text,
      );
      
      // إضافة الرسالة إلى Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
      
      // إنشاء كلمات مفتاحية للبحث
      await _firestoreService.createMessageSearchKeywords(
        widget.chatId,
        message.id,
        text,
      );
      
      // تحديث آخر رسالة في الدردشة
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'lastMessage': text,
            'lastMessageTimestamp': Timestamp.now(),
            'lastMessageSenderId': currentUserId,
          });
      
      // إرسال إشعار للمستقبل - استخدام طريقة بديلة لإرسال الإشعار
      await _sendNotificationToReceiver(
        widget.receiverId,
        currentUserId,
        _currentUser!.name,
        text,
      );
      
      // تحديث الإحصائيات
      await _firestoreService.updateUserStatistics(
        currentUserId,
        {'totalMessages': FieldValue.increment(1)},
      );
      
      // تحميل الرسائل الجديدة
      _loadMessages();
    } catch (e) {
      // إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة: $e')),
        );
      }
    }
  }

  // طريقة بديلة لإرسال إشعار
  Future<void> _sendNotificationToReceiver(
    String receiverId,
    String senderId,
    String senderName,
    String messageText,
  ) async {
    try {
      // إنشاء إشعار في Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': receiverId,
        'senderId': senderId,
        'senderName': senderName,
        'type': 'message',
        'title': 'رسالة جديدة',
        'body': '$senderName: $messageText',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'targetId': widget.chatId,
        'data': {
          'chatId': widget.chatId,
          'messagePreview': messageText,
        },
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          // زر المكالمة الصوتية
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
          ),
          
          // زر البحث
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // قائمة الرسائل
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('لا توجد رسائل'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final message = _messages[index];
                      return _buildMessageItem(message);
                    },
                  ),
          ),
          
          // مؤشر التحميل
          if (_isLoading && _messages.isEmpty)
            const Center(child: CircularProgressIndicator()),
          
          // حقل إدخال الرسالة
          _buildMessageInput(),
        ],
      ),
    );
  }

  // بناء عنصر الرسالة
  Widget _buildMessageItem(Message message) {
    final currentUserId = _firestoreService.currentUserId;
    final isMe = message.senderId == currentUserId;
    
    final time = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                if (isMe)
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.grey[600],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بناء حقل إدخال الرسالة
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر إرفاق ملف
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // تنفيذ إرفاق ملف
            },
          ),
          
          // حقل إدخال الرسالة
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالة...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          // زر إرسال الرسالة
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // بدء مكالمة صوتية
  void _startVoiceCall() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تحميل معلومات المستخدم الحالي')),
      );
      return;
    }
    
    // بدء مكالمة جديدة باستخدام خدمة المكالمات
    _callService.startCall(
      callerId: _currentUser!.id,
      callerName: _currentUser!.name,
      callerImage: _currentUser!.imageUrl,
      receiverId: widget.receiverId,
      receiverName: widget.chatName,
    ).then((call) {
      if (call != null) {
        // فتح شاشة المكالمة
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              call: call,
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

  // عرض نافذة البحث
  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث في الرسائل'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'أدخل نص البحث...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final searchText = searchController.text.trim();
              if (searchText.isNotEmpty) {
                Navigator.pop(context);
                _searchMessages(searchText);
              }
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  // البحث في الرسائل
  Future<void> _searchMessages(String searchText) async {
    try {
      final searchResultsData = await _firestoreService.searchChatMessages(
        chatId: widget.chatId,
        searchText: searchText,
      );
      
      final searchResults = searchResultsData.map((data) {
        return Message.fromMap(data['id'], data);
      }).toList();
      
      if (searchResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على نتائج')),
          );
        }
        return;
      }
      
      // عرض نتائج البحث
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('نتائج البحث عن "$searchText"'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final message = searchResults[index];
                  final date = '${message.timestamp.day}/${message.timestamp.month}/${message.timestamp.year}';
                  final time = '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}';
                  
                  return ListTile(
                    title: Text(message.text),
                    subtitle: Text('$date $time'),
                    onTap: () {
                      Navigator.pop(context);
                      // التمرير إلى الرسالة
                      // في التطبيق الفعلي، سيتم تنفيذ التمرير إلى الرسالة
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء البحث: $e')),
        );
      }
    }
  }
}
