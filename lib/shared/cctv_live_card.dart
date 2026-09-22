import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils/date_formatter.dart';
import '../data/providers/api_client_provider.dart';
import '../data/providers/cctv_provider.dart';
import '../data/services/cctv_service.dart';
import '../features/cctv/widgets/cctv_status_badge.dart';
import '../features/cctv/widgets/mjpeg_view.dart';
import '../features/cctv/widgets/snapshot_gallery.dart';

/// Kartu CCTV live reusable (stream MJPEG + badge + pilih feed).
/// Dipakai di tab Inkubator; rute /cctv tetap ada untuk layar penuh.
class CctvLiveCard extends ConsumerStatefulWidget {
  final double height;

  const CctvLiveCard({super.key, this.height = 220});

  @override
  ConsumerState<CctvLiveCard> createState() => _CctvLiveCardState();
}

class _CctvLiveCardState extends ConsumerState<CctvLiveCard> {
  bool _streamFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cctvProvider.notifier).loadCustom();
      ref.read(cctvProvider.notifier).pollHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cctv = ref.watch(cctvProvider);
    final service = CctvService(ref.watch(apiClientProvider));
    final isKandang = cctv.selected == CctvFeed.kandang;
    final bust = cctv.cacheBuster == 0 ? null : cctv.cacheBuster;
    final feedUri = isKandang
        ? service.kandangFeed(
            cacheBuster: bust,
            baseOverride: cctv.effectiveBase,
          )
        : service.incubatorFeed(
            cacheBuster: bust,
            baseOverride: cctv.effectiveBase,
          );

    final apiKey = ref.watch(apiKeyProvider);
    final jwt = ref.watch(jwtTokenProvider);
    final headers = <String, String>{};
    // Sama seperti cctv_screen: jangan kirim kredensial ke host custom eksternal.
    if (!CctvService.isExternalHost(feedUri, AppConstants.cctvBaseUrl)) {
      if (apiKey != null && apiKey.isNotEmpty) headers['X-API-Key'] = apiKey;
      if (jwt != null && jwt.isNotEmpty) headers['Authorization'] = 'Bearer $jwt';
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'CCTV Live',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                CctvStatusBadge(
                  reachable: cctv.reachable,
                  checking: cctv.checking,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Hubungkan Ulang',
                  onPressed: () {
                    setState(() => _streamFailed = false);
                    ref.read(cctvProvider.notifier).reconnect();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  tooltip: 'Layar Penuh',
                  onPressed: () => context.push('/cctv'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CctvFeed>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(
                    value: CctvFeed.inkubator,
                    label: Text('Inkubator'),
                  ),
                  ButtonSegment(
                    value: CctvFeed.kandang,
                    label: Text('Kandang'),
                  ),
                ],
                selected: {cctv.selected},
                onSelectionChanged: (sel) {
                  setState(() => _streamFailed = false);
                  ref.read(cctvProvider.notifier).select(sel.first);
                },
              ),
            ),
          ),
          Container(
            height: widget.height,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            clipBehavior: Clip.antiAlias,
            child: _streamFailed
                ? const Center(
                    child: Text(
                      'Stream terputus — tekan Hubungkan Ulang',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                : MjpegPlayerView(
                    feedUri: feedUri,
                    client: HeaderHttpClient(headers),
                    label: isKandang ? 'KANDANG-CAM-01' : 'INC-CAM-01',
                    onError: () {
                      if (!mounted) return;
                      setState(() => _streamFailed = true);
                      ref.read(cctvProvider.notifier).reportStreamError();
                    },
                  ),
          ),
          const _LatestSnapshotRow(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Baris snapshot terbaru di card: thumbnail + tombol detail + riwayat.
/// Sembunyi total bila kosong/gagal agar card tetap ramping.
class _LatestSnapshotRow extends ConsumerWidget {
  const _LatestSnapshotRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cctvSnapshotsProvider);
    return async.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final snap = items.first;
        final label = snap.capturedAt != null
            ? formatDateTime(snap.capturedAt!.toIso8601String())
            : 'Snapshot terbaru';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showSnapshotViewer(context, snap),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: snap.url,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textMuted),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.bg,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Snapshot Terbaru',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showSnapshotViewer(context, snap),
                child: const Text('Lihat Detail'),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                tooltip: 'Riwayat snapshot',
                onPressed: () => context.push('/cctv'),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
