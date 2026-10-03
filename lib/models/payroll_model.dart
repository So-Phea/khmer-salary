import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/korea_minimum_wage_service.dart';

enum CurrencyType {
  krw, // ₩ វ៉ុន
  khr, // ៛ រៀល
  usd, // $ ដុល្លារ
}

extension CurrencyTypeExtension on CurrencyType {
  String get symbol {
    switch (this) {
      case CurrencyType.krw:
        return '₩';
      case CurrencyType.khr:
        return '៛';
      case CurrencyType.usd:
        return '\$';
    }
  }

  String get code {
    switch (this) {
      case CurrencyType.krw:
        return 'KRW (₩)';
      case CurrencyType.khr:
        return 'KHR (៛)';
      case CurrencyType.usd:
        return 'USD (\$)';
    }
  }
}

enum AttendanceStatus {
  present, // មកធ្វើការ (Blue/Green)
  overtime, // ថែមម៉ោង (Amber/Yellow)
  leavePaid, // ឈប់មានច្បាប់ (Teal/Blue)
  absentUnpaid, // អវត្តមានឥតច្បាប់ (Red)
  dayOff, // ថ្ងៃសម្រាក (Grey)
}

extension AttendanceStatusExtension on AttendanceStatus {
  String localizedTitle(AppLanguage lang) {
    switch (this) {
      case AttendanceStatus.present:
        return LocalizationService.tr('status_present', lang);
      case AttendanceStatus.overtime:
        return LocalizationService.tr('status_ot', lang);
      case AttendanceStatus.leavePaid:
        return LocalizationService.tr('status_leave', lang);
      case AttendanceStatus.absentUnpaid:
        return LocalizationService.tr('status_absent', lang);
      case AttendanceStatus.dayOff:
        return LocalizationService.tr('status_dayoff', lang);
    }
  }

  String shortBadgeText(AppLanguage lang) {
    switch (this) {
      case AttendanceStatus.present:
        return lang == AppLanguage.korean ? '출근' : (lang == AppLanguage.english ? 'Work' : 'ធ្វើការ');
      case AttendanceStatus.overtime:
        return 'OT';
      case AttendanceStatus.leavePaid:
        return lang == AppLanguage.korean ? '휴가' : (lang == AppLanguage.english ? 'Leave' : 'ច្បាប់');
      case AttendanceStatus.absentUnpaid:
        return lang == AppLanguage.korean ? '결근' : (lang == AppLanguage.english ? 'Absent' : 'អវត្តមាន');
      case AttendanceStatus.dayOff:
        return lang == AppLanguage.korean ? '휴무' : (lang == AppLanguage.english ? 'Off' : 'សម្រាក');
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return const Color(0xFF2563EB); // Royal Blue (Crisp & Clean)
      case AttendanceStatus.overtime:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case AttendanceStatus.leavePaid:
        return const Color(0xFF0D9488); // Teal
      case AttendanceStatus.absentUnpaid:
        return const Color(0xFFEF4444); // Red
      case AttendanceStatus.dayOff:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.overtime:
        return Icons.more_time_rounded;
      case AttendanceStatus.leavePaid:
        return Icons.beach_access_rounded;
      case AttendanceStatus.absentUnpaid:
        return Icons.cancel_rounded;
      case AttendanceStatus.dayOff:
        return Icons.weekend_rounded;
    }
  }
}

enum WeekStartDay {
  sunday,   // អាទិត្យ ដល់ សៅរ៍ - Sun (Default per user request)
  monday,   // ច័ន្ទ ដល់ អាទិត្យ - Mon
  saturday, // សៅរ៍ ដល់ សុក្រ - Sat
}

extension WeekStartDayExtension on WeekStartDay {
  String localizedTitle(AppLanguage lang) {
    switch (this) {
      case WeekStartDay.sunday:
        return lang == AppLanguage.korean
            ? '일요일 시작 (일-토)'
            : (lang == AppLanguage.english ? 'Sunday (Sun - Sat)' : 'អាទិត្យ ដល់ សៅរ៍');
      case WeekStartDay.monday:
        return lang == AppLanguage.korean
            ? '월요일 시작 (월-일)'
            : (lang == AppLanguage.english ? 'Monday (Mon - Sun)' : 'ច័ន្ទ ដល់ អាទិត្យ');
      case WeekStartDay.saturday:
        return lang == AppLanguage.korean
            ? '토요일 시작 (토-금)'
            : (lang == AppLanguage.english ? 'Saturday (Sat - Fri)' : 'សៅរ៍ ដល់ សុក្រ');
    }
  }

