import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Task> _tasks = [];
  List<Task> _userTasks = [];
  bool _isLoading = false;
  String? _error;
  
  // الحصول على قائمة جميع المهام
  List<Task> get tasks => _tasks;
  
  // الحصول على قائمة مهام المستخدم الحالي
  List<Task> get userTasks => _userTasks;
  
  // حالة التحميل
  bool get isLoading => _isLoading;
  
  // رسالة الخطأ
  String? get error => _error;

  // تحميل جميع المهام (للمشرف)
  Future<void> loadAllTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('tasks').get();
      _tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
      
      // ترتيب المهام حسب الأولوية والتاريخ
      _tasks.sort((a, b) {
        // ترتيب تنازلي حسب الأولوية
        int priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        
        // ترتيب تصاعدي حسب تاريخ الاستحقاق
        return a.dueDate.compareTo(b.dueDate);
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء تحميل المهام: $e';
      notifyListeners();
    }
  }

  // تحميل مهام المستخدم
  Future<void> loadUserTasks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .get();
      
      _userTasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.id, doc.data()))
          .toList();
      
      // ترتيب المهام حسب الأولوية والتاريخ
      _userTasks.sort((a, b) {
        // ترتيب تنازلي حسب الأولوية
        int priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        
        // ترتيب تصاعدي حسب تاريخ الاستحقاق
        return a.dueDate.compareTo(b.dueDate);
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء تحميل مهام المستخدم: $e';
      notifyListeners();
    }
  }

  // إضافة مهمة جديدة
  Future<Task?> addTask({
    required String title,
    required String description,
    required String assignerId,
    required String assignerName,
    required String assigneeId,
    required String assigneeName,
    required DateTime dueDate,
    required int priority,
    required bool isUrgent,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newTask = Task.create(
        title: title,
        description: description,
        assignerId: assignerId,
        assignerName: assignerName,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        dueDate: dueDate,
        priority: priority,
      );
      
      // إضافة معلومات إضافية في metadata
      final metadata = {
        'isUrgent': isUrgent,
        'completionDetails': '',
      };
      
      final taskWithMetadata = Task(
        id: newTask.id,
        title: newTask.title,
        description: newTask.description,
        assignerId: newTask.assignerId,
        assignerName: newTask.assignerName,
        assigneeId: newTask.assigneeId,
        assigneeName: newTask.assigneeName,
        createdAt: newTask.createdAt,
        dueDate: newTask.dueDate,
        status: newTask.status,
        priority: newTask.priority,
        comments: newTask.comments,
        attachments: newTask.attachments,
        metadata: metadata,
      );
      
      await _firestore
          .collection('tasks')
          .doc(newTask.id)
          .set(taskWithMetadata.toMap());
      
      if (assignerId == assigneeId) {
        _userTasks.add(taskWithMetadata);
        _tasks.add(taskWithMetadata);
      } else if (_tasks.isNotEmpty) {
        _tasks.add(taskWithMetadata);
      }
      
      // إعادة ترتيب المهام
      if (_tasks.isNotEmpty) {
        _tasks.sort((a, b) {
          int priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) return priorityCompare;
          return a.dueDate.compareTo(b.dueDate);
        });
      }
      
      if (_userTasks.isNotEmpty) {
        _userTasks.sort((a, b) {
          int priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) return priorityCompare;
          return a.dueDate.compareTo(b.dueDate);
        });
      }
      
      _isLoading = false;
      notifyListeners();
      
      return taskWithMetadata;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء إضافة المهمة: $e';
      notifyListeners();
      return null;
    }
  }

  // تحديث حالة المهمة
  Future<bool> updateTaskStatus({
    required String taskId,
    required String newStatus,
    String? completionDetails,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // البحث عن المهمة في القوائم المحلية
      int taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      int userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
      
      if (taskIndex == -1 && userTaskIndex == -1) {
        _isLoading = false;
        _error = 'المهمة غير موجودة';
        notifyListeners();
        return false;
      }
      
      // الحصول على المهمة من Firestore
      final docSnapshot = await _firestore.collection('tasks').doc(taskId).get();
      if (!docSnapshot.exists) {
        _isLoading = false;
        _error = 'المهمة غير موجودة في قاعدة البيانات';
        notifyListeners();
        return false;
      }
      
      final task = Task.fromMap(taskId, docSnapshot.data()!);
      final updatedTask = task.updateStatus(newStatus);
      
      // تحديث تفاصيل الإنجاز إذا كانت متوفرة
      Map<String, dynamic> metadata = updatedTask.metadata ?? {};
      if (completionDetails != null && newStatus == 'completed') {
        metadata['completionDetails'] = completionDetails;
      }
      
      // تحديث المهمة في Firestore
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
        'metadata': metadata,
      });
      
      // تحديث المهمة في القوائم المحلية
      final finalUpdatedTask = Task(
        id: updatedTask.id,
        title: updatedTask.title,
        description: updatedTask.description,
        assignerId: updatedTask.assignerId,
        assignerName: updatedTask.assignerName,
        assigneeId: updatedTask.assigneeId,
        assigneeName: updatedTask.assigneeName,
        createdAt: updatedTask.createdAt,
        dueDate: updatedTask.dueDate,
        status: newStatus,
        priority: updatedTask.priority,
        comments: updatedTask.comments,
        attachments: updatedTask.attachments,
        metadata: metadata,
      );
      
      if (taskIndex != -1) {
        _tasks[taskIndex] = finalUpdatedTask;
      }
      
      if (userTaskIndex != -1) {
        _userTasks[userTaskIndex] = finalUpdatedTask;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء تحديث حالة المهمة: $e';
      notifyListeners();
      return false;
    }
  }

  // إضافة تعليق على المهمة
  Future<bool> addTaskComment({
    required String taskId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // البحث عن المهمة في القوائم المحلية
      int taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      int userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
      
      if (taskIndex == -1 && userTaskIndex == -1) {
        _isLoading = false;
        _error = 'المهمة غير موجودة';
        notifyListeners();
        return false;
      }
      
      // الحصول على المهمة من Firestore
      final docSnapshot = await _firestore.collection('tasks').doc(taskId).get();
      if (!docSnapshot.exists) {
        _isLoading = false;
        _error = 'المهمة غير موجودة في قاعدة البيانات';
        notifyListeners();
        return false;
      }
      
      final task = Task.fromMap(taskId, docSnapshot.data()!);
      final updatedTask = task.addComment(
        userId: userId,
        userName: userName,
        text: text,
      );
      
      // تحديث المهمة في Firestore
      await _firestore.collection('tasks').doc(taskId).update({
        'comments': updatedTask.comments,
      });
      
      // تحديث المهمة في القوائم المحلية
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
      }
      
      if (userTaskIndex != -1) {
        _userTasks[userTaskIndex] = updatedTask;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء إضافة تعليق على المهمة: $e';
      notifyListeners();
      return false;
    }
  }

  // حذف مهمة
  Future<bool> deleteTask(String taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      
      _tasks.removeWhere((task) => task.id == taskId);
      _userTasks.removeWhere((task) => task.id == taskId);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء حذف المهمة: $e';
      notifyListeners();
      return false;
    }
  }

  // الحصول على مهام المستخدم حسب الحالة
  List<Task> getUserTasksByStatus(String userId, String status) {
    return _userTasks.where((task) => 
      task.assigneeId == userId && task.status == status
    ).toList();
  }

  // الحصول على عدد مهام المستخدم حسب الحالة
  int getUserTasksCountByStatus(String userId, String status) {
    return _userTasks.where((task) => 
      task.assigneeId == userId && task.status == status
    ).length;
  }

  // الحصول على المهام المستعجلة للمستخدم
  List<Task> getUrgentTasksForUser(String userId) {
    return _userTasks.where((task) {
      final isUrgent = task.metadata?['isUrgent'] == true;
      return task.assigneeId == userId && isUrgent && task.status != 'completed' && task.status != 'canceled';
    }).toList();
  }

  // إرسال إشعار بإنجاز المهمة
  Future<bool> sendTaskCompletionNotification({
    required String taskId,
    required String completionDetails,
  }) async {
    try {
      // تحديث حالة المهمة إلى "مكتملة" وإضافة تفاصيل الإنجاز
      final success = await updateTaskStatus(
        taskId: taskId,
        newStatus: 'completed',
        completionDetails: completionDetails,
      );
      
      if (!success) {
        return false;
      }
      
      // البحث عن المهمة
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
      
      Task? task;
      if (taskIndex != -1) {
        task = _tasks[taskIndex];
      } else if (userTaskIndex != -1) {
        task = _userTasks[userTaskIndex];
      } else {
        final docSnapshot = await _firestore.collection('tasks').doc(taskId).get();
        if (docSnapshot.exists) {
          task = Task.fromMap(taskId, docSnapshot.data()!);
        }
      }
      
      if (task == null) {
        _error = 'المهمة غير موجودة';
        notifyListeners();
        return false;
      }
      
      // إنشاء إشعار في Firestore
      await _firestore.collection('notifications').add({
        'type': 'task_completed',
        'taskId': taskId,
        'taskTitle': task.title,
        'assigneeId': task.assigneeId,
        'assigneeName': task.assigneeName,
        'assignerId': task.assignerId,
        'completionDetails': completionDetails,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
      
      return true;
    } catch (e) {
      _error = 'حدث خطأ أثناء إرسال إشعار إنجاز المهمة: $e';
      notifyListeners();
      return false;
    }
  }
}
