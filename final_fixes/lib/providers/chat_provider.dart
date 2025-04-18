import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/chat_service.dart';
import '../providers/user_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _chats = [];
  Map<String, List<Map<String, dynamic>>> _messages = {};
  String? _currentChatId;
  Map<String, Map<String, dynamic>> _usersInfo = {};

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get chats => _chats;
  Map<String, List<Map<String, dynamic>>> get messages => _messages;
  String? get currentChatId => _currentChatId;
  Map<String, Map<String, dynamic>> get usersInfo => _usersInfo;
  String? get currentUserId => _auth.currentUser?.uid;

  // تحميل قائمة الدردشات
  void loadChats() {
    try {
      _isLoading = true;
      notifyListeners();

      _chatService.getChats().listen((snapshot) async {
        _chats = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final chatId = doc.id;
          
          // تحويل البيانات إلى تنسيق مناسب
          final chatInfo = {
            'id': chatId,
            'type': data['type'],
            'participants': List<String>.from(data['participants'] ?? []),
            'lastMessage': data['lastMessage'],
            'lastMessageTime': data['lastMessageTimestamp'],
          };
          
          // إضافة اسم المجموعة إذا كانت دردشة جماعية
          if (data['type'] == 'group') {
            chatInfo['name'] = data['name'];
            chatInfo['admin'] = data['admin'];
          } else {
            // للدردشات الفردية، احصل على معلومات المستخدم الآخر
            final participants = List<String>.from(data['participants'] ?? []);
            if (currentUserId != null && participants.isNotEmpty) {
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => participants.first,
              );
              
              // تحميل معلومات المستخدم إذا لم تكن محملة بالفعل
              if (!_usersInfo.containsKey(otherUserId)) {
                final userInfo = await _chatService.getUserInfo(otherUserId);
                if (userInfo != null) {
                  _usersInfo[otherUserId] = userInfo;
                }
              }
            }
          }
          
          _chats.add(chatInfo);
        }
        
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading chats: $e');
    }
  }

  // إنشاء دردشة فردية جديدة
  Future<String?> createPrivateChat(String otherUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatId = await _chatService.createPrivateChat(otherUserId);
      
      // تحميل معلومات المستخدم الآخر
      if (!_usersInfo.containsKey(otherUserId)) {
        final userInfo = await _chatService.getUserInfo(otherUserId);
        if (userInfo != null) {
          _usersInfo[otherUserId] = userInfo;
        }
      }

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating private chat: $e');
      return null;
    }
  }

  // إنشاء مجموعة دردشة جديدة
  Future<String?> createGroupChat(String name, List<String> participants) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chatId = await _chatService.createGroupChat(name, participants);

      _isLoading = false;
      notifyListeners();
      return chatId;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating group chat: $e');
      return null;
    }
  }

  // إضافة مشاركين إلى مجموعة دردشة
  Future<bool> addParticipantsToGroup(String chatId, List<String> newParticipants) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.addParticipantsToGroup(chatId, newParticipants);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error adding participants to group: $e');
      return false;
    }
  }

  // تحديد الدردشة الحالية وتحميل رسائلها
  void setCurrentChat(String chatId) {
    _currentChatId = chatId;
    loadChatMessages(chatId);
    notifyListeners();
  }

  // تحميل رسائل دردشة معينة
  void loadChatMessages(String chatId) {
    try {
      _isLoading = true;
      notifyListeners();

      _chatService.getChatMessages(chatId: chatId).then((messagesList) {
        final List<Map<String, dynamic>> messagesData = [];
        
        for (var message in messagesList) {
          // تحويل البيانات إلى تنسيق مناسب
          final messageData = {
            'id': message.id,
            'type': message.type,
            'senderId': message.senderId,
            'timestamp': message.timestamp,
            'readBy': message.readBy,
            'deliveredTo': message.deliveredTo,
          };
          
          // إضافة البيانات الخاصة بنوع الرسالة
          if (message.type == 'text') {
            messageData['text'] = message.text;
          } else if (message.type == 'voice' || message.type == 'image') {
            messageData['url'] = message.url;
          }
          
          // تحميل معلومات المرسل إذا لم تكن محملة بالفعل
          final senderId = message.senderId;
          if (!_usersInfo.containsKey(senderId)) {
            _chatService.getUserInfo(senderId).then((userInfo) {
              if (userInfo != null) {
                _usersInfo[senderId] = userInfo;
                notifyListeners();
              }
            });
          }
          
          // تحديث حالة استلام الرسالة
          if (currentUserId != null && 
              senderId != currentUserId && 
              !message.deliveredTo.contains(currentUserId)) {
            _chatService.markMessageAsDelivered(chatId, message.id);
          }
          
          messagesData.add(messageData);
        }
        
        _messages[chatId] = messagesData;
        _isLoading = false;
        notifyListeners();
      }).catchError((e) {
        _isLoading = false;
        notifyListeners();
        print('Error loading chat messages: $e');
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading chat messages: $e');
    }
  }

  // إرسال رسالة نصية
  Future<bool> sendTextMessage(String text) async {
    try {
      if (_currentChatId == null) {
        throw Exception('لم يتم تحديد دردشة حالية');
      }
      
      _isLoading = true;
      notifyListeners();

      await _chatService.sendTextMessage(_currentChatId!, text);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error sending text message: $e');
      return false;
    }
  }

  // إرسال رسالة صوتية
  Future<bool> sendVoiceMessage(File audioFile) async {
    try {
      if (_currentChatId == null) {
        throw Exception('لم يتم تحديد دردشة حالية');
      }
      
      _isLoading = true;
      notifyListeners();

      await _chatService.sendVoiceMessage(_currentChatId!, audioFile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error sending voice message: $e');
      return false;
    }
  }

  // إرسال صورة
  Future<bool> sendImageMessage(File imageFile) async {
    try {
      if (_currentChatId == null) {
        throw Exception('لم يتم تحديد دردشة حالية');
      }
      
      _isLoading = true;
      notifyListeners();

      await _chatService.sendImageMessage(_currentChatId!, imageFile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error sending image message: $e');
      return false;
    }
  }

  // تحديث حالة قراءة الرسالة
  Future<void> markMessageAsRead(String messageId) async {
    try {
      if (_currentChatId == null) {
        throw Exception('لم يتم تحديد دردشة حالية');
      }
      
      await _chatService.markMessageAsRead(_currentChatId!, messageId);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // البحث في رسائل دردشة معينة
  Future<List<Map<String, dynamic>>> searchChatMessages(String query) async {
    try {
      if (_currentChatId == null) {
        throw Exception('لم يتم تحديد دردشة حالية');
      }
      
      _isLoading = true;
      notifyListeners();

      final results = await _chatService.searchChatMessages(
        chatId: _currentChatId!,
        searchText: query,
      );
      
      final List<Map<String, dynamic>> searchResults = [];
      for (var message in results) {
        searchResults.add({
          'id': message.id,
          'type': message.type,
          'text': message.text,
          'senderId': message.senderId,
          'timestamp': message.timestamp,
        });
      }

      _isLoading = false;
      notifyListeners();
      return searchResults;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error searching chat messages: $e');
      return [];
    }
  }

  // الحصول على معلومات المستخدم
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      if (_usersInfo.containsKey(userId)) {
        return _usersInfo[userId];
      }
      
      final userInfo = await _chatService.getUserInfo(userId);
      if (userInfo != null) {
        _usersInfo[userId] = userInfo;
        notifyListeners();
      }
      
      return userInfo;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}

// مفتاح عام للتنقل (يجب تعريفه في main.dart)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
