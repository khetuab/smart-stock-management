import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
      double amount, {
        String? currencyCode,
        String? locale,
      }) {
    try {
      final format = NumberFormat.currency(
        locale: locale ?? 'en_US',
        symbol: _getCurrencySymbol(currencyCode ?? 'ETB'),
      );
      return format.format(amount);
    } catch (e) {
      return '${_getCurrencySymbol(currencyCode ?? 'ETB')} ${amount.toStringAsFixed(2)}';
    }
  }

  static String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'ETB':
        return 'Br';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      default:
        return code;
    }
  }

  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  static double parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}