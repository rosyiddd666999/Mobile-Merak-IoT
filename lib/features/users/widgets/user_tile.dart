import 'package:flutter/material.dart';
import '../../../core/status_mapper.dart';
import '../../../core/theme.dart';
import '../../../data/models/user.dart';
import '../../../shared/app_card.dart';
import '../../../shared/app_photo.dart';
import '../../../shared/design_kit.dart';

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = user.nama.isNotEmpty ? user.nama.substring(0, 1).toUpperCase() : '?';
    final role = StatusMapper.userRole(user.role);
    return AppRowCard(
      onTap: onTap,
      showChevron: false,
      leading: AppPhotoCircle(
        radius: 24,
        url: user.fotoUrl,
        backgroundColor: AppColors.primary,
        fallback: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      title: user.nama,
      subtitle: user.email,
      meta: StatusChip(label: role.$1, status: role.$2),
    );
  }
}
