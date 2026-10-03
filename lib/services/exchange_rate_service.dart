import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateResult {
  final double krwToKhr;
  final double krwToUsd;
  final DateTime lastUpdated;
  final bool isLive;
  final String? errorMessage;

  ExchangeRateResult({
    required this.krwToKhr,
    required this.krwToUsd,
    required this.lastUpdated,
    required this.isLive,
    this.errorMessage,
  });

  String get formattedKhrRate => krwToKhr.toStringAsFixed(2);
  String get formattedUsdRate => krwToUsd.toStringAsFixed(5);
}

class ExchangeRateService {
  static const String _prefKhrKey = 'pref_krw_to_khr_rate';
  static const String _prefUsdKey = 'pref_krw_to_usd_rate';
  static const String _prefUpdateKey = 'pref_exchange_last_updated';

  static const double defaultKrwToKhr = 3.05;
  static const double defaultKrwToUsd = 0.00075;

  /// Loads cached rates from local storage
  static Future<ExchangeRateResult> getCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final khr = prefs.getDouble(_prefKhrKey) ?? defaultKrwToKhr;
      final usd = prefs.getDouble(_prefUsdKey) ?? defaultKrwToUsd;
      final timeStr = prefs.getString(_prefUpdateKey);
      final dt = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

      return ExchangeRateResult(
        krwToKhr: khr,
        krwToUsd: usd,
        lastUpdated: dt,
        isLive: false,
      );
    } catch (_) {
      return ExchangeRateResult(
        krwToKhr: defaultKrwToKhr,
        krwToUsd: defaultKrwToUsd,
        lastUpdated: DateTime.now(),
        isLive: false,
      );
    }
  }

  /// Fetches live rates from open API with fallback and caching
  static Future<ExchangeRateResult> fetchLiveRates() async {
    // 1. Try Primary Open API: open.er-api.com
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/KRW'))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final rates = data['rates'] as Map<String, dynamic>;
          final khr = (rates['KHR'] as num?)?.toDouble() ?? defaultKrwToKhr;
          final usd = (rates['USD'] as num?)?.toDouble() ?? defaultKrwToUsd;
          final now = DateTime.now();

          await _persistRates(khr, usd, now);

          return ExchangeRateResult(
            krwToKhr: khr,
            krwToUsd: usd,
            lastUpdated: now,
            isLive: true,
          );
        }
      }
    } catch (_) {
      // Continue to secondary fallback
    }

    // 2. Try Secondary Fallback API
    try {
      final res = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/KRW'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['rates'] != null) {
          final rates = data['rates'] as Map<String, dynamic>;
          final khr = (rates['KHR'] as num?)?.toDouble() ?? defaultKrwToKhr;
          final usd = (rates['USD'] as num?)?.toDouble() ?? defaultKrwToUsd;
          final now = DateTime.now();

          await _persistRates(khr, usd, now);

          return ExchangeRateResult(
            krwToKhr: khr,
            krwToUsd: usd,
            lastUpdated: now,
            isLive: true,
          );
        }
      }
    } catch (_) {
      // Fall through to cached rates
    }

    // 3. Fallback to cached or default rates if offline
    final cached = await getCachedRates();
    return ExchangeRateResult(
      krwToKhr: cached.krwToKhr,
      krwToUsd: cached.krwToUsd,
      lastUpdated: cached.lastUpdated,
      isLive: false,
      errorMessage: 'មិនអាចភ្ជាប់បណ្តាញបានទេ (ប្រើប្រាស់ទិន្នន័យចុងក្រោយ)',
    );
  }

  static Future<void> saveManualRates(double khr, double usd) async {
    await _persistRates(khr, usd, DateTime.now());
  }

  static Future<void> _persistRates(double khr, double usd, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKhrKey, khr);
    await prefs.setDouble(_prefUsdKey, usd);
    await prefs.setString(_prefUpdateKey, time.toIso8601String());
  }
}
