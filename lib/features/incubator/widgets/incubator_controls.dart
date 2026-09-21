import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/providers/mqtt_provider.dart';
import '../../../shared/design_kit.dart';

/// Kontrol inkubator — 60% bg, 30% kartu putih, 10% aksen teal (DESIGN.md §1).
/// Lampu = segmented langsung kirim; Rotasi = tombol primer; Mist = tombol
/// outlined (mist ±10 dtk, firmware mendukung TRIGGER). Nilai optimistis
/// ditampilkan hingga telemetri nyata mengonfirmasi.
class TelemetryControls extends ConsumerStatefulWidget {
  final String? mqttLamp;
  final String? mqttMist;
  final String? mqttMotor;
  final bool mqttLive;
  final bool canControl;
  final bool demoActive;
  final DateTime? lastRotation;
  final String? lastRotationRaw;

  const TelemetryControls({
    super.key,
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
  ConsumerState<TelemetryControls> createState() => TelemetryControlsState();
}

class TelemetryControlsState extends ConsumerState<TelemetryControls> {
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

    final lastLabel = rotationLabel(
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
        LampCard(
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
        TriggerCard(
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
        TriggerCard(
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
        const AutoRotationCard(),
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
class AutoRotationCard extends ConsumerStatefulWidget {
  const AutoRotationCard({super.key});

  @override
  ConsumerState<AutoRotationCard> createState() => AutoRotationCardState();
}

class AutoRotationCardState extends ConsumerState<AutoRotationCard> {
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
    return ControlCard(
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
class ControlCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusLabel;
  final bool statusActive;
  final bool loading;
  final Widget child;

  const ControlCard({
    super.key,
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
class LampCard extends StatelessWidget {
  final String? lampShown;
  final LampMode selected;
  final bool loading;
  final bool enabled;
  final ValueChanged<LampMode> onSelect;

  const LampCard({
    super.key,
    required this.lampShown,
    required this.selected,
    required this.loading,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ControlCard(
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
class TriggerCard extends StatelessWidget {
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

  const TriggerCard({
    super.key,
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
    return ControlCard(
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
