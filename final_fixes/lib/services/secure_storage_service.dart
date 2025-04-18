import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  // Singleton pattern
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // مفاتيح التخزين
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _migrationCompletedKey = 'secure_storage_migration_completed';

  // مثيل التخزين الآمن
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // تهيئة الخدمة
  Future<void> initialize() async {
    // التحقق مما إذا كانت الترحيل قد تم بالفعل
    final prefs = await SharedPreferences.getInstance();
    final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;
    
    if (!migrationCompleted) {
      // ترحيل البيانات من SharedPreferences إلى التخزين الآمن
      await _migrateFromSharedPreferences();
      
      // تعليم الترحيل كمكتمل
      await prefs.setBool(_migrationCompletedKey, true);
    }
  }

  // ترحيل البيانات من SharedPreferences إلى التخزين الآمن
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ترحيل معرف المستخدم
      final userId = prefs.getString(_userIdKey);
      if (userId != null && userId.isNotEmpty) {
        await _secureStorage.write(key: _userIdKey, value: userId);
        await prefs.remove(_userIdKey);
      }
      
      // ترحيل البريد الإلكتروني
      final email = prefs.getString(_emailKey);
      if (email != null && email.isNotEmpty) {
        await _secureStorage.write(key: _emailKey, value: email);
        await prefs.remove(_emailKey);
      }
      
      // ترحيل كلمة المرور
      final password = prefs.getString(_passwordKey);
      if (password != null && password.isNotEmpty) {
        await _secureStorage.write(key: _passwordKey, value: password);
        await prefs.remove(_passwordKey);
      }
      
      // ترحيل رمز المصادقة
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: token);
        await prefs.remove(_tokenKey);
      }
      
      // ترحيل رمز التحديث
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        await prefs.remove(_refreshTokenKey);
      }
      
      print('تم ترحيل البيانات من SharedPreferences إلى التخزين الآمن بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء ترحيل البيانات: $e');
    }
  }

  // حفظ معرف المستخدم
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }

  // الحصول على معرف المستخدم
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  // حفظ بيانات المصادقة
  Future<void> saveAuthData({
    required String userId,
    required String email,
    required String password,
    required String token,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // الحصول على البريد الإلكتروني
  Future<String?> getEmail() async {
    return await _secureStorage.read(key: _emailKey);
  }

  // الحصول على كلمة المرور
  Future<String?> getPassword() async {
    return await _secureStorage.read(key: _passwordKey);
  }

  // الحصول على رمز المصادقة
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // الحصول على رمز التحديث
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  // تحديث رمز المصادقة
  Future<void> updateToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // تحديث رمز التحديث
  Future<void> updateRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // حذف بيانات المصادقة
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  // حفظ قيمة آمنة
  Future<void> saveSecureValue(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // الحصول على قيمة آمنة
  Future<String?> getSecureValue(String key) async {
    return await _secureStorage.read(key: key);
  }

  // حذف قيمة آمنة
  Future<void> deleteSecureValue(String key) async {
    await _secureStorage.delete(key: key);
  }

  // التحقق مما إذا كان المفتاح موجوداً
  Future<bool> containsKey(String key) async {
    return (await _secureStorage.read(key: key)) != null;
  }

  // حذف جميع القيم
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}
