import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _presentEmployees = [];
  int _absentCount = 0;
  Map<String, dynamic>? _featuredEmployee;
  Map<String, dynamic> _allEmployeesStats = {};
  List<Map<String, dynamic>> _attendanceReport = [];
  Map<String, dynamic> _employeeAttendanceCount = {};
  String _currentPeriod = 'day'; // يوم، أسبوع، شهر، سنة

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get presentEmployees => _presentEmployees;
  int get absentCount => _absentCount;
  Map<String, dynamic>? get featuredEmployee => _featuredEmployee;
  Map<String, dynamic> get allEmployeesStats => _allEmployeesStats;
  List<Map<String, dynamic>> get attendanceReport => _attendanceReport;
  Map<String, dynamic> get employeeAttendanceCount => _employeeAttendanceCount;
  String get currentPeriod => _currentPeriod;

  // تحميل البيانات الأساسية للوحة المعلومات
  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // تحميل الموظفين المتواجدين حالياً
      _presentEmployees = await _statisticsService.getPresentEmployees();

      // تحميل عدد الغياب
      _absentCount = await _statisticsService.getAbsentCount();

      // تحميل الموظف المميز
      _featuredEmployee = await _statisticsService.getFeaturedEmployee();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading dashboard data: $e');
    }
  }

  // تحميل إحصائيات جميع الموظفين
  Future<void> loadAllEmployeesStats(String period) async {
    try {
      _isLoading = true;
      _currentPeriod = period;
      notifyListeners();

      _allEmployeesStats = await _statisticsService.getAllEmployeesAttendanceStats(period);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading all employees stats: $e');
    }
  }

  // تحميل تقرير الحضور والغياب
  Future<void> loadAttendanceReport(String period) async {
    try {
      _isLoading = true;
      _currentPeriod = period;
      notifyListeners();

      _attendanceReport = await _statisticsService.getAttendanceReport(period);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading attendance report: $e');
    }
  }

  // تحميل عدد دوام موظف معين
  Future<void> loadEmployeeAttendanceCount(String userId, String period) async {
    try {
      _isLoading = true;
      _currentPeriod = period;
      notifyListeners();

      _employeeAttendanceCount = await _statisticsService.getEmployeeAttendanceCount(userId, period);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading employee attendance count: $e');
    }
  }

  // تغيير الفترة الزمنية
  void changePeriod(String period) {
    _currentPeriod = period;
    notifyListeners();
  }
}
