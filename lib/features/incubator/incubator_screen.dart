import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/chick.dart';
import '../../data/models/egg.dart';
import '../../data/models/incubator_status.dart';
import '../../data/models/telemetry_log.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/demo_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/providers/incubator_provider.dart';
import '../../data/providers/mqtt_provider.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/root_app_bar.dart';
import '../../shared/demo_banner.dart';
import '../../shared/cctv_live_card.dart';
import 'widgets/telemetry_chart.dart';

/// Inkubator — tab monitoring IoT (DESIGN.md §3): satu scroll menyatu.
class IncubatorScreen extends ConsumerWidget {
  const IncubatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoProvider);
    final mqtt = ref.watch(mqttProvider);
    final statusAsync = ref.watch(incubatorStatusProvider);
    final rotationAsync = ref.watch(rotationLogsProvider);
    final logsAsync = ref.watch(incubatorStatusHistoryProvider);
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = user?.role == 'pemilik' || user?.role == 'staff';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttProvider.notifier).connectIfNeeded();
    });

    IncubatorStatus? effective;
    if (demo.active) {
      effective = demo.status;
    } else if (mqtt.hasTelemetry) {
      effective = IncubatorStatus(
        id: 0,
        suhuSekarang: mqtt.temperature!,
        kelembapanSekarang: mqtt.humidity!,
        lampuStatus: mqtt.statusLamp ?? 'OFF',
      );
    } else {
      effective = statusAsync.valueOrNull;
    }

    // Rotasi terakhir: field status dulu, fallback entri "sukses" terbaru
    // dari riwayat (kontrak backend: status log "sukses"/"gagal", case-insensitive).
    DateTime? lastRotation = effective?.terakhirRotasi;
    String? lastRotationRaw;
    if (lastRotation == null) {
      final rotations = rotationAsync.valueOrNull;
      if (rotations != null && rotations.isNotEmpty) {
        final sukses = rotations
            .where((r) => r.status.trim().toLowerCase() == 'sukses')
            .toList();
        DateTime? latest;
        String? latestRaw;
        for (final r in sukses) {
          final t = DateTime.tryParse(r.timestamp);
          if (t != null) {
            if (latest == null || t.isAfter(latest)) {
              latest = t;
              latestRaw = null;
            }
          } else if (latest == null &&
              latestRaw == null &&
              r.timestamp.isNotEmpty) {
            // Tak terparse: tampilkan raw apa adanya daripada "-".
            latestRaw = r.timestamp;
          }
        }
        lastRotation = latest;
        lastRotationRaw = latest == null ? latestRaw : null;
      }
    }

    // Menangkan yang terbaru: picu manual lokal mengalahkan nilai basi
    // dari tabel status/log (keduanya hanya berubah bila ada yang menulis).
    if (!demo.active) {
      final manual = mqtt.lastManualRotation;
      if (manual != null &&
          (lastRotation == null || manual.isAfter(lastRotation))) {
        lastRotation = manual;
        lastRotationRaw = null;
      }
    }

    return Scaffold(
      appBar: RootAppBar(
        title: 'Inkubator',
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Pengaturan',
              onPressed: () => context.push('/incubator/settings'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          unawaited(ref.read(mqttProvider.notifier).refreshConnection());
          ref.invalidate(incubatorStatusProvider);
          ref.invalidate(rotationLogsProvider);
          ref.invalidate(incubatorStatusHistoryProvider);
          ref.invalidate(eggsListProvider);
          ref.invalidate(chicksListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const DemoBanner(),
            _HeaderStats(status: effective),
            const SizedBox(height: 16),
            _BioDomeHero(
              status: effective,
              isLive: mqtt.hasTelemetry && !demo.active,
              lastRotation: lastRotation,
              lastRotationRaw: lastRotationRaw,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Fase Embrio'),
            const SizedBox(height: 12),
            _EmbryoCard(eggsAsync: eggsAsync),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Kontrol Telemetri'),
            const SizedBox(height: 12),
            _TelemetryControls(
              mqttLamp: mqtt.statusLamp,
              mqttMist: mqtt.statusMist,
              mqttMotor: mqtt.statusMotor,
              mqttLive: mqtt.isLive,
              canControl: canEdit,
              demoActive: demo.active,
              lastRotation: lastRotation,
              lastRotationRaw: lastRotationRaw,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Grafik'),
            const SizedBox(height: 12),
            _ChartCard(logsAsync: logsAsync),
            const SizedBox(height: 20),
            const SectionHeader(title: 'CCTV Live'),
            const SizedBox(height: 12),
            const CctvLiveCard(),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Log Penetasan',
              trailing: 'Lihat semua',
            ),
            const SizedBox(height: 12),
            _HatchLog(chicksAsync: chicksAsync),
            const SizedBox(height: 12),
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () => context.push('/eggs/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Catat Telur'),
              ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Kesiapan Brooder'),
            const SizedBox(height: 12),
            _BrooderCard(status: effective),
          ],
        ),
      ),
    );
  }
}

