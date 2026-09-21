import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/app_photo.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/api_key_settings.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPemilik = user?.role == 'pemilik';
    final canEdit = isPemilik || user?.role == 'staff';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppPhotoCircle(
                    radius: 28,
                    url: user?.fotoUrl,
                    backgroundColor: AppColors.primaryTeal,
                    fallback: const Icon(Icons.person, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.nama ?? 'Pengguna', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Chip(label: Text(user?.role ?? '', style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const ApiKeySettings(),
          const SizedBox(height: 16),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  ListTile(
                    leading: const Icon(Icons.thermostat, color: AppColors.primary),
                    title: const Text('Pengaturan Inkubator'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/incubator/settings'),
                  ),
                if (isPemilik)
                  ListTile(
                    leading: const Icon(Icons.people, color: AppColors.primary),
                    title: const Text('Pengaturan Pengguna'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/users'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.critical),
              title: const Text('Keluar', style: TextStyle(color: AppColors.critical)),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}
