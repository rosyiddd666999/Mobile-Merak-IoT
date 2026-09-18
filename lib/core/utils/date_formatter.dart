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