/// Header stat row — 3 kolom card tipis (DESIGN.md §3.1).
class _HeaderStats extends StatelessWidget {
  final IncubatorStatus? status;

  const _HeaderStats({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Mini(
          icon: Icons.thermostat,
          value: status != null
              ? '${status!.suhuSekarang.toStringAsFixed(1)}°'
              : '-',
          label: 'Suhu',
        ),
        const SizedBox(width: 8),
        _Mini(
          icon: Icons.water_drop,
          value: status != null
              ? '${status!.kelembapanSekarang.toStringAsFixed(0)}%'
              : '-',
          label: 'Lembap',
        ),
        const SizedBox(width: 8),
        _Mini(
          icon: Icons.lightbulb,
          value: status != null ? status!.lampuStatus : '-',
          label: 'Lampu',
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Mini({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: const Color(0xFFE6ECEA)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bio-Dome hero: 1 card menyatu, overlay stat semi-transparan (DESIGN.md §3.2).
class _BioDomeHero extends StatelessWidget {
  final IncubatorStatus? status;
  final bool isLive;
  final DateTime? lastRotation;
  final String? lastRotationRaw;

  const _BioDomeHero({
    required this.status,
    required this.isLive,
    this.lastRotation,
    this.lastRotationRaw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bio-Dome Inkubator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                StatusChip(
                  label: isLive
                      ? 'Live'
                      : (status != null ? 'Data Terakhir' : 'Offline'),
                  status: isLive
                      ? AppStatus.active
                      : (status != null
                            ? AppStatus.pending
                            : AppStatus.neutral),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OverlayStat(
                  'Suhu',
                  status != null
                      ? '${status!.suhuSekarang.toStringAsFixed(1)}°C'
                      : '-',
                ),
                _OverlayStat(
                  'Lembap',
                  status != null
                      ? '${status!.kelembapanSekarang.toStringAsFixed(0)}%'
                      : '-',
                ),
                _OverlayStat('Lampu', status?.lampuStatus ?? '-'),
                _OverlayStat(
                  'Rotasi',
                  _rotationLabel(lastRotation, lastRotationRaw),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayStat extends StatelessWidget {
  final String label;
  final String value;

  const _OverlayStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

/// Label rotasi terakhir: presisi menit di bawah 24 jam, relatif di bawah
/// 7 hari, lalu tanggal; raw bila tak terparse; "-" bila kosong.
String _rotationLabel(DateTime? t, String? raw) {
  if (t == null) {
    if (raw != null && raw.isNotEmpty) return raw;
    return '-';
  }
  final diff = DateTime.now().difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) {
    final rest = diff.inMinutes % 60;
    if (rest == 0) return '${diff.inHours} jam lalu';
    return '${diff.inHours} jam $rest mnt lalu';
  }
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatDate(t.toIso8601String());
}

/// Fase embrio + candling dalam 1 card (DESIGN.md §3.3-3.4).
class _EmbryoCard extends StatelessWidget {
  final AsyncValue<List<Egg>> eggsAsync;

  const _EmbryoCard({required this.eggsAsync});

  @override
  Widget build(BuildContext context) {
    final activeCount = eggsAsync.maybeWhen(
      data: (eggs) =>
          eggs.where((e) => e.akhir.toLowerCase() == 'proses').length,
      orElse: () => null,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 0.64,
                    strokeWidth: 8,
                    backgroundColor: AppColors.primaryTeal.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryTeal,
                    ),
                  ),
                  const Center(
                    child: Text(
                      '18/28',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fase Pertumbuhan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeCount != null
                        ? '$activeCount telur dalam proses'
                        : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.statusActive,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Candling: -',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
}

/// Kontrol inkubator — 60% bg, 30% kartu putih, 10% aksen teal (DESIGN.md §1).
/// Lampu = segmented langsung kirim; Rotasi = tombol primer; Mist = tombol
/// outlined (mist ±10 dtk, firmware mendukung TRIGGER). Nilai optimistis
/// ditampilkan hingga telemetri nyata mengonfirmasi.
class _TelemetryControls extends ConsumerStatefulWidget {
  final String? mqttLamp;
  final String? mqttMist;
  final String? mqttMotor;
  final bool mqttLive;
  final bool canControl;
  final bool demoActive;
  final DateTime? lastRotation;
  final String? lastRotationRaw;

  const _TelemetryControls({
    this.mqttLamp,
    this.mqttMist,
    this.mqttMotor,
    required this.mqttLive,
    required this.canControl,
    this.demoActive = false,
    this.lastRotation,
    this.lastRotationRaw,
  });

  @override
  ConsumerState<_TelemetryControls> createState() => _TelemetryControlsState();
}

class _TelemetryControlsState extends ConsumerState<_TelemetryControls> {
  /// Perintah lampu yang sedang dikirim (optimistis).
  LampMode? _pendingLamp;

  /// Trigger motor sedang dikirim.
  bool _pendingMotor = false;

  /// Trigger mist sedang dikirim.
  bool _pendingMist = false;

  Timer? _pendingTimer;

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  /// Selalu bisa diklik selama boleh kontrol & bukan demo — walau MQTT
  /// masih menghubungkan. Pengiriman yang gagal memicu reconnect + snackbar.
  bool get _tappable => widget.canControl && !widget.demoActive;

  void _clearPending() {
    _pendingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _pendingLamp = null;
      _pendingMotor = false;
      _pendingMist = false;
    });
  }

  void _pendingTimeout() {
    _pendingTimer?.cancel();
    // Beri firmware 10 dtk untuk mempublish status baru, lalu kembalikan
    // ke nilai nyata (sukses diam-diam atau gagal).
    _pendingTimer = Timer(const Duration(seconds: 10), _clearPending);
  }

  @override
  Widget build(BuildContext context) {
    // Konfirmasi optimistis per perintah: status nyata yang cocok
    // membersihkan flag-nya masing-masing (tidak saling menimpa).
    final lampConfirmed =
        _pendingLamp != null &&
        ((_pendingLamp == LampMode.on && widget.mqttLamp == 'ON') ||
            (_pendingLamp == LampMode.off && widget.mqttLamp == 'OFF') ||
            (_pendingLamp == LampMode.auto && widget.mqttLamp != null));
    final motorConfirmed = _pendingMotor && widget.mqttMotor == 'ON';
    final mistConfirmed = _pendingMist && widget.mqttMist == 'ON';
    if (lampConfirmed || motorConfirmed || mistConfirmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (lampConfirmed) _pendingLamp = null;
          if (motorConfirmed) _pendingMotor = false;
          if (mistConfirmed) _pendingMist = false;
        });
        if (_pendingLamp == null && !_pendingMotor && !_pendingMist) {
          _pendingTimer?.cancel();
        }
      });
    }

    // Tampilan optimistis selama loading.
    String? lampShown = widget.mqttLamp;
    if (_pendingLamp != null && !lampConfirmed) {
      lampShown = _pendingLamp == LampMode.on
          ? 'ON'
          : _pendingLamp == LampMode.off
          ? 'OFF'
          : widget.mqttLamp;
    }
    final loading = _pendingLamp != null || _pendingMotor || _pendingMist;

    final lastLabel = _rotationLabel(
      widget.lastRotation,
      widget.lastRotationRaw,
    );
    final rotationInfo = lastLabel == '-'
        ? 'Otomatis tiap 4 jam'
        : 'Otomatis tiap 4 jam';

    final String? reason = !widget.canControl
        ? 'Login sebagai pemilik/staff untuk mengendalikan.'
        : widget.demoActive
        ? 'Mode demo aktif — kontrol dinonaktifkan.'
        : (!widget.mqttLive ? 'Menghubungkan MQTT...' : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LampCard(
          lampShown: lampShown,
          selected: _pendingLamp ?? _lampSelection(lampShown),
          loading: _pendingLamp != null && !lampConfirmed,
          enabled: _tappable,
          onSelect: (mode) {
            setState(() => _pendingLamp = mode);
            _pendingTimeout();
            _send(ref.read(mqttProvider.notifier).sendLampMode(mode));
          },
        ),
        const SizedBox(height: 12),
        _TriggerCard(
          icon: Icons.cached,
          title: 'Rotasi Rak',
          statusLabel: (_pendingMotor && !motorConfirmed)
              ? 'Memutar…'
              : (widget.mqttMotor ?? '-'),
          statusActive:
              widget.mqttMotor == 'ON' || (_pendingMotor && !motorConfirmed),
          loading: _pendingMotor && !motorConfirmed,
          info: rotationInfo,
          buttonLabel: 'Putar Sekarang',
          primary: true,
          enabled: _tappable,
          onAction: () => _confirm(
            title: 'Putar rak?',
            body: 'Motor berjalan ±30 detik.',
            onConfirm: () {
              setState(() => _pendingMotor = true);
              _pendingTimeout();
              final sent = ref.read(mqttProvider.notifier).triggerMotor();
              if (sent) {
                unawaited(
                  ref.read(mqttProvider.notifier).recordManualRotation(),
                );
              }
              _send(sent);
            },
          ),
        ),
        const SizedBox(height: 12),
        _TriggerCard(
          icon: Icons.air,
          title: 'Mist Maker',
          statusLabel: (_pendingMist && !mistConfirmed)
              ? 'Menyala…'
              : (widget.mqttMist ?? '-'),
          statusActive:
              widget.mqttMist == 'ON' || (_pendingMist && !mistConfirmed),
          loading: _pendingMist && !mistConfirmed,
          info: 'Otomatis saat kelembapan rendah · manual ±10 detik',
          buttonLabel: 'Nyalakan',
          primary: false,
          enabled: _tappable,
          onAction: () => _confirm(
            title: 'Nyalakan mist?',
            body: 'Mist maker berjalan ±10 detik.',
            onConfirm: () {
              setState(() => _pendingMist = true);
              _pendingTimeout();
              _send(ref.read(mqttProvider.notifier).triggerMist());
            },
          ),
        ),
        const SizedBox(height: 12),
        const _AutoRotationCard(),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              loading ? 'Mengirim perintah...' : reason,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Mengirim perintah...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  void _send(bool sent) {
    if (!mounted) return;
    if (sent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perintah terkirim')));
      return;
    }
    // Kirim gagal (socket down): bersihkan loading, picu reconnect.
    _clearPending();
    ref.read(mqttProvider.notifier).reconnect();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menghubungkan ulang MQTT, coba lagi sebentar'),
      ),
    );
  }

  void _confirm({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  LampMode _lampSelection(String? lampShown) {
    switch (lampShown) {
      case 'ON':
        return LampMode.on;
      case 'OFF':
        return LampMode.off;
      default:
        return LampMode.auto;
    }
  }
}

/// Kartu info rotasi otomatis firmware (MOTOR_AUTO_INTERVAL tiap 4 jam).
/// Anchor jadwal berikut: [lastManualRotation] dulu, fallback
/// [lastTelemetryAt]; '-' bila tak ada data. Hitung mundur refresh
/// tiap 30 detik. Tombol manual ada di kartu "Rotasi Rak" (tak diubah).
class _AutoRotationCard extends ConsumerStatefulWidget {
  const _AutoRotationCard();

  @override
  ConsumerState<_AutoRotationCard> createState() => _AutoRotationCardState();
}

class _AutoRotationCardState extends ConsumerState<_AutoRotationCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _countdown(DateTime anchor) {
    final next = anchor.add(const Duration(hours: 4));
    final rem = next.difference(DateTime.now());
    if (rem.isNegative || rem.inSeconds < 30) return 'segera';
    if (rem.inHours >= 1) {
      final rest = rem.inMinutes % 60;
      if (rest == 0) return '${rem.inHours} jam lagi';
      return '${rem.inHours} jam $rest mnt lagi';
    }
    if (rem.inMinutes >= 1) return '${rem.inMinutes} mnt lagi';
    return '${rem.inSeconds} dtk lagi';
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = ref.watch(mqttProvider);
    final anchor = mqtt.lastManualRotation ?? mqtt.lastTelemetryAt;
    final label = anchor == null ? '-' : _countdown(anchor);
    return _ControlCard(
      icon: Icons.autorenew,
      title: 'Rotasi Otomatis',
      statusLabel: label,
      statusActive: anchor != null,
      loading: false,
      child: const Text(
        'Rak berputar otomatis tiap 4 jam (firmware)',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}

/// Cangkang kartu kontrol: header (ikon + judul + chip status) + isi.
/// Putih 30% di atas bg 60%, aksen teal 10% hanya di status/aksi aktif.
class _ControlCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusLabel;
  final bool statusActive;
  final bool loading;
  final Widget child;

  const _ControlCard({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.statusActive,
    required this.loading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: statusActive
                      ? AppColors.statusActive
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  StatusChip(
                    label: statusLabel,
                    status: statusActive ? AppStatus.active : AppStatus.neutral,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Kartu Lampu: segmented Otomatis/Nyala/Mati, kirim langsung tanpa dialog.
class _LampCard extends StatelessWidget {
  final String? lampShown;
  final LampMode selected;
  final bool loading;
  final bool enabled;
  final ValueChanged<LampMode> onSelect;

  const _LampCard({
    required this.lampShown,
    required this.selected,
    required this.loading,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      icon: Icons.lightbulb_outline,
      title: 'Lampu',
      statusLabel: loading ? 'Mengirim…' : (lampShown ?? '-'),
      statusActive: lampShown == 'ON',
      loading: loading,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<LampMode>(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
          ),
          segments: const [
            ButtonSegment(value: LampMode.auto, label: Text('Otomatis')),
            ButtonSegment(value: LampMode.on, label: Text('Nyala')),
            ButtonSegment(value: LampMode.off, label: Text('Mati')),
          ],
          selected: {selected},
          onSelectionChanged: enabled ? (sel) => onSelect(sel.first) : null,
        ),
      ),
    );
  }
}

/// Kartu pemicu sekali jalan (Rotasi primer, Mist outlined).
class _TriggerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusLabel;
  final bool statusActive;
  final bool loading;
  final String info;
  final String buttonLabel;
  final bool primary;
  final bool enabled;
  final VoidCallback onAction;

  const _TriggerCard({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.statusActive,
    required this.loading,
    required this.info,
    required this.buttonLabel,
    required this.primary,
    required this.enabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final Widget leading = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18);
    final label = Text(loading ? 'Mengirim…' : buttonLabel);
    return _ControlCard(
      icon: icon,
      title: title,
      statusLabel: statusLabel,
      statusActive: statusActive,
      loading: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            info,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (primary)
            ElevatedButton.icon(
              onPressed: enabled && !loading ? onAction : null,
              icon: leading,
              label: label,
            )
          else
            OutlinedButton.icon(
              onPressed: enabled && !loading ? onAction : null,
              icon: leading,
              label: label,
            ),
        ],
      ),
    );
  }
}

enum _ChartMode { suhu, kelembapan }

/// Satu kartu grafik dengan toggle Suhu | Kelembapan + chip sumber
/// (Riwayat server vs Live MQTT).
class _ChartCard extends ConsumerStatefulWidget {
  final AsyncValue<List<TelemetryLog>> logsAsync;

  const _ChartCard({required this.logsAsync});

  @override
  ConsumerState<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends ConsumerState<_ChartCard> {
  _ChartMode _mode = _ChartMode.suhu;

  @override
  Widget build(BuildContext context) {
    // Fallback Jalur B: bila riwayat server kosong, pakai buffer live
    // 24 titik dari MQTT (hilang saat restart, tergantikan otomatis
    // begitu endpoint history backend hidup).
    final mqtt = ref.watch(mqttProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_ChartMode>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(value: _ChartMode.suhu, label: Text('Suhu')),
                  ButtonSegment(
                    value: _ChartMode.kelembapan,
                    label: Text('Kelembapan'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: widget.logsAsync.when(
                loading: () => const LoadingWidget(),
                error: (err, _) => AppErrorWidget(
                  message: friendlyApiError(err),
                  onRetry: () => ref.refresh(incubatorStatusHistoryProvider),
                ),
                data: (logs) {
                  final bool live;
                  final List<TelemetryLog> source;
                  if (logs.isNotEmpty) {
                    source = logs;
                    live = false;
                  } else if (mqtt.trend.isNotEmpty) {
                    source = mqtt.trend;
                    live = true;
                  } else {
                    final waiting =
                        mqtt.status == 'connecting' ||
                        mqtt.status == 'reconnecting';
                    return Center(
                      child: Text(
                        waiting
                            ? 'Menunggu data live…'
                            : 'Belum ada data telemetry',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusChip(
                        label: live ? 'Live' : 'Riwayat',
                        status: live ? AppStatus.active : AppStatus.neutral,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _mode == _ChartMode.suhu
                            ? TelemetryTempChart(logs: source)
                            : TelemetryHumidityChart(logs: source),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Log penetasan: icon + kode + tanggal + berat (DESIGN.md §3.6).
class _HatchLog extends ConsumerWidget {
  final AsyncValue<List<Chick>> chicksAsync;

  const _HatchLog({required this.chicksAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return chicksAsync.when(
      loading: () => const LoadingWidget(),
      error: (err, _) => AppErrorWidget(
        message: friendlyApiError(err),
        onRetry: () => ref.refresh(chicksListProvider),
      ),
      data: (chicks) {
        final recent = chicks.take(5).toList();
        if (recent.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.egg_outlined,
                message: 'Belum ada data di kategori ini',
              ),
            ),
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                _HatchItem(chick: recent[i]),
                if (i < recent.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HatchItem extends StatelessWidget {
  final Chick chick;

  const _HatchItem({required this.chick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.egg_outlined,
              size: 20,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chick.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatDate(chick.tanggalMenetas),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${chick.beratAwal.toStringAsFixed(0)}g',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const StatusChip(label: 'Prima', status: AppStatus.active),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brooder checklist 1 card ber-divider (DESIGN.md §3.7).
class _BrooderCard extends StatelessWidget {
  final IncubatorStatus? status;

  const _BrooderCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Suhu Stabil', status != null ? 'AKTIF' : '-'),
      ('Kelembapan', status != null ? 'AKTIF' : '-'),
      ('Lampu Cadangan', status?.lampuStatus ?? '-'),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Brooder',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusChip(
                  label: status != null ? 'STANDBY' : '-',
                  status: status != null
                      ? AppStatus.pending
                      : AppStatus.neutral,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.statusActive,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].$1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusActive,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
