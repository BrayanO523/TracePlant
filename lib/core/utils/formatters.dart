import 'package:intl/intl.dart';

class AppFormatters {
  /// Formats a number with commas for thousands and 2 decimal places (e.g., 10,000.00).
  /// Uses the 'en_US' locale pattern implicitly configured or explicitly to ensure standard
  /// comma/dot representation regardless of device locale if we want consistency,
  /// but using the standard NumberFormat behavior.
  static String formatNumber(num? value) {
    if (value == null) return '0.00';
    final formatter = NumberFormat(
      '#,##0.00',
      'en_US',
    ); // Force en_US to get commas for thousands and dots for decimals
    return formatter.format(value);
  }

  /// Formats a number with commas for thousands but NO decimal places (e.g., 10,000).
  static String formatInt(num? value) {
    if (value == null) return '0';
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(value);
  }
}
