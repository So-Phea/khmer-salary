import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/payroll_model.dart';
import 'localization_service.dart';

class StorageService {
  static const String _tasksKey = 'tica_tasks';
  static const String _userKey = 'tica_user';
  static const String _themeKey = 'tica_theme_mode';
  static const String _workLogsKey = 'tica_work_logs';
  static const String _salaryConfigKey = 'tica_salary_config';

  static Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJsonString = prefs.getString(_tasksKey);
    if (tasksJsonString == null || tasksJsonString.isEmpty) {
      return _generateDefaultTasks();
    }
    try {
      final List<dynamic> decoded = jsonDecode(tasksJsonString);
      return decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return _generateDefaultTasks();
    }
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(jsonList));
  }

  static Future<AppUser> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
      return AppUser(
        id: 'u_101',
        name: 'Sophea Lan',
        email: 'sophea@tica.app',
        isPremium: false,
      );
    }
    return AppUser.fromJson(jsonDecode(userJson));
  }

  static Future<void> saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static const String _languageKey = 'tica_language';

  static Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langStr = prefs.getString(_languageKey);
    return AppLanguage.values.firstWhere(
      (l) => l.name == langStr,
      orElse: () => AppLanguage.khmer,
    );
  }

  static Future<void> saveLanguage(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang.name);
  }

  static Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Work Logs
  static Future<Map<String, WorkLog>> loadWorkLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_workLogsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return _generateDefaultWorkLogs();
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, WorkLog> result = {};
      decoded.forEach((key, val) {
        result[key] = WorkLog.fromJson(val as Map<String, dynamic>);
      });
      return result;
    } catch (e) {
      return _generateDefaultWorkLogs();
    }
  }

  static Future<void> saveWorkLogs(Map<String, WorkLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map = {};
    logs.forEach((k, v) => map[k] = v.toJson());
    await prefs.setString(_workLogsKey, jsonEncode(map));
  }

  // Salary Config
  static Future<SalaryConfig> loadSalaryConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_salaryConfigKey);
    if (jsonString == null || jsonString.isEmpty) {
      return SalaryConfig();
    }
    try {
      return SalaryConfig.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return SalaryConfig();
    }
  }

  static Future<void> saveSalaryConfig(SalaryConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_salaryConfigKey, jsonEncode(config.toJson()));
  }

  // Multi-Employee Storage
  static const String _employeesKey = 'tica_employees';
  static const String _activeEmployeeIdKey = 'tica_active_emp_id';
  static const String _weekStartKey = 'tica_week_start_day';

  static Future<List<Employee>> loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_employeesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaultSalary = await loadSalaryConfig();
      final defaultList = [
        Employee(
          id: 'emp_me',
          name: 'ខ្ញុំ (Me)',
          role: 'ពលករ/បុគ្គលិក',
          config: defaultSalary,
        ),
      ];
      await saveEmployees(defaultList);
      return defaultList;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final employees =
          list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
      if (employees.isEmpty) {
        final defaultSalary = await loadSalaryConfig();
        return [
          Employee(
            id: 'emp_me',
            name: 'ខ្ញុំ (Me)',
            role: 'ពលករ/បុគ្គលិក',
            config: defaultSalary,
          ),
        ];
      }
      return employees;
    } catch (_) {
      final defaultSalary = await loadSalaryConfig();
      return [
        Employee(
          id: 'emp_me',
          name: 'ខ្ញុំ (Me)',
          role: 'ពលករ/បុគ្គលិក',
          config: defaultSalary,
        ),
      ];
    }
  }

  static Future<void> saveEmployees(List<Employee> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(_employeesKey, jsonEncode(jsonList));
  }

  static Future<String> loadActiveEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeEmployeeIdKey) ?? 'emp_me';
  }

  static Future<void> saveActiveEmployeeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeEmployeeIdKey, id);
  }

  static Future<Map<String, WorkLog>> loadEmployeeWorkLogs(
      String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tica_work_logs_$employeeId';
    final jsonString = prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      if (employeeId == 'emp_me') {
        return loadWorkLogs();
      }
      return {};
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final Map<String, WorkLog> result = {};
      decoded.forEach((k, val) {
        result[k] = WorkLog.fromJson(val as Map<String, dynamic>);
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveEmployeeWorkLogs(
      String employeeId, Map<String, WorkLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'tica_work_logs_$employeeId';
    final Map<String, dynamic> map = {};
    logs.forEach((k, v) => map[k] = v.toJson());
    await prefs.setString(key, jsonEncode(map));
    if (employeeId == 'emp_me') {
      await saveWorkLogs(logs);
    }
  }

  // Week Start Day
  static Future<WeekStartDay> loadWeekStartDay() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_weekStartKey);
    if (str == null || str == 'saturday') {
      return WeekStartDay.sunday; // Default Sunday (អាទិត្យ ដល់ សៅរ៍) per user request!
    }
    return WeekStartDay.values.firstWhere(
      (e) => e.name == str,
      orElse: () => WeekStartDay.sunday,
    );
  }

  static Future<void> saveWeekStartDay(WeekStartDay day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weekStartKey, day.name);
  }

  static List<Task> _generateDefaultTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'រៀបចំកាលវិភាគការងារប្រចាំសប្តាហ៍ (Weekly Schedule)',
        description: 'កំណត់អាទិភាពគម្រោង និងការងារដែលត្រូវធ្វើជាមួយក្រុមការងារ',
        category: TaskCategory.work,
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(hours: 3)),
        isCompleted: true,
      ),
      Task(
        id: '2',
        title: 'រៀន Flutter & Dart Architecture (Study Session)',
        description: 'ស្វែងយល់បន្ថែមអំពី State Management និង Offline Storage',
        category: TaskCategory.study,
        priority: TaskPriority.high,
        dueDate: now.add(const Duration(hours: 6)),
        isCompleted: false,
      ),
      Task(
        id: '3',
        title: 'ហាត់ប្រាណពេលល្ងាច ៤៥ នាទី (Evening Workout)',
        description: 'រត់ហាត់ប្រាណ ឬ Cardio ដើម្បីសុខភាពល្អ',
        category: TaskCategory.health,
        priority: TaskPriority.medium,
        dueDate: now.add(const Duration(hours: 10)),
        isCompleted: false,
      ),
      Task(
        id: '4',
        title: 'ទិញសម្ភារៈ និងអាហារសម្រាប់គ្រួសារ (Grocery Shopping)',
        description: 'ទិញបន្លែ ផ្លែឈើ និងរបស់ប្រើប្រាស់ប្រចាំថ្ងៃ',
        category: TaskCategory.family,
        priority: TaskPriority.low,
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
      ),
    ];
  }

  static Map<String, WorkLog> _generateDefaultWorkLogs() {
    final now = DateTime.now();
    final Map<String, WorkLog> sample = {};
    // Generate sample logs for current month
    for (int i = 1; i <= now.day; i++) {
      final date = DateTime(now.year, now.month, i);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Weekend: Day off
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        sample[key] = WorkLog(
          dateKey: key,
          status: AttendanceStatus.dayOff,
          regularHours: 0,
          otHours: 0,
          note: 'សម្រាកចុងសប្តាហ៍',
        );
      } else if (i == 3) {
        // Sample Overtime
        sample[key] = WorkLog(
          dateKey: key,
          status: AttendanceStatus.overtime,
          checkIn: '08:00',
          checkOut: '19:30',
          regularHours: 8,
          otHours: 2.5,
          note: 'ថែមម៉ោងបញ្ចប់ Report',
        );
      } else if (i == 5) {
        // Sample leave
        sample[key] = WorkLog(
          dateKey: key,
          status: AttendanceStatus.leavePaid,
          regularHours: 0,
          otHours: 0,
          note: 'ឈប់ច្បាប់មានធុរៈគ្រួសារ',
        );
      } else {
        // Regular present
        sample[key] = WorkLog(
          dateKey: key,
          status: AttendanceStatus.present,
          checkIn: '08:00',
          checkOut: '17:00',
          regularHours: 8,
          otHours: 0,
          lateMinutes: i == 2 ? 15 : 0,
        );
      }
    }
    return sample;
  }
}
