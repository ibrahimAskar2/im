import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class TaskServiceRefactored {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على قائمة المهام للمستخدم الحالي
  Future<List<Task>> getUserTasks({
    required String userId,
    String status = 'all',
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('tasks').where('assigneeId', isEqualTo: userId);
      
      // تصفية حسب الحالة إذا كانت محددة
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      
      // ترتيب حسب تاريخ الاستحقاق
      query = query.orderBy('dueDate', descending: false);
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      // استخدام آخر وثيقة للتحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting user tasks: $e');
      return [];
    }
  }

  // إنشاء مهمة جديدة
  Future<Task?> createTask({
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required DateTime dueDate,
    int priority = 2,
  }) async {
    try {
      final currentUserId = _firestoreService.currentUserId;
      if (currentUserId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      // الحصول على معلومات المستخدم الحالي
      final userInfo = await _firestoreService.getUserInfo(currentUserId);
      if (userInfo == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم الحالي');
      }
      
      final currentUser = User.fromMap(currentUserId, userInfo);
      
      // إنشاء مهمة جديدة
      final task = Task.create(
        title: title,
        description: description,
        assignerId: currentUserId,
        assignerName: currentUser.name,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        dueDate: dueDate,
        priority: priority,
      );
      
      // إضافة المهمة إلى Firestore
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      
      // إنشاء إشعار للمستلم
      await _firestoreService.createTaskNotification(
        userId: assigneeId,
        senderId: currentUserId,
        senderName: currentUser.name,
        taskTitle: title,
        taskId: task.id,
        taskType: 'new',
      );
      
      // تحديث الإحصائيات
      await _firestoreService.updateUserStatistics(
        currentUserId,
        {'totalTasksCreated': FieldValue.increment(1)},
      );
      
      await _firestoreService.updateUserStatistics(
        assigneeId,
        {'totalTasksAssigned': FieldValue.increment(1)},
      );
      
      return task;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // تحديث حالة المهمة
  Future<bool> updateTaskStatus({
    required String taskId,
    required String newStatus,
  }) async {
    try {
      final currentUserId = _firestoreService.currentUserId;
      if (currentUserId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      // الحصول على المهمة
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('لم يتم العثور على المهمة');
      }
      
      final task = Task.fromMap(taskId, taskDoc.data() as Map<String, dynamic>);
      
      // التحقق من صلاحية المستخدم لتحديث المهمة
      if (task.assigneeId != currentUserId && task.assignerId != currentUserId) {
        throw Exception('ليس لديك صلاحية لتحديث هذه المهمة');
      }
      
      // تحديث حالة المهمة
      final updatedTask = task.updateStatus(newStatus);
      
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
      });
      
      // إنشاء إشعار للمستلم أو المنشئ
      final recipientId = currentUserId == task.assigneeId ? task.assignerId : task.assigneeId;
      
      // الحصول على معلومات المستخدم الحالي
      final userInfo = await _firestoreService.getUserInfo(currentUserId);
      if (userInfo == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم الحالي');
      }
      
      final currentUser = User.fromMap(currentUserId, userInfo);
      
      await _firestoreService.createTaskNotification(
        userId: recipientId,
        senderId: currentUserId,
        senderName: currentUser.name,
        taskTitle: task.title,
        taskId: taskId,
        taskType: newStatus == 'completed' ? 'complete' : 'update',
      );
      
      // تحديث الإحصائيات إذا تم إكمال المهمة
      if (newStatus == 'completed') {
        await _firestoreService.updateUserStatistics(
          task.assigneeId,
          {'completedTasks': FieldValue.increment(1)},
        );
      }
      
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  // إضافة تعليق إلى المهمة
  Future<bool> addTaskComment({
    required String taskId,
    required String text,
  }) async {
    try {
      final currentUserId = _firestoreService.currentUserId;
      if (currentUserId == null) {
        throw Exception('لم يتم تعيين معرف المستخدم الحالي');
      }
      
      // الحصول على معلومات المستخدم الحالي
      final userInfo = await _firestoreService.getUserInfo(currentUserId);
      if (userInfo == null) {
        throw Exception('لم يتم العثور على معلومات المستخدم الحالي');
      }
      
      final currentUser = User.fromMap(currentUserId, userInfo);
      
      // الحصول على المهمة
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('لم يتم العثور على المهمة');
      }
      
      final task = Task.fromMap(taskId, taskDoc.data() as Map<String, dynamic>);
      
      // إضافة التعليق
      final updatedTask = task.addComment(
        userId: currentUserId,
        userName: currentUser.name,
        text: text,
      );
      
      await _firestore.collection('tasks').doc(taskId).update({
        'comments': updatedTask.comments,
      });
      
      // إنشاء إشعار للمستلم أو المنشئ
      final recipientId = currentUserId == task.assigneeId ? task.assignerId : task.assigneeId;
      
      await _firestoreService.createTaskNotification(
        userId: recipientId,
        senderId: currentUserId,
        senderName: currentUser.name,
        taskTitle: task.title,
        taskId: taskId,
        taskType: 'comment',
      );
      
      return true;
    } catch (e) {
      print('Error adding task comment: $e');
      return false;
    }
  }

  // الحصول على تفاصيل المهمة
  Future<Task?> getTaskDetails(String taskId) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        return null;
      }
      
      return Task.fromMap(taskId, taskDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting task details: $e');
      return null;
    }
  }

  // الحصول على المهام المتأخرة للمستخدم
  Future<List<Task>> getOverdueTasks(String userId) async {
    try {
      final now = DateTime.now();
      
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();
      
      return querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      return [];
    }
  }

  // الحصول على إحصائيات المهام للمستخدم
  Future<Map<String, dynamic>> getTaskStatistics(String userId) async {
    try {
      // المهام المعينة
      final assignedQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .get();
      
      // المهام المكتملة
      final completedQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      // المهام المتأخرة
      final now = DateTime.now();
      final overdueQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'in_progress'])
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();
      
      // المهام حسب الأولوية
      final lowPriorityQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('priority', isEqualTo: 1)
          .get();
      
      final mediumPriorityQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('priority', isEqualTo: 2)
          .get();
      
      final highPriorityQuery = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .where('priority', isEqualTo: 3)
          .get();
      
      return {
        'totalAssigned': assignedQuery.docs.length,
        'completed': completedQuery.docs.length,
        'overdue': overdueQuery.docs.length,
        'lowPriority': lowPriorityQuery.docs.length,
        'mediumPriority': mediumPriorityQuery.docs.length,
        'highPriority': highPriorityQuery.docs.length,
        'completionRate': assignedQuery.docs.isEmpty
            ? 0
            : (completedQuery.docs.length / assignedQuery.docs.length) * 100,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      return {
        'totalAssigned': 0,
        'completed': 0,
        'overdue': 0,
        'lowPriority': 0,
        'mediumPriority': 0,
        'highPriority': 0,
        'completionRate': 0,
      };
    }
  }
}
