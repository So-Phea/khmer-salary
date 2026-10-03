import 'package:flutter/material.dart';
import 'models/task_model.dart';
import 'models/user_model.dart';
import 'models/payroll_model.dart';
import 'services/storage_service.dart';
import 'services/localization_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/payroll_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TicaApp());
}

class TicaApp extends StatefulWidget {
  const TicaApp({super.key});

  @override
  State<TicaApp> createState() => _TicaAppState();
}

class _TicaAppState extends State<TicaApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;
  List<Task> _tasks = [];
  late AppUser _user;
  AppLanguage _language = AppLanguage.khmer;
  SalaryConfig _salaryConfig = SalaryConfig();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final tasks = await StorageService.loadTasks();
    final user = await StorageService.loadUser();
    final isDark = await StorageService.loadDarkMode();
    final lang = await StorageService.loadLanguage();
    final config = await StorageService.loadSalaryConfig();

    setState(() {
      _tasks = tasks;
      _user = user;
      _isDarkMode = isDark;
      _language = lang;
      _salaryConfig = config;
      _isLoading = false;
    });
  }

  void _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await StorageService.saveDarkMode(value);
  }

  void _updateLanguage(AppLanguage lang) async {
    setState(() => _language = lang);
    await StorageService.saveLanguage(lang);
  }

  void _updateSalaryConfig(SalaryConfig config) async {
    setState(() => _salaryConfig = config);
    await StorageService.saveSalaryConfig(config);
  }

  void _toggleTaskCompletion(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      }
    });
    await StorageService.saveTasks(_tasks);
  }

  void _deleteTask(String id) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    await StorageService.saveTasks(_tasks);
  }

  void _saveTask(Task task) async {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
      } else {
        _tasks.insert(0, task);
      }
    });
    await StorageService.saveTasks(_tasks);
  }

  void _updateUser(AppUser updatedUser) async {
    setState(() => _user = updatedUser);
    await StorageService.saveUser(updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Khmer Salary - គណនាប្រាក់ខែ និងម៉ោងការងារ',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: MainNavigationShell(
        tasks: _tasks,
        user: _user,
        isDarkMode: _isDarkMode,
        language: _language,
        salaryConfig: _salaryConfig,
        onToggleDarkMode: _toggleDarkMode,
        onUpdateLanguage: _updateLanguage,
        onUpdateSalaryConfig: _updateSalaryConfig,
        onToggleTask: _toggleTaskCompletion,
        onDeleteTask: _deleteTask,
        onSaveTask: _saveTask,
        onUpdateUser: _updateUser,
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final List<Task> tasks;
  final AppUser user;
  final bool isDarkMode;
  final AppLanguage language;
  final SalaryConfig salaryConfig;
  final Function(bool) onToggleDarkMode;
  final Function(AppLanguage) onUpdateLanguage;
  final Function(SalaryConfig) onUpdateSalaryConfig;
  final Function(Task) onToggleTask;
  final Function(String) onDeleteTask;
  final Function(Task) onSaveTask;
  final Function(AppUser) onUpdateUser;

  const MainNavigationShell({
    super.key,
    required this.tasks,
    required this.user,
    required this.isDarkMode,
    required this.language,
    required this.salaryConfig,
    required this.onToggleDarkMode,
    required this.onUpdateLanguage,
    required this.onUpdateSalaryConfig,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onSaveTask,
    required this.onUpdateUser,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 2; // Default to Payroll & Work Hours tab

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final List<Widget> pages = [
      DashboardScreen(
        tasks: widget.tasks,
        user: widget.user,
        onToggleTask: widget.onToggleTask,
        onDeleteTask: widget.onDeleteTask,
        onSaveTask: widget.onSaveTask,
      ),
      CalendarScreen(
        tasks: widget.tasks,
        onToggleTask: widget.onToggleTask,
        onDeleteTask: widget.onDeleteTask,
        onSaveTask: widget.onSaveTask,
      ),
      PayrollScreen(
        user: widget.user,
        language: widget.language,
        salaryConfig: widget.salaryConfig,
        onUpdateSalaryConfig: widget.onUpdateSalaryConfig,
      ),
      AnalyticsScreen(tasks: widget.tasks),
      ProfileScreen(
        user: widget.user,
        isDarkMode: widget.isDarkMode,
        language: widget.language,
        salaryConfig: widget.salaryConfig,
        onToggleDarkMode: widget.onToggleDarkMode,
        onUpdateUser: widget.onUpdateUser,
        onLanguageChanged: widget.onUpdateLanguage,
        onUpdateSalaryConfig: widget.onUpdateSalaryConfig,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: LocalizationService.tr('tab_dashboard', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: LocalizationService.tr('tab_calendar', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments_rounded),
            label: LocalizationService.tr('tab_payroll', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: LocalizationService.tr('tab_analytics', lang),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: LocalizationService.tr('tab_profile', lang),
          ),
        ],
      ),
    );
  }
}
