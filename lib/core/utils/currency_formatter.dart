import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat('#,###', 'id_ID');

  /// Formats an integer amount to "Rp 10.000" style.
  static String formatRupiah(int amount) {
    final formatted = _formatter.format(amount);
    return 'Rp $formatted';
  }

  /// Parses "Rp 10.000" or "10.000" back to int.
  /// Returns 0 if parsing fails.
  static int parseRupiah(String text) {
    final cleaned = text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return int.tryParse(cleaned) ?? 0;
  }
}
