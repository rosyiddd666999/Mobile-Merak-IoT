import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/rotation_log.dart';

class RotationLogList extends StatelessWidget {
  final List<RotationLog> logs;

  const RotationLogList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('Belum ada log rotasi'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (_, i) {
        final log = logs[i];
        final sukses = log.status == 'sukses';
        return ListTile(
          leading: Icon(sukses ? Icons.check_circle : Icons.cancel, color: sukses ? AppColors.success : AppColors.critical),
          title: Text(formatDateTime(log.timestamp), style: const TextStyle(fontSize: 14)),
          subtitle: log.catatan != null ? Text(log.catatan!, style: const TextStyle(fontSize: 12)) : null,
          trailing: Text(sukses ? 'Sukses' : 'Gagal', style: TextStyle(color: sukses ? AppColors.success : AppColors.critical, fontWeight: FontWeight.w600)),
        );
      },
    );
  }
}
