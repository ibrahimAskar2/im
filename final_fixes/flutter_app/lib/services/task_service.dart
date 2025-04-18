import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class TaskService {
  // Singleton pattern
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على قائمة المهام المخصصة للمستخدم مع التحميل المتدرج
  Future<List<Task>> getUserTasks({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .orderBy('dueDate', descending: false);
      
      // تصفية حسب الحالة إذا تم تحديدها
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      // إضافة التحميل المتدرج
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // تحديد عدد النتائج
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      
      // تحويل البيانات إلى قائمة من كائنات Task
      final tasks = querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      return tasks;
    } catch (e) {
      print('Error getting user tasks: $e');
      rethrow;
    }
  }

  // الحصول على تفاصيل مهمة محددة
  Future<Task?> getTaskDetails(String taskId) async {
    try {
      final docSnapshot = await _firestore
          .collection('tasks')
          .doc(taskId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return Task.fromMap(docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting task details: $e');
      rethrow;
    }
  }

  // إنشاء مهمة جديدة
  Future<Task> createTask({
    required String title,
    required String description,
    required String assignedBy,
    required String assignedByName,
    required String assignedTo,
    required String assignedToName,
    required DateTime dueDate,
    int priority = 2,
  }) async {
    try {
      // إنشاء كائن Task جديد
      final task = Task.create(
        title: title,
        description: description,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        dueDate: dueDate,
        priority: priority,
      );
      
      // حفظ المهمة في Firestore
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
      
      return task;
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // تحديث حالة مهمة
  Future<Task> updateTaskStatus(String taskId, String newStatus) async {
    try {
      // الحصول على المهمة الحالية
      final task = await getTaskDetails(taskId);
      if (task == null) {
        throw Exception('المهمة غير موجودة');
      }
      
      // تحديث حالة المهمة
      final updatedTask = task.updateStatus(newStatus);
      
      // حفظ التغييرات في Firestore
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({
            'status': newStatus,
            'completedAt': updatedTask.completedAt != null ? Timestamp.fromDate(updatedTask.completedAt!) : null,
          });
      
      return updatedTask;
    } catch (e) {
      print('Error updating task status: $e');
      rethrow;
    }
  }

  // إضافة تعليق إلى مهمة
  Future<Task> addCommentToTask({
    required String taskId,
    required String userId,
    required String userName,
    String userImage = '',
    required String text,
  }) async {
    try {
      // إنشاء كائن Comment جديد
      final comment = Comment.create(
        userId: userId,
        userName: userName,
        userImage: userImage,
        text: text,
      );
      
      // الحصول على المهمة الحالية
      final task = await getTaskDetails(taskId);
      if (task == null) {
        throw Exception('المهمة غير موجودة');
      }
      
      // إضافة التعليق إلى المهمة
      final updatedTask = task.addComment(comment);
      
      // حفظ التغييرات في Firestore
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({
            'comments': updatedTask.comments.map((comment) => comment.toMap()).toList(),
          });
      
      return updatedTask;
    } catch (e) {
      print('Error adding comment to task: $e');
      rethrow;
    }
  }

  // إضافة مرفق إلى مهمة
  Future<Task> addAttachmentToTask(String taskId, String attachmentUrl) async {
    try {
      // الحصول على المهمة الحالية
      final task = await getTaskDetails(taskId);
      if (task == null) {
        throw Exception('المهمة غير موجودة');
      }
      
      // إضافة المرفق إلى المهمة
      final updatedTask = task.addAttachment(attachmentUrl);
      
      // حفظ التغييرات في Firestore
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({
            'attachments': updatedTask.attachments,
          });
      
      return updatedTask;
    } catch (e) {
      print('Error adding attachment to task: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات المهام للمستخدم
  Future<Map<String, dynamic>> getTaskStatistics(String userId) async {
    try {
      // الحصول على جميع مهام المستخدم
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();
      
      // تحويل البيانات إلى قائمة من كائنات Task
      final tasks = querySnapshot.docs.map((doc) {
        return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      
      // حساب الإحصائيات
      int totalTasks = tasks.length;
      int pendingTasks = tasks.where((task) => task.status == 'pending').length;
      int inProgressTasks = tasks.where((task) => task.status == 'in_progress').length;
      int completedTasks = tasks.where((task) => task.status == 'completed').length;
      int cancelledTasks = tasks.where((task) => task.status == 'cancelled').length;
      int overdueTasks = tasks.where((task) => task.isOverdue()).length;
      
      // حساب معدل الإنجاز
      double completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;
      
      // حساب معدل التأخير
      double overdueRate = totalTasks > 0 ? (overdueTasks / totalTasks) * 100 : 0;
      
      return {
        'totalTasks': totalTasks,
        'pendingTasks': pendingTasks,
        'inProgressTasks': inProgressTasks,
        'completedTasks': completedTasks,
        'cancelledTasks': cancelledTasks,
        'overdueTasks': overdueTasks,
        'completionRate': completionRate,
        'overdueRate': overdueRate,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      rethrow;
    }
  }
}
