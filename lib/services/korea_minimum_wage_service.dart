import 'package:intl/intl.dart';

class StatutoryWageInfo {
  final int year;
  final double hourlyRate;
  final double otHourlyRate;
  final double monthlyStandard; // Based on 209 hours per month (40 regular hours/week + 8 hours paid weekly holiday)
  final double increasePercent;
  final String officialNotice;
  final String descriptionKhmer;

  const StatutoryWageInfo({
    required this.year,
    required this.hourlyRate,
    required this.otHourlyRate,
    required this.monthlyStandard,
    required this.increasePercent,
    required this.officialNotice,
    required this.descriptionKhmer,
  });

  String get formattedHourly => '₩${NumberFormat('#,###').format(hourlyRate.round())}';
  String get formattedOt => '₩${NumberFormat('#,###').format(otHourlyRate.round())}';
  String get formattedMonthly => '₩${NumberFormat('#,###').format(monthlyStandard.round())}';
}

/// Official Minimum Wage Service for South Korea (고용노동부 최저임금)
/// Automatically resolves statutory minimum hourly wage & OT rate based on official Ministry of Employment and Labor policies by year.
class KoreaMinimumWageService {
  static const Map<int, StatutoryWageInfo> _ministryRates = {
    2027: StatutoryWageInfo(
      year: 2027,
      hourlyRate: 10700.0,
      otHourlyRate: 16050.0,
      monthlyStandard: 2236300.0,
      increasePercent: 3.68,
      officialNotice: '고용노동부 최저임금 고시',
      descriptionKhmer: 'ឆ្នាំ ២០២៧: ១០,៧០០ វ៉ុន/ម៉ោង (OT: ១៦,០៥០ វ៉ុន)',
    ),
    2026: StatutoryWageInfo(
      year: 2026,
      hourlyRate: 10320.0,
      otHourlyRate: 15480.0,
      monthlyStandard: 2156880.0,
      increasePercent: 2.89,
      officialNotice: '고용노동부 최저임금 고시',
      descriptionKhmer: 'ឆ្នាំ ២០២៦: ១០,៣២០ វ៉ុន/ម៉ោង (OT: ១៥,៤៨០ វ៉ុន)',
    ),
    2025: StatutoryWageInfo(
      year: 2025,
      hourlyRate: 10030.0,
      otHourlyRate: 15045.0,
      monthlyStandard: 2096270.0,
      increasePercent: 1.72,
      officialNotice: '고용노동부 고시 제2024-58호',
      descriptionKhmer: 'ឆ្នាំ ២០២៥: ១០,០៣០ វ៉ុន/ម៉ោង (OT: ១៥,០៤៥ វ៉ុន - លើស ១ម៉ឺនវ៉ុន)',
    ),
    2024: StatutoryWageInfo(
      year: 2024,
      hourlyRate: 9860.0,
      otHourlyRate: 14790.0,
      monthlyStandard: 2060740.0,
      increasePercent: 2.50,
      officialNotice: '고용노동부 고시 제2023-43호',
      descriptionKhmer: 'ឆ្នាំ ២០២៤: ៩,៨៦០ វ៉ុន/ម៉ោង (OT: ១៤,៧៩០ វ៉ុន)',
    ),
    2023: StatutoryWageInfo(
      year: 2023,
      hourlyRate: 9620.0,
      otHourlyRate: 14430.0,
      monthlyStandard: 2010580.0,
      increasePercent: 5.02,
      officialNotice: '고용노동부 고시 제2022-67호',
      descriptionKhmer: 'ឆ្នាំ ២០២៣: ៩,៦២០ វ៉ុន/ម៉ោង (OT: ១៤,៤៣០ វ៉ុន)',
    ),
    2022: StatutoryWageInfo(
      year: 2022,
      hourlyRate: 9160.0,
      otHourlyRate: 13740.0,
      monthlyStandard: 1914440.0,
      increasePercent: 5.05,
      officialNotice: '고용노동부 고시 제2021-75호',
      descriptionKhmer: 'ឆ្នាំ ២០២២: ៩,១៦០ វ៉ុន/ម៉ោង (OT: ១៣,៧៤០ វ៉ុន)',
    ),
    2021: StatutoryWageInfo(
      year: 2021,
      hourlyRate: 8720.0,
      otHourlyRate: 13080.0,
      monthlyStandard: 1822480.0,
      increasePercent: 1.51,
      officialNotice: '고용노동부 고시 제2020-111호',
      descriptionKhmer: 'ឆ្នាំ ២០២១: ៨,៧២០ វ៉ុន/ម៉ោង (OT: ១៣,០៨០ វ៉ុន)',
    ),
    2020: StatutoryWageInfo(
      year: 2020,
      hourlyRate: 8590.0,
      otHourlyRate: 12885.0,
      monthlyStandard: 1795310.0,
      increasePercent: 2.87,
      officialNotice: '고용노동부 고시 제2019-43호',
      descriptionKhmer: 'ឆ្នាំ ២០២០: ៨,៥៩០ វ៉ុន/ម៉ោង (OT: ១២,៨៨៥ វ៉ុន)',
    ),
  };

  /// Returns statutory wage details for a given year.
  /// If year is beyond 2027, project with the latest known statutory standard.
  /// If year is older than 2020, fallback to 2020.
  static StatutoryWageInfo getInfoForYear(int year) {
    if (_ministryRates.containsKey(year)) {
      return _ministryRates[year]!;
    }
    if (year > 2027) {
      final latest = _ministryRates[2027]!;
      return StatutoryWageInfo(
        year: year,
        hourlyRate: latest.hourlyRate,
        otHourlyRate: latest.otHourlyRate,
        monthlyStandard: latest.monthlyStandard,
        increasePercent: 0.0,
        officialNotice: '고용노동부 최저임금 기준',
        descriptionKhmer: 'ឆ្នាំ $year: ${latest.formattedHourly} (អប្បបរមាកូរ៉េ)',
      );
    }
    return _ministryRates[2020]!;
  }

  /// Official statutory hourly wage (₩) for a specific year
  static double getHourlyRate(int year) {
    return getInfoForYear(year).hourlyRate;
  }

  /// Official overtime (OT) rate (1.5x) for a specific year
  static double getOtHourlyRate(int year) {
    return getInfoForYear(year).otHourlyRate;
  }

  /// Official monthly salary equivalent (209 hours)
  static double getMonthlyStandard(int year) {
    return getInfoForYear(year).monthlyStandard;
  }

  /// Available years for selection
  static List<int> get supportedYears =>
      _ministryRates.keys.toList()..sort((a, b) => b.compareTo(a));
}
