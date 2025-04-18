import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reference_model.dart';

class ReferenceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Reference> _references = [];
  List<String> _categories = [];
  List<String> _departments = [];
  bool _isLoading = false;
  String? _error;

  // الحصول على قائمة المراجع
  List<Reference> get references => _references;
  
  // الحصول على قائمة التصنيفات
  List<String> get categories => _categories;
  
  // الحصول على قائمة الأقسام
  List<String> get departments => _departments;
  
  // حالة التحميل
  bool get isLoading => _isLoading;
  
  // رسالة الخطأ
  String? get error => _error;

  // تحميل جميع المراجع
  Future<void> loadReferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('references').get();
      _references = snapshot.docs
          .map((doc) => Reference.fromMap(doc.id, doc.data()))
          .toList();
      
      // استخراج التصنيفات والأقسام الفريدة
      _updateCategoriesAndDepartments();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء تحميل المراجع: $e';
      notifyListeners();
    }
  }

  // تحديث قوائم التصنيفات والأقسام
  void _updateCategoriesAndDepartments() {
    final Set<String> categoriesSet = {};
    final Set<String> departmentsSet = {};
    
    for (var reference in _references) {
      if (reference.category.isNotEmpty) {
        categoriesSet.add(reference.category);
      }
      if (reference.department.isNotEmpty) {
        departmentsSet.add(reference.department);
      }
    }
    
    _categories = categoriesSet.toList()..sort();
    _departments = departmentsSet.toList()..sort();
  }

  // إضافة مرجع جديد
  Future<Reference?> addReference({
    required String title,
    required String content,
    required String category,
    required String department,
    required String creatorId,
    required String creatorName,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newReference = Reference.create(
        title: title,
        content: content,
        category: category,
        department: department,
        creatorId: creatorId,
        creatorName: creatorName,
        tags: tags,
      );
      
      await _firestore
          .collection('references')
          .doc(newReference.id)
          .set(newReference.toMap());
      
      _references.add(newReference);
      _updateCategoriesAndDepartments();
      
      _isLoading = false;
      notifyListeners();
      
      return newReference;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء إضافة المرجع: $e';
      notifyListeners();
      return null;
    }
  }

  // تحديث مرجع موجود
  Future<bool> updateReference({
    required String id,
    required String title,
    required String content,
    required String category,
    required String department,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final index = _references.indexWhere((ref) => ref.id == id);
      if (index == -1) {
        _isLoading = false;
        _error = 'المرجع غير موجود';
        notifyListeners();
        return false;
      }
      
      final updatedReference = _references[index].updateContent(
        title: title,
        content: content,
        category: category,
        department: department,
        tags: tags,
      );
      
      await _firestore
          .collection('references')
          .doc(id)
          .update(updatedReference.toMap());
      
      _references[index] = updatedReference;
      _updateCategoriesAndDepartments();
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء تحديث المرجع: $e';
      notifyListeners();
      return false;
    }
  }

  // حذف مرجع
  Future<bool> deleteReference(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _firestore.collection('references').doc(id).delete();
      
      _references.removeWhere((ref) => ref.id == id);
      _updateCategoriesAndDepartments();
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'حدث خطأ أثناء حذف المرجع: $e';
      notifyListeners();
      return false;
    }
  }

  // البحث عن المراجع
  List<Reference> searchReferences({
    String? query,
    String? category,
    String? department,
  }) {
    if (query == null && category == null && department == null) {
      return _references;
    }
    
    return _references.where((ref) {
      bool matchesQuery = true;
      bool matchesCategory = true;
      bool matchesDepartment = true;
      
      if (query != null && query.isNotEmpty) {
        matchesQuery = ref.title.contains(query) || 
                      ref.content.contains(query) || 
                      ref.tags.any((tag) => tag.contains(query));
      }
      
      if (category != null && category.isNotEmpty) {
        matchesCategory = ref.category == category;
      }
      
      if (department != null && department.isNotEmpty) {
        matchesDepartment = ref.department == department;
      }
      
      return matchesQuery && matchesCategory && matchesDepartment;
    }).toList();
  }
}
