import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/attendance_service.dart';
import '../providers/user_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _presentEmployees = [];
  int _absentCount = 0;
  Map<String, dynamic>? _featuredEmployee;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get presentEmployees => _presentEmployees;
  int get absentCount => _absentCount;
  Map<String, dynamic>? get featuredEmployee => _featuredEmployee;

  // تسجيل الدخول
  Future<bool> checkIn() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _attendanceService.checkIn();
      
      if (success) {
        await _refreshDashboardData();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error checking in: $e');
      return false;
    }
  }

  // تسجيل الخروج
  Future<bool> checkOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _attendanceService.checkOut();
      
      if (success) {
        await _refreshDashboardData();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error checking out: $e');
      return false;
    }
  }

  // تحديث بيانات لوحة المعلومات
  Future<void> _refreshDashboardData() async {
    try {
      _presentEmployees = await _attendanceService.getPresentEmployees();
      _absentCount = await _attendanceService.getAbsentCount();
      _featuredEmployee = await _attendanceService.getFeaturedEmployee();
      notifyListeners();
    } catch (e) {
      print('Error refreshing dashboard data: $e');
    }
  }

  // تحديث بيانات لوحة المعلومات (للاستخدام العام)
  Future<void> refreshDashboardData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _refreshDashboardData();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error refreshing dashboard data: $e');
    }
  }

  // الحصول على إحصائيات الدوام لموظف معين
  Future<Map<String, dynamic>> getAttendanceStats(String userId, String period) async {
    try {
      _isLoading = true;
      notifyListeners();

      final stats = await _attendanceService.getAttendanceStats(userId, period);

      _isLoading = false;
      notifyListeners();
      return stats;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error getting attendance stats: $e');
      return {
        'present': 0,
        'late': 0,
        'total': 0,
      };
    }
  }
}
