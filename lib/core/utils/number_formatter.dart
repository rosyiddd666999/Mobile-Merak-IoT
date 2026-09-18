import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(amount);
}

String formatNumber(dynamic number) {
  return NumberFormat('#,##0').format(number);
}

/// Ringkas: 1500 -> 1,5rb · 2.500.000 -> 2,5jt (DESIGN.md: value besar ringkas).
String formatCompact(num number) {
  final abs = number.abs();
  if (abs >= 1000000000) {
    return '${_trim(number / 1000000000)}M';
  } else if (abs >= 1000000) {
    return '${_trim(number / 1000000)}jt';
  } else if (abs >= 1000) {
    return '${_trim(number / 1000)}rb';
  }
  return formatNumber(number);
}

String _trim(num v) {
  final s = v.toStringAsFixed(1).replaceAll('.', ',');
  return s.endsWith(',0') ? s.substring(0, s.length - 2) : s;
}
