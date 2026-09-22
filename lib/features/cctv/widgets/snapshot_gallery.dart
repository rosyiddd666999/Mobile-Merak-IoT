import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/cctv_snapshot.dart';
import '../../../data/providers/cctv_provider.dart';
import '../../../shared/design_kit.dart';
import '../../../shared/error_widget.dart';
import '../../../shared/loading_widget.dart';
import '../../../core/utils/api_error.dart';

/// Galeri riwayat snapshot CCTV (`GET /api/cctv-snapshots`).
/// Tap thumbnail -> viewer fullscreen (dialog geser).
class SnapshotGallery extends ConsumerWidget {
  const SnapshotGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cctvSnapshotsProvider);
    return async.when(
      loading: () => const LoadingWidget(message: 'Memuat snapshot...'),
      error: (e, _) => AppErrorWidget(
        message: friendlyApiError(e),
        onRetry: () => ref.invalidate(cctvSnapshotsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.photo_library_outlined,
            message: 'Belum ada snapshot.',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _thumb(context, items[i]),
        );
      },
    );
  }

  Widget _thumb(BuildContext context, CctvSnapshot snap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openViewer(context, snap),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: snap.url,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
          ),
          errorWidget: (_, _, _) => Container(
            color: AppColors.bg,
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, CctvSnapshot snap) =>
      showSnapshotViewer(context, snap);
}

/// Dialog detail gambar snapshot: pratinjau + metadata (waktu, sumber, ID).
/// Dipakai galeri dan card CCTV Live.
void showSnapshotViewer(BuildContext context, CctvSnapshot snap) {
  final label = snap.capturedAt != null
      ? formatDateTime(snap.capturedAt!.toIso8601String())
      : '-';
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: snap.url,
              fit: BoxFit.contain,
              placeholder: (_, _) => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaRow('Waktu', label),
                _metaRow('Sumber', snap.source ?? '-'),
                _metaRow('ID', '#${snap.id}'),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _metaRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
      ],
    ),
  );
}
