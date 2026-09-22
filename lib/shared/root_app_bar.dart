import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../data/providers/alerts_provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/demo_provider.dart';
import 'app_photo.dart';
import 'partner_logos.dart';

/// AppBar untuk 5 rute utama (tab bottom nav): logo mitra diperbesar di
/// kiri (leading) sebagai pengganti judul — + notifikasi & avatar di kanan.
class RootAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const RootAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final demo = ref.watch(demoProvider);
    final alertsAsync = ref.watch(alertsListProvider);
    final unread = demo.active
        ? demo.alerts.where((a) => !a.isRead).length
        : alertsAsync.maybeWhen(
            data: (list) => list.where((a) => !a.isRead).length,
            orElse: () => 0,
          );
    final nama = user?.nama ?? 'Pengguna';
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      leadingWidth: 186,
      leading: Center(child: PartnerLogos(size: 38, wide: true)),
      title: null,
      actions: [
        ...?actions,
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifikasi',
              onPressed: () => context.push('/alerts'),
            ),
            if (unread > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusAlert,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/profile'),
            child: AppPhotoCircle(
              key: ValueKey(user?.fotoUrl),
              radius: 16,
              url: user?.fotoUrl,
              backgroundColor: AppColors.primaryTeal,
              fallback: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
