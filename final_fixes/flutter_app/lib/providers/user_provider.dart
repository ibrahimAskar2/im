import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isAdmin = false;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // الاستماع لتغييرات حالة المصادقة
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userData = null;
        _isAdmin = false;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  // تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _userData = await _authService.getUserData(uid);
      _isAdmin = await _authService.isAdmin(uid);
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // تسجيل مستخدم جديد
  Future<bool> register(String email, String password, String name, String phone, String role) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
        phone,
        role,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error registering user: $e');
      return false;
    }
  }

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<bool> signIn(String email, String password, bool rememberMe) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);

      // حفظ بيانات المستخدم محلياً إذا تم اختيار "تذكرني"
      if (rememberMe) {
        await _authService.saveUserCredentials(email, password);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error signing in: $e');
      return false;
    }
  }

  // تسجيل الدخول باستخدام البصمة
  Future<bool> signInWithBiometrics() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithBiometrics();
      final success = userCredential != null;

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error signing in with biometrics: $e');
      return false;
    }
  }

  // التحقق من دعم المصادقة بالبصمة
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error signing out: $e');
    }
  }

  // إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error resetting password: $e');
      return false;
    }
  }

  // تحديث بيانات المستخدم
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null) {
        await _authService.updateUserData(_user!.uid, data);
        await _loadUserData(_user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error updating user data: $e');
      return false;
    }
  }

  // تحديث صورة الملف الشخصي
  Future<bool> updateProfileImage(String imageUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null) {
        await _authService.updateProfileImage(_user!.uid, imageUrl);
        await _loadUserData(_user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error updating profile image: $e');
      return false;
    }
  }
}