  List<String> weekdays(AppLanguage lang) {
    switch (this) {
      case WeekStartDay.saturday:
        return lang == AppLanguage.korean
            ? ['토', '일', '월', '화', '수', '목', '금']
            : (lang == AppLanguage.english
                ? ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']
                : ['ស', 'អា', 'ច', 'អ', 'ព', 'ព្រ', 'សុ']);
      case WeekStartDay.sunday:
        return lang == AppLanguage.korean
            ? ['일', '월', '화', '수', '목', '금', '토']
            : (lang == AppLanguage.english
                ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                : ['អា', 'ច', 'អ', 'ព', 'ព្រ', 'សុ', 'ស']);
      case WeekStartDay.monday:
        return lang == AppLanguage.korean
            ? ['월', '화', '수', '목', '금', '토', '일']
            : (lang == AppLanguage.english
                ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                : ['ច', 'អ', 'ព', 'ព្រ', 'សុ', 'ស', 'អា']);
    }
  }

  int getStartingOffset(DateTime firstDayOfMonth) {
    switch (this) {
      case WeekStartDay.saturday:
        return (firstDayOfMonth.weekday - 6 + 7) % 7;
      case WeekStartDay.sunday:
        return firstDayOfMonth.weekday % 7;
      case WeekStartDay.monday:
        return firstDayOfMonth.weekday - 1;
    }
  }
}

class Employee {
  final String id;
  String name;
  String role;
  SalaryConfig config;

  Employee({
    required this.id,
    required this.name,
    this.role = 'បុគ្គលិក',
    required this.config,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'config': config.toJson(),
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'បុគ្គលិក',
      config: json['config'] != null
          ? SalaryConfig.fromJson(json['config'] as Map<String, dynamic>)
          : SalaryConfig(),
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    String? role,
    SalaryConfig? config,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      config: config ?? this.config,
    );
  }
}

enum SalaryType {
  hourly, // គិតជាម៉ោង (Hourly - Common in Korea)
  monthly, // គិតជាខែ (Monthly)
  daily, // គិតជាថ្ងៃ (Daily)
}

class SalaryConfig {
  SalaryType salaryType;
  double baseRate; // ឧទាហរណ៍ 10,320 វ៉ុន/ម៉ោង ឬ 2,156,880 វ៉ុន/ខែ
  double otHourlyRate; // អត្រា OT ក្នុង ១ ម៉ោង (1.5x)
  double lateDeductionPerHour; // កាត់កងក្នុង ១ ម៉ោងយឺត
  double krwToKhrRate; // Optional backwards compat
  double krwToUsdRate; // Optional backwards compat
  bool autoMinistryWage; // គណនាប្រាក់ម៉ោងស្វ័យប្រវត្តិតាមឆ្នាំដែលក្រសួងការងារកូរ៉េកំណត់
  int? statutoryYear; // ឆ្នាំក្រសួងដែលបានជ្រើសរើស (បើមិនកំណត់ យកតាមឆ្នាំនៃខែដែលកំពុងមើល)

  SalaryConfig({
    this.salaryType = SalaryType.hourly,
    double? baseRate,
    double? otHourlyRate,
    double? lateDeductionPerHour,
    this.krwToKhrRate = 3.05,
    this.krwToUsdRate = 0.00075,
    this.autoMinistryWage = true,
    this.statutoryYear,
  })  : baseRate = baseRate ??
            KoreaMinimumWageService.getHourlyRate(DateTime.now().year),
        otHourlyRate = otHourlyRate ??
            KoreaMinimumWageService.getOtHourlyRate(DateTime.now().year),
        lateDeductionPerHour = lateDeductionPerHour ??
            (baseRate ?? KoreaMinimumWageService.getHourlyRate(DateTime.now().year));

  /// Returns effective base rate for a specific calendar year.
  /// If [autoMinistryWage] is true, automatically resolves statutory rate for that year.
  double getEffectiveBaseRate(int year) {
    if (autoMinistryWage && salaryType == SalaryType.hourly) {
      final y = statutoryYear ?? year;
      return KoreaMinimumWageService.getHourlyRate(y);
    }
    return baseRate;
  }

  /// Returns effective overtime (OT 1.5x) rate for a specific calendar year.
  double getEffectiveOtRate(int year) {
    if (autoMinistryWage && salaryType == SalaryType.hourly) {
      final y = statutoryYear ?? year;
      return KoreaMinimumWageService.getOtHourlyRate(y);
    }
    return otHourlyRate;
  }

