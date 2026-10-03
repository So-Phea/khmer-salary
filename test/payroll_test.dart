import 'package:flutter_test/flutter_test.dart';
import 'package:tica/models/payroll_model.dart';
import 'package:tica/services/localization_service.dart';
import 'package:tica/services/korea_minimum_wage_service.dart';

void main() {
  group('Khmer Salary Minute-Precision & Multi-Currency Tests', () {
    test('Calculates minute-level precision matching user exact example (8h 45m = 86,275 KRW)', () {
      final config = SalaryConfig(
        salaryType: SalaryType.hourly,
        baseRate: 9860.0, // 9,860 KRW/hr
        otHourlyRate: 14790.0, // 14,790 KRW/hr (1.5x)
        krwToKhrRate: 3.05,
        krwToUsdRate: 0.00075,
      );

      // 8 hours 45 minutes = 8 * 60 + 45 = 525 minutes
      final log = WorkLog(
        dateKey: '2026-10-01',
        status: AttendanceStatus.present,
        regularMinutesTotal: 525, // 8h 45m
        otMinutesTotal: 0,
      );

      expect(log.regularHours, equals(8));
      expect(log.regularMinutes, equals(45));
      expect(log.regularHoursDecimal, equals(8.75));

      // Daily wage calculation: 8.75 * 9,860 = 86,275 KRW
      final dailyWage = log.regularHoursDecimal * config.baseRate;
      expect(dailyWage, equals(86275.0));

      // Remittance into KHR: 86,275 * 3.05 = 263,138.75 KHR
      final khrVal = dailyWage * config.krwToKhrRate;
      expect(khrVal, equals(263138.75));
    });

    test('Monthly minute-sum calculation with OT and multi-currency formatting', () {
      final config = SalaryConfig(
        salaryType: SalaryType.hourly,
        baseRate: 9860.0,
        otHourlyRate: 14790.0,
        krwToKhrRate: 3.05,
        krwToUsdRate: 0.00075,
      );

      // 20 workdays: 160 hours (9600 mins) regular, 24h 30m (1470 mins) OT
      const totalRegMins = 9600; // 160h 00m
      const totalOtMins = 1470; // 24h 30m = 24.5h

      final baseWage = (totalRegMins / 60.0) * config.baseRate; // 160 * 9,860 = 1,577,600 KRW
      final otWage = (totalOtMins / 60.0) * config.otHourlyRate; // 24.5 * 14,790 = 362,355 KRW
      final netWage = baseWage + otWage; // 1,939,955 KRW

      final calc = PayrollCalculation(
        totalWorkingDays: 20,
        totalRegularMinutes: totalRegMins,
        totalOtMinutes: totalOtMins,
        totalAbsences: 0,
        totalLeaves: 0,
        totalLateMinutes: 0,
        baseSalaryKrw: baseWage,
        otPayKrw: otWage,
        deductionsKrw: 0.0,
        netSalaryKrw: netWage,
        config: config,
      );

      expect(calc.netSalaryKrw, equals(1939955.0));
      expect(calc.regularHoursPart, equals(160));
      expect(calc.regularMinutesPart, equals(0));
      expect(calc.otHoursPart, equals(24));
      expect(calc.otMinutesPart, equals(30));

      // KRW formatted
      expect(calc.formatAmount(calc.netSalaryKrw), equals('₩1,939,955'));
      expect(calc.formattedNetWon, equals('₩1,939,955'));
      expect(calc.formattedBaseWon, equals('₩1,577,600'));
      expect(calc.formattedOtWon, equals('₩362,355'));

      // KHR and USD formatted
      expect(calc.formatAmount(calc.netSalaryKrw, CurrencyType.khr), contains('៛'));
      expect(calc.formattedNetKhr, contains('៛'));
      expect(calc.formattedNetUsd, contains('\$'));

      // Duration strings
      expect(calc.formatRegularDuration(AppLanguage.english), equals('160h 00m'));
      expect(calc.formatOtDuration(AppLanguage.english), equals('24h 30m'));
      expect(calc.formatOtDuration(AppLanguage.korean), equals('24시간 30분'));
    });

    test('Trilingual Localization Dictionary works for Khmer, Korean, English', () {
      expect(
        LocalizationService.tr('app_name_display', AppLanguage.khmer),
        equals('Khmer Salary'),
      );
      expect(
        LocalizationService.tr('payroll_title', AppLanguage.khmer),
        contains('Khmer Salary'),
      );
      expect(
        LocalizationService.tr('payroll_title', AppLanguage.korean),
        contains('Khmer Salary'),
      );
      expect(
        LocalizationService.tr('payroll_title', AppLanguage.english),
        contains('Khmer Salary'),
      );
    });

    test('AttendanceStatus badges are translated properly', () {
      expect(AttendanceStatus.present.shortBadgeText(AppLanguage.khmer), equals('ធ្វើការ'));
      expect(AttendanceStatus.present.shortBadgeText(AppLanguage.korean), equals('출근'));
      expect(AttendanceStatus.present.shortBadgeText(AppLanguage.english), equals('Work'));

      expect(AttendanceStatus.overtime.shortBadgeText(AppLanguage.korean), equals('OT'));
      expect(AttendanceStatus.dayOff.shortBadgeText(AppLanguage.khmer), equals('សម្រាក'));
      expect(AttendanceStatus.dayOff.shortBadgeText(AppLanguage.korean), equals('휴무'));
    });

    test('WeekStartDay Sunday start offsets and weekday labels in Khmer (Sun to Sat)', () {
      final sunWeekdays = WeekStartDay.sunday.weekdays(AppLanguage.khmer);
      expect(sunWeekdays, equals(['អា', 'ច', 'អ', 'ព', 'ព្រ', 'សុ', 'ស']));

      // 2026-03-01 was a Sunday (DateTime.sunday = 7)
      final sunDate = DateTime(2026, 3, 1);
      expect(sunDate.weekday, equals(DateTime.sunday));
      expect(WeekStartDay.sunday.getStartingOffset(sunDate), equals(0));

      // 2026-06-01 was a Monday (DateTime.monday = 1)
      final monDate = DateTime(2026, 6, 1);
      expect(monDate.weekday, equals(DateTime.monday));
      expect(WeekStartDay.sunday.getStartingOffset(monDate), equals(1));

      // 2026-08-01 was a Saturday (DateTime.saturday = 6)
      final satDate = DateTime(2026, 8, 1);
      expect(satDate.weekday, equals(DateTime.saturday));
      expect(WeekStartDay.sunday.getStartingOffset(satDate), equals(6));
    });

    test('WeekStartDay Saturday start offsets and weekday labels in Khmer', () {
      final satWeekdays = WeekStartDay.saturday.weekdays(AppLanguage.khmer);
      expect(satWeekdays, equals(['ស', 'អា', 'ច', 'អ', 'ព', 'ព្រ', 'សុ']));

      // 2026-08-01 was a Saturday (DateTime.saturday = 6)
      final satDate = DateTime(2026, 8, 1);
      expect(satDate.weekday, equals(DateTime.saturday));
      expect(WeekStartDay.saturday.getStartingOffset(satDate), equals(0));

      // 2026-03-01 was a Sunday (DateTime.sunday = 7)
      final sunDate = DateTime(2026, 3, 1);
      expect(sunDate.weekday, equals(DateTime.sunday));
      expect(WeekStartDay.saturday.getStartingOffset(sunDate), equals(1));

      // 2026-06-01 was a Monday (DateTime.monday = 1)
      final monDate = DateTime(2026, 6, 1);
      expect(monDate.weekday, equals(DateTime.monday));
      expect(WeekStartDay.saturday.getStartingOffset(monDate), equals(2));
    });

    test('Employee model serialization and configuration independence', () {
      final emp = Employee(
        id: 'emp_001',
        name: 'សុខា (Sokha)',
        role: 'ផ្នែករោងចក្រ',
        config: SalaryConfig(baseRate: 10500.0, otHourlyRate: 15750.0),
      );

      final json = emp.toJson();
      final reconstructed = Employee.fromJson(json);

      expect(reconstructed.id, equals('emp_001'));
      expect(reconstructed.name, equals('សុខា (Sokha)'));
      expect(reconstructed.role, equals('ផ្នែករោងចក្រ'));
      expect(reconstructed.config.baseRate, equals(10500.0));
      expect(reconstructed.config.otHourlyRate, equals(15750.0));

      final updated = reconstructed.copyWith(name: 'សុខា កែប្រែ', role: 'ប្រធានក្រុម');
      expect(updated.name, equals('សុខា កែប្រែ'));
      expect(updated.role, equals('ប្រធានក្រុម'));
      expect(updated.id, equals('emp_001'));
    });

    test('KoreaMinimumWageService returns exact official MOEL statutory minimum rates by year', () {
      // 2026: 10,320 ₩/hr, OT 15,480 ₩/hr, Monthly: 2,156,880 ₩
      final info2026 = KoreaMinimumWageService.getInfoForYear(2026);
      expect(info2026.hourlyRate, equals(10320.0));
      expect(info2026.otHourlyRate, equals(15480.0));
      expect(info2026.monthlyStandard, equals(2156880.0));
      expect(info2026.formattedHourly, equals('₩10,320'));
      expect(info2026.formattedOt, equals('₩15,480'));
      expect(info2026.formattedMonthly, equals('₩2,156,880'));

      // 2025: 10,030 ₩/hr, OT 15,045 ₩/hr, Monthly: 2,096,270 ₩
      final info2025 = KoreaMinimumWageService.getInfoForYear(2025);
      expect(info2025.hourlyRate, equals(10030.0));
      expect(info2025.otHourlyRate, equals(15045.0));
      expect(info2025.monthlyStandard, equals(2096270.0));

      // 2024: 9,860 ₩/hr, OT 14,790 ₩/hr
      final info2024 = KoreaMinimumWageService.getInfoForYear(2024);
      expect(info2024.hourlyRate, equals(9860.0));
      expect(info2024.otHourlyRate, equals(14790.0));

      // 2027: 10,700 ₩/hr
      expect(KoreaMinimumWageService.getHourlyRate(2027), equals(10700.0));
      expect(KoreaMinimumWageService.getOtHourlyRate(2027), equals(16050.0));
    });

    test('SalaryConfig autoMinistryWage automatically adjusts rates based on calendar year', () {
      final config = SalaryConfig(autoMinistryWage: true);

      // In 2026
      expect(config.getEffectiveBaseRate(2026), equals(10320.0));
      expect(config.getEffectiveOtRate(2026), equals(15480.0));

      // In 2025
      expect(config.getEffectiveBaseRate(2025), equals(10030.0));
      expect(config.getEffectiveOtRate(2025), equals(15045.0));

      // In 2024
      expect(config.getEffectiveBaseRate(2024), equals(9860.0));
      expect(config.getEffectiveOtRate(2024), equals(14790.0));

      // If user overrides with custom manual rate (autoMinistryWage: false)
      final manualConfig = SalaryConfig(
        autoMinistryWage: false,
        baseRate: 11000.0,
        otHourlyRate: 16500.0,
      );
      expect(manualConfig.getEffectiveBaseRate(2026), equals(11000.0));
      expect(manualConfig.getEffectiveOtRate(2026), equals(16500.0));
    });
  });
}
