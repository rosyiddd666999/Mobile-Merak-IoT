import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/alert.dart';

Color _colorForLevel(String level) {
  switch (level) {
    case 'critical':
      return AppColors.critical;
    case 'warning':
      return AppColors.warning;
    default:
      return AppColors.info;
  }
}

IconData _iconForTipe(String tipe) {
  switch (tipe) {
    case 'suhu':
      return Icons.thermostat;
    case 'kelembapan':
      return Icons.water_drop;
    default:
      return Icons.notifications;
  }
}

class AlertTile extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  const AlertTile({
    super.key,
    required this.alert,
    this.onMarkRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _statusIcon(alert),
      title: Text(alert.pesan, style: TextStyle(fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold)),
      subtitle: Text(alert.createdAt != null ? formatDateTime(alert.createdAt!.toIso8601String()) : '', style: const TextStyle(fontSize: 12)),
      trailing: alert.isRead ? null : IconButton(icon: const Icon(Icons.check_circle_outline, color: AppColors.primary), onPressed: onMarkRead),
    );
  }
}

/// Satu baris grup: pesan pertama + badge "Nx" + waktu terbaru.
/// Expand menampilkan anggota sebagai [AlertTile] biasa + aksi hapus grup.
class AlertGroupTile extends StatelessWidget {
  final List<Alert> members;
  final void Function(Alert alert)? onMarkRead;
  final VoidCallback? onDeleteGroup;

  const AlertGroupTile({
    super.key,
    required this.members,
    this.onMarkRead,
    this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    assert(members.isNotEmpty, 'members tidak boleh kosong');
    final first = members.first;
    final color = _colorForLevel(first.level);
    final anyUnread = members.any((a) => !a.isRead);
    DateTime? newest;
    for (final m in members) {
      final t = m.createdAt;
      if (t != null && (newest == null || t.isAfter(newest))) newest = t;
    }
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(_iconForTipe(first.tipe), color: color, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              first.pesan,
              style: TextStyle(
                fontWeight: anyUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${members.length}x',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        newest != null ? formatDateTime(newest.toIso8601String()) : '',
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        if (onDeleteGroup != null)
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.critical,
            ),
            title: Text('Hapus grup (${members.length})'),
            onTap: onDeleteGroup,
          ),
        for (final m in members)
          AlertTile(
            alert: m,
            onMarkRead: onMarkRead == null ? null : () => onMarkRead!(m),
          ),
      ],
    );
  }
}

Widget _statusIcon(Alert alert) {
  final color = _colorForLevel(alert.level);
  return CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(_iconForTipe(alert.tipe), color: color, size: 20));
}
