import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/app_failure.dart';
import '../../core/theme.dart';
import '../../data/providers/api_client_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/users_provider.dart';
import '../../data/services/upload_service.dart';
import '../../shared/app_photo.dart';
import '../../shared/app_photo_picker.dart';
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
                  Stack(
                    children: [
                      AppPhotoCircle(
                        radius: 28,
                        url: user?.fotoUrl,
                        backgroundColor: AppColors.primaryTeal,
                        fallback: const Icon(Icons.person, size: 28),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () => _editPhoto(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.darkCard,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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

  /// Ubah foto profil: picker (galeri/kamera) -> upload -> PUT.
  /// Backend membatasi PUT users untuk pemilik — staff mendapat pesan jelas.
  Future<void> _editPhoto(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    PickedPhoto? picked;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPhotoPicker(
              label: 'Foto Profil',
              initialUrl: me.fotoUrl,
              folder: UploadFolder.profile,
              onChanged: (p) => picked = p,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Simpan Foto'),
              ),
            ),
          ],
        ),
      ),
    );
    if (save != true || picked == null || !context.mounted) return;

    String? fotoUrl = picked!.url;
    if (picked!.file != null) {
      try {
        final up = await UploadService(ref.read(apiClientProvider))
            .uploadPhoto(picked!.file!, UploadFolder.profile);
        fotoUrl = up.url;
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload foto gagal: ${AppFailure.from(e, action: 'mengunggah foto').message}')),
        );
        return;
      }
    }

    final updated = await ref
        .read(userUpdateProvider.notifier)
        .updateUser(id: me.id, fotoUrl: fotoUrl ?? '');
    if (!context.mounted) return;
    if (updated == null) {
      final err = ref.read(userUpdateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null
              ? AppFailure.from(err, action: 'mengubah foto profil').message
              : 'Gagal mengubah foto profil'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }
    // Respons PUT tak selalu bawa avatar — pertahankan URL terkirim bila
    // respons miskin field; dukung pengosongan eksplisit via konstruktor.
    final User merged;
    if (updated.fotoUrl?.isNotEmpty == true) {
      merged = updated;
    } else if (fotoUrl?.isNotEmpty == true) {
      merged = updated.copyWith(fotoUrl: fotoUrl);
    } else {
      merged = User(
        id: updated.id,
        email: updated.email,
        nama: updated.nama,
        role: updated.role,
        createdAt: updated.createdAt,
      );
    }
    ref.read(currentUserProvider.notifier).state = merged;
    ref.invalidate(usersListProvider);
    ref.read(userUpdateProvider.notifier).reset();

    // Bersihkan file lama bila diganti (BACKEND.md §13.3).
    final oldKey = UploadService.objectKeyFromUrl(me.fotoUrl);
    if (oldKey != null &&
        oldKey.isNotEmpty &&
        me.fotoUrl != updated.fotoUrl) {
      UploadService(ref.read(apiClientProvider)).deletePhoto(oldKey);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto profil diperbarui')),
    );
  }
}
