import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // التحقق من حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // تسجيل مستخدم جديد
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name, String phone, String role) async {
    try {
      // إنشاء المستخدم في Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // إضافة معلومات المستخدم إلى Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'profileImage': '',
        'lastActive': FieldValue.serverTimestamp(),
        'fcmToken': '',
        'createdAt': FieldValue.serverTimestamp(),
        'additionalInfo': {},
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // تحديث وقت آخر نشاط
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // التحقق من دعم المصادقة بالبصمة
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // المصادقة باستخدام البصمة
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'الرجاء المصادقة للدخول إلى التطبيق',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // تسجيل الدخول باستخدام البصمة
  Future<UserCredential?> signInWithBiometrics() async {
    try {
      // التحقق من وجود بيانات المستخدم المخزنة محلياً
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('user_email');
      final String? password = prefs.getString('user_password');

      if (email != null && password != null) {
        // المصادقة باستخدام البصمة
        final bool didAuthenticate = await authenticateWithBiometrics();
        if (didAuthenticate) {
          // تسجيل الدخول باستخدام البيانات المخزنة
          return await signInWithEmailAndPassword(email, password);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // حفظ بيانات المستخدم محلياً للمصادقة بالبصمة
  Future<void> saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
  }

  // حذف بيانات المستخدم المخزنة محلياً
  Future<void> clearUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_password');
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      // تحديث وقت آخر نشاط قبل تسجيل الخروج
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // الحصول على معلومات المستخدم من Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // تحديث معلومات المستخدم
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // تحديث صورة الملف الشخصي
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImage': imageUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  // التحقق مما إذا كان المستخدم مشرفاً
  Future<bool> isAdmin(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data != null && data['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}
