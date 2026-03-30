import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const _kRates = 's_exchange_rates';
  static const _kRatesDate = 's_exchange_rates_date';

  static Map<String, double> _cachedRates = {};

  /// Get exchange rates with IDR as base. Cached daily.
  static Future<Map<String, double>> getRates() async {
    if (_cachedRates.isNotEmpty) return _cachedRates;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_kRatesDate) ?? '';

    // Use cache if from today
    if (cachedDate == today) {
      final cached = prefs.getString(_kRates);
      if (cached != null && cached.isNotEmpty) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _cachedRates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
        return _cachedRates;
      }
    }

    // Fetch fresh rates
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = (data['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        _cachedRates = rates;
        await prefs.setString(_kRates, jsonEncode(rates));
        await prefs.setString(_kRatesDate, today);
        return rates;
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Fetch error: $e');
    }

    // Return cached even if stale
    final cached = prefs.getString(_kRates);
    if (cached != null && cached.isNotEmpty) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      _cachedRates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    return _cachedRates;
  }

  /// Convert amount from one currency to another.
  static Future<double?> convert(
      double amount, String from, String to) async {
    if (from == to) return amount;
    final rates = await getRates();
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null) return null;
    // Convert via USD: amount / fromRate * toRate
    return amount / fromRate * toRate;
  }

  /// Format a conversion string like "USD 100 ≈ Rp 1.550.000"
  static Future<String?> formatConversion(
      double amount, String from, String to) async {
    final converted = await convert(amount, from, to);
    if (converted == null) return null;
    final rounded = converted.round();
    return '$from ${amount.toStringAsFixed(0)} ≈ $to ${_formatNumber(rounded)}';
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
