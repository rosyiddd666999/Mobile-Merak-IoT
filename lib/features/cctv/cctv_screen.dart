import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/providers/api_client_provider.dart';
import '../../data/providers/cctv_provider.dart';
import '../../data/services/cctv_service.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/cctv_error_view.dart';
import 'widgets/cctv_status_badge.dart';
import 'widgets/mjpeg_view.dart';

/// 2 feed MJPEG + health polling tiap 8 dtk (MOBILE.md §6.19/§7.5, cctv.md).
/// Sumber: gateway RTSP->MJPEG; override `?url=` opsional (default .env).
class CctvScreen extends ConsumerStatefulWidget {
  const CctvScreen({super.key});

  @override
  ConsumerState<CctvScreen> createState() => _CctvScreenState();
}

class _CctvScreenState extends ConsumerState<CctvScreen> {
  Timer? _pollTimer;
  bool _streamFailed = false;
  final _baseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cctvProvider.notifier).loadCustom();
      ref.read(cctvProvider.notifier).pollHealth();
      _pollTimer?.cancel();
      // Health polling tiap 8 detik (pola CctvPage.jsx).
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) ref.read(cctvProvider.notifier).pollHealth();
      });
    });
  }

  @override
  void dispose() {
    // Pause stream saat screen di-background/dispose (MOBILE.md §6.19.7).
    _pollTimer?.cancel();
    _baseController.dispose();
    super.dispose();
  }

  void _showSettingsDialog(CctvState cctv) {
    _baseController.text = cctv.customBase ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan CCTV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Host CCTV (kosong = CCTV_BASE_URL)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _baseController,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hanya HTTPS publik. Token TIDAK dikirim ke host custom yang belum terverifikasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Target kamera diatur di env gateway server, bukan dari app.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(cctvProvider.notifier).saveBase(_baseController.text);
              if (!ctx.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Host ditolak: wajib https:// publik, tanpa IP lokal/query.'),
                  ),
                );
                return;
              }
              setState(() => _streamFailed = false);
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cctv = ref.watch(cctvProvider);
    final service = CctvService(ref.watch(apiClientProvider));
    final isKandang = cctv.selected == CctvFeed.kandang;
    final baseOverride = cctv.effectiveBase;
    final bust = cctv.cacheBuster == 0 ? null : cctv.cacheBuster;
    final feedUri = isKandang
        ? service.kandangFeed(cacheBuster: bust, baseOverride: baseOverride)
        : service.incubatorFeed(cacheBuster: bust, baseOverride: baseOverride);
    final label = isKandang ? 'KANDANG-CAM-01' : 'INC-CAM-01';
    final rest = isKandang ? '/kandang_feed' : '/video_feed';

    // Overlay hanya saat PLAYER gagal — health gagal cukup badge + retry.
    final showError = _streamFailed;

    // Header auth untuk MJPEG (MOBILE.md §6.19.6).
    // Jangan kirim kredensial ke host custom eksternal yang belum terverifikasi.
    final apiKey = ref.watch(apiKeyProvider);
    final jwt = ref.watch(jwtTokenProvider);
    final headers = <String, String>{};
    final trustedBase = AppConstants.cctvBaseUrl;
    final isExternal = CctvService.isExternalHost(feedUri, trustedBase);
    if (!isExternal) {
      if (apiKey != null && apiKey.isNotEmpty) headers['X-API-Key'] = apiKey;
      if (jwt != null && jwt.isNotEmpty) headers['Authorization'] = 'Bearer $jwt';
    }

    return Scaffold(
      appBar: DetailAppBar(
        title: 'CCTV',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan CCTV',
            onPressed: () => _showSettingsDialog(cctv),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Hubungkan Ulang',
            onPressed: () {
              setState(() => _streamFailed = false);
              ref.read(cctvProvider.notifier).reconnect();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<CctvFeed>(
                    segments: const [
                      ButtonSegment(value: CctvFeed.inkubator, label: Text('Inkubator')),
                      ButtonSegment(value: CctvFeed.kandang, label: Text('Kandang')),
                    ],
                    selected: {cctv.selected},
                    onSelectionChanged: (sel) {
                      setState(() => _streamFailed = false);
                      ref.read(cctvProvider.notifier).select(sel.first);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                CctvStatusBadge(reachable: cctv.reachable, checking: cctv.checking),
              ],
            ),
          ),
          if (cctv.error != null && !_streamFailed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cctv.lastStatusCode != null ? '${cctv.error} (${cctv.lastStatusCode})' : cctv.error!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          if (isExternal)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Host custom terdeteksi — mode tanpa token (auth tidak dikirim).',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          if (cctv.reachable == false && !_streamFailed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kamera standby — cek relay/ESP32 di server. Frame diagnostik tetap tampil bila gateway online.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MjpegPlayerView(
                          feedUri: feedUri,
                          client: headers.isEmpty ? null : HeaderHttpClient(headers),
                          label: label,
                          onError: () {
                            if (mounted) setState(() => _streamFailed = true);
                            ref.read(cctvProvider.notifier).reportStreamError();
                          },
                        ),
                        if (showError)
                          Container(
                            color: Colors.black.withValues(alpha: 0.72),
                            child: CctvErrorView(
                              message: 'Stream tidak tersedia. Kamera standby atau gateway offline.',
                              onRetry: () {
                                setState(() => _streamFailed = false);
                                ref.read(cctvProvider.notifier).reconnect();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // Masked: query url (RTSP + password) tidak pernah tampil.
                    '${CctvService.safeFeedLabel(feedUri)} · REST: $rest',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => ref.read(cctvProvider.notifier).pollHealth(),
                  child: const Text(
                    'Cek ulang',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
