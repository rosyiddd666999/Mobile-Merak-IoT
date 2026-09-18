import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/alert.dart';

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
      leading: _statusIcon(),
      title: Text(alert.pesan, style: TextStyle(fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold)),
      subtitle: Text(alert.createdAt != null ? formatDateTime(alert.createdAt!.toIso8601String()) : '', style: const TextStyle(fontSize: 12)),
      trailing: alert.isRead ? null : IconButton(icon: const Icon(Icons.check_circle_outline, color: AppColors.primary), onPressed: onMarkRead),
    );
  }

  Widget _statusIcon() {
    Color color;
    switch (alert.level) {
      case 'critical':
        color = AppColors.critical;
        break;
      case 'warning':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.info;
    }
    return CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(_tipeIcon, color: color, size: 20));
  }

  IconData get _tipeIcon {
    switch (alert.tipe) {
      case 'suhu':
        return Icons.thermostat;
      case 'kelembapan':
        return Icons.water_drop;
      default:
        return Icons.notifications;
    }
  }
}