  Map<String, dynamic> toJson() => {
        'salaryType': salaryType.name,
        'baseRate': baseRate,
        'otHourlyRate': otHourlyRate,
        'lateDeductionPerHour': lateDeductionPerHour,
        'krwToKhrRate': krwToKhrRate,
        'krwToUsdRate': krwToUsdRate,
        'autoMinistryWage': autoMinistryWage,
        if (statutoryYear != null) 'statutoryYear': statutoryYear,
      };

  factory SalaryConfig.fromJson(Map<String, dynamic> json) {
    final nowYear = DateTime.now().year;
    final defaultBase = KoreaMinimumWageService.getHourlyRate(nowYear);
    final defaultOt = KoreaMinimumWageService.getOtHourlyRate(nowYear);

    return SalaryConfig(
      salaryType: SalaryType.values.firstWhere(
        (e) => e.name == json['salaryType'],
        orElse: () => SalaryType.hourly,
      ),
      baseRate: (json['baseRate'] as num?)?.toDouble() ?? defaultBase,
      otHourlyRate: (json['otHourlyRate'] as num?)?.toDouble() ?? defaultOt,
      lateDeductionPerHour:
          (json['lateDeductionPerHour'] as num?)?.toDouble() ?? defaultBase,
      krwToKhrRate: (json['krwToKhrRate'] as num?)?.toDouble() ?? 3.05,
      krwToUsdRate: (json['krwToUsdRate'] as num?)?.toDouble() ?? 0.00075,
      autoMinistryWage: json['autoMinistryWage'] as bool? ?? true,
      statutoryYear: json['statutoryYear'] as int?,
    );
  }

  SalaryConfig copyWith({
    SalaryType? salaryType,
    double? baseRate,
    double? otHourlyRate,
    double? lateDeductionPerHour,
    double? krwToKhrRate,
    double? krwToUsdRate,
    bool? autoMinistryWage,
    int? statutoryYear,
  }) {
    return SalaryConfig(
      salaryType: salaryType ?? this.salaryType,
      baseRate: baseRate ?? this.baseRate,
      otHourlyRate: otHourlyRate ?? this.otHourlyRate,
      lateDeductionPerHour:
          lateDeductionPerHour ?? this.lateDeductionPerHour,
      krwToKhrRate: krwToKhrRate ?? this.krwToKhrRate,
      krwToUsdRate: krwToUsdRate ?? this.krwToUsdRate,
      autoMinistryWage: autoMinistryWage ?? this.autoMinistryWage,
      statutoryYear: statutoryYear ?? this.statutoryYear,
    );
  }
}

class WorkLog {
  final String dateKey; // 'YYYY-MM-DD'
  AttendanceStatus status;
  String checkIn; // '08:00'
  String checkOut; // '17:00'
  int regularMinutesTotal; // in minutes (e.g. 480 = 8h 00m, 510 = 8h 30m)
  int otMinutesTotal; // in minutes (e.g. 135 = 2h 15m)
  int lateMinutes;
  String note;

  WorkLog({
    required this.dateKey,
    this.status = AttendanceStatus.present,
    this.checkIn = '08:00',
    this.checkOut = '17:00',
    int? regularMinutesTotal,
    int? otMinutesTotal,
    double? regularHours,
    double? otHours,
    this.lateMinutes = 0,
    this.note = '',
  })  : regularMinutesTotal = regularMinutesTotal ??
            (regularHours != null ? (regularHours * 60).round() : 480),
        otMinutesTotal = otMinutesTotal ??
            (otHours != null ? (otHours * 60).round() : 0);

  // Breakdown getters
  int get regularHours => regularMinutesTotal ~/ 60;
  int get regularMinutes => regularMinutesTotal % 60;
  double get regularHoursDecimal => regularMinutesTotal / 60.0;

  int get otHours => otMinutesTotal ~/ 60;
  int get otMinutes => otMinutesTotal % 60;
  double get otHoursDecimal => otMinutesTotal / 60.0;

  int get totalMinutesTotal => regularMinutesTotal + otMinutesTotal;
  int get totalHours => totalMinutesTotal ~/ 60;
  int get totalMinutesPart => totalMinutesTotal % 60;
  double get totalHoursDecimal => totalMinutesTotal / 60.0;

