import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Format minor currency units (cents) to dollar string representation.
  /// E.g. 2450 -> "$24.50"
  static String formatCents(int cents) {
    final dollars = cents / 100.0;
    return _currencyFormat.format(dollars);
  }

  /// Convert dollar amount to minor currency units (cents).
  static int dollarsToCents(double dollars) {
    return (dollars * 100).round();
  }
}
