import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  String _searchQuery = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // تحديد الدردشة الحالية وتحميل رسائلها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).setCurrentChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // التمرير إلى أسفل القائمة عند إضافة رسائل جديدة
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // إرسال رسالة نصية
  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendTextMessage(widget.chatId, text);

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الرسالة')),
        );
      }
    }
  }

  // إرسال رسالة صوتية
  Future<void> _startVoiceRecording() async {
    // في التطبيق الفعلي، سيتم هنا بدء تسجيل الصوت
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopVoiceRecording() async {
    // في التطبيق الفعلي، سيتم هنا إيقاف تسجيل الصوت وإرسال الملف
    setState(() {
      _isRecording = false;
    });

    // مثال لإرسال ملف صوتي (سيتم استبداله بالتسجيل الفعلي)
    // final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // final success = await chatProvider.sendVoiceMessage(widget.chatId, audioFile);
  }

  // إرسال صورة
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final success = await chatProvider.sendImageMessage(
        widget.chatId,
        File(pickedFile.path),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الصورة')),
        );
      }
    }
  }

  // البحث في المحادثة
  Future<void> _searchInChat(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final results = await chatProvider.searchChatMessages(widget.chatId, query);

    setState(() {
      _searchResults = results;
    });
  }

  // تحديث حالة قراءة الرسالة
  void _markMessageAsRead(String messageId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markMessageAsRead(widget.chatId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchResults = [];
                }
              });
            },
          ),
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () {
                // في التطبيق الفعلي، سيتم هنا فتح شاشة إضافة مشاركين
              },
            ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'البحث في المحادثة',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _searchInChat(value);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // عرض نتائج البحث
          if (_isSearching && _searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final message = _searchResults[index];
                  return ListTile(
                    title: Text(message['text'] ?? ''),
                    subtitle: Text('${_formatTimestamp(message['timestamp'])}'),
                    onTap: () {
                      // في التطبيق الفعلي، سيتم هنا التمرير إلى الرسالة في المحادثة
                    },
                  );
                },
              ),
            )
          else if (_isSearching && _searchQuery.isNotEmpty)
            const Expanded(
              child: Center(
                child: Text('لا توجد نتائج'),
              ),
            )
          else
            // عرض المحادثة
            Expanded(
              child: Consumer2<ChatProvider, UserProvider>(
                builder: (context, chatProvider, userProvider, child) {
                  final messages = chatProvider.messages[widget.chatId] ?? [];
                  final currentUserId = userProvider.user?.uid;

                  if (chatProvider.isLoading && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == currentUserId;
                      
                      // تحديث حالة قراءة الرسالة
                      if (!isMe && currentUserId != null && 
                          !message['readBy'].contains(currentUserId)) {
                        _markMessageAsRead(message['id']);
                      }
                      
                      return _buildMessageItem(message, isMe, chatProvider);
                    },
                  );
                },
              ),
            ),
          
          // حقل إدخال الرسالة
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // زر إرسال الصورة
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _sendImage,
                ),
                
                // زر تسجيل الصوت
                IconButton(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _isRecording ? _stopVoiceRecording : _startVoiceRecording,
                  color: _isRecording ? Colors.red : null,
                ),
                
                // حقل إدخال النص
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
                
                // زر إرسال الرسالة
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء عنصر الرسالة
  Widget _buildMessageItem(Map<String, dynamic> message, bool isMe, ChatProvider chatProvider) {
    final userInfo = chatProvider.usersInfo[message['senderId']];
    final userName = userInfo?['name'] ?? 'مستخدم';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم المرسل (للمجموعات)
            if (widget.isGroup && !isMe)
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            
            // محتوى الرسالة
            _buildMessageContent(message),
            
            // وقت الرسالة وحالة القراءة
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(message['timestamp']),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['readBy'].length > 1
                        ? Icons.done_all
                        : Icons.done,
                    size: 12,
                    color: message['readBy'].length > 1
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // بناء محتوى الرسالة حسب نوعها
  Widget _buildMessageContent(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'text':
        return Text(message['text'] ?? '');
      case 'image':
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message['url'] ?? '',
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 'voice':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                // في التطبيق الفعلي، سيتم هنا تشغيل الرسالة الصوتية
              },
            ),
            const Text('رسالة صوتية'),
          ],
        );
      default:
        return const Text('نوع رسالة غير معروف');
    }
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
      
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
