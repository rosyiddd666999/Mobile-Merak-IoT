import 'package:intl/intl.dart';

String formatDate(String dateStr) {
  final dt = DateTime.tryParse(dateStr);
  if (dt == null) return dateStr;
  return DateFormat('dd MMM yyyy').format(dt);
}

String formatDateTime(String dateStr) {
  final dt = DateTime.tryParse(dateStr);
  if (dt == null) return dateStr;
  return DateFormat('dd MMM yyyy HH:mm').format(dt);
}

String timeAgo(String dateStr) {
  final dt = DateTime.tryParse(dateStr);
  if (dt == null) return dateStr;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes}m lalu';
  if (diff.inDays < 1) return '${diff.inHours}j lalu';
  return '${diff.inDays}h lalu';
}

/// Label rotasi terakhir: presisi menit di bawah 24 jam, relatif di bawah
/// 7 hari, lalu tanggal; raw bila tak terparse; "-" bila kosong.
String rotationLabel(DateTime? t, String? raw) {
  if (t == null) {
    if (raw != null && raw.isNotEmpty) return raw;
    return '-';
  }
  final diff = DateTime.now().difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) {
    final rest = diff.inMinutes % 60;
    if (rest == 0) return '${diff.inHours} jam lalu';
    return '${diff.inHours} jam $rest mnt lalu';
  }
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(t.toIso8601String());
}