  // Formatted duration helper (e.g. "8h 30m" or "8시간 30분")
  static String formatDuration(int totalMins, AppLanguage lang, {bool short = false}) {
    if (totalMins <= 0) return '0h 00m';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;

    switch (lang) {
      case AppLanguage.khmer:
        if (m == 0) return '${h}h 00m';
        return '${h}h ${m.toString().padLeft(2, '0')}m';
      case AppLanguage.korean:
        if (m == 0) return '$h시간';
        return '$h시간 $m분';
      case AppLanguage.english:
        if (m == 0) return '${h}h 00m';
        return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
  }

  // Khmer-specific numeric representation
  static String formatKhmerDuration(int totalMins) {
    if (totalMins <= 0) return '0ម៉';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (m == 0) return '$hម៉';
    return '$hម៉ $mន';
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'status': status.name,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'regularMinutesTotal': regularMinutesTotal,
        'otMinutesTotal': otMinutesTotal,
        'regularHours': regularHoursDecimal,
        'otHours': otHoursDecimal,
        'lateMinutes': lateMinutes,
        'note': note,
      };

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    int regMins = 480;
    if (json.containsKey('regularMinutesTotal')) {
      regMins = (json['regularMinutesTotal'] as num).toInt();
    } else if (json.containsKey('regularHours')) {
      regMins = ((json['regularHours'] as num).toDouble() * 60).round();
    }

    int otMins = 0;
    if (json.containsKey('otMinutesTotal')) {
      otMins = (json['otMinutesTotal'] as num).toInt();
    } else if (json.containsKey('otHours')) {
      otMins = ((json['otHours'] as num).toDouble() * 60).round();
    }

    return WorkLog(
      dateKey: json['dateKey'] as String,
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      checkIn: json['checkIn'] as String? ?? '08:00',
      checkOut: json['checkOut'] as String? ?? '17:00',
      regularMinutesTotal: regMins,
      otMinutesTotal: otMins,
      lateMinutes: (json['lateMinutes'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class PayrollCalculation {
  final int totalWorkingDays;
  final int totalRegularMinutes; // Minute-level exact sum
  final int totalOtMinutes; // Minute-level exact sum
  final int totalAbsences;
  final int totalLeaves;
  final int totalLateMinutes;
  final double baseSalaryKrw;
  final double otPayKrw;
  final double deductionsKrw;
  final double netSalaryKrw;
  final SalaryConfig config;

  PayrollCalculation({
    required this.totalWorkingDays,
    required this.totalRegularMinutes,
    required this.totalOtMinutes,
    required this.totalAbsences,
    required this.totalLeaves,
    required this.totalLateMinutes,
    required this.baseSalaryKrw,
    required this.otPayKrw,
    required this.deductionsKrw,
    required this.netSalaryKrw,
    required this.config,
  });

  // Hours getters for calculations
  double get totalRegularHours => totalRegularMinutes / 60.0;
  double get totalOtHours => totalOtMinutes / 60.0;

  int get totalMinutesAll => totalRegularMinutes + totalOtMinutes;
  int get totalHoursAll => totalMinutesAll ~/ 60;
  int get totalMinutesPartAll => totalMinutesAll % 60;

  int get regularHoursPart => totalRegularMinutes ~/ 60;
  int get regularMinutesPart => totalRegularMinutes % 60;

  int get otHoursPart => totalOtMinutes ~/ 60;
  int get otMinutesPart => totalOtMinutes % 60;

  String formatRegularDuration(AppLanguage lang) =>
      WorkLog.formatDuration(totalRegularMinutes, lang);

  String formatOtDuration(AppLanguage lang) =>
      WorkLog.formatDuration(totalOtMinutes, lang);

  String formatTotalDuration(AppLanguage lang) =>
      WorkLog.formatDuration(totalMinutesAll, lang);

  // Multi-Currency getters
  double get netSalaryKhr => netSalaryKrw * config.krwToKhrRate;
  double get netSalaryUsd => netSalaryKrw * config.krwToUsdRate;

  // Formatted amounts
  String get formattedNetWon => '₩${_formatNumber(netSalaryKrw.round())}';
  String get formattedNetKhr => '${_formatNumber(netSalaryKhr.round())} ៛';
  String get formattedNetUsd => '\$${netSalaryUsd.toStringAsFixed(2)}';

  String get formattedBaseWon => '₩${_formatNumber(baseSalaryKrw.round())}';
  String get formattedOtWon => '₩${_formatNumber(otPayKrw.round())}';
  String get formattedDeductionsWon => '₩${_formatNumber(deductionsKrw.round())}';

  String formatAmount(double amountKrw, [CurrencyType type = CurrencyType.krw]) {
    switch (type) {
      case CurrencyType.krw:
        return '₩${_formatNumber(amountKrw.round())}';
      case CurrencyType.khr:
        final khr = (amountKrw * config.krwToKhrRate).round();
        return '${_formatNumber(khr)} ៛';
      case CurrencyType.usd:
        final usd = amountKrw * config.krwToUsdRate;
        return '\$${usd.toStringAsFixed(2)}';
    }
  }

  static String _formatNumber(num n) {
    final str = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }
}
