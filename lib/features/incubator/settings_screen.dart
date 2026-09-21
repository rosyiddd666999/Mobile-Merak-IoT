import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/validators.dart';
import '../../data/models/incubator_settings.dart';
import '../../data/providers/incubator_provider.dart';
import '../../data/providers/mqtt_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

class IncubatorSettingsScreen extends ConsumerStatefulWidget {
  const IncubatorSettingsScreen({super.key});

  @override
  ConsumerState<IncubatorSettingsScreen> createState() => _IncubatorSettingsScreenState();
}

class _IncubatorSettingsScreenState extends ConsumerState<IncubatorSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suhuMinController = TextEditingController();
  final _suhuMaxController = TextEditingController();
  final _lembapMinController = TextEditingController();
  final _lembapMaxController = TextEditingController();
  final _intervalController = TextEditingController();
  bool _isSaving = false;

  /// Teks mismatch DB vs perangkat, null bila selaras/belum ada data firmware.
  String? _mismatchText({
    required double? suhuMin,
    required double? suhuMax,
    required double? lembapMin,
    required double? lembapMax,
    required MqttState mqtt,
  }) {
    final t = [
      mqtt.threshTempOn, mqtt.threshTempOff, mqtt.threshHumidLow, mqtt.threshHumidHigh
    ];
    if (t.any((v) => v == null)) return null;
    bool eq(double? a, double? b) =>
        a != null && b != null && (a - b).abs() < 0.001;
    if (eq(suhuMin, mqtt.threshTempOn) &&
        eq(suhuMax, mqtt.threshTempOff) &&
        eq(lembapMin, mqtt.threshHumidLow) &&
        eq(lembapMax, mqtt.threshHumidHigh)) {
      return null;
    }
    return 'Perangkat (${mqtt.threshTempOn}–${mqtt.threshTempOff}°C) ≠ server. Ketuk Selaraskan.';
  }

  @override
  void dispose() {
    _suhuMinController.dispose();
    _suhuMaxController.dispose();
    _lembapMinController.dispose();
    _lembapMaxController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _initFromSettings(IncubatorSettings s) {
    _suhuMinController.text = s.suhuMin.toString();
    _suhuMaxController.text = s.suhuMax.toString();
    _lembapMinController.text = s.kelembapanMin.toString();
    _lembapMaxController.text = s.kelembapanMax.toString();
    _intervalController.text = s.intervalRotasiMenit.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = IncubatorSettings(
      id: 1,
      suhuMin: double.parse(_suhuMinController.text),
      suhuMax: double.parse(_suhuMaxController.text),
      kelembapanMin: double.parse(_lembapMinController.text),
      kelembapanMax: double.parse(_lembapMaxController.text),
      intervalRotasiMenit: int.parse(_intervalController.text),
    );

    await ref.read(incubatorSettingsUpdateProvider.notifier).update(updated);

    // Tulis dua arah: DB sudah via PUT di atas, kini dorong ke perangkat
    // agar firmware tak tertinggal (split-brain lama: DB vs ESP beda).
    var deviceOk = false;
    if (mounted) {
      final sent = ref.read(mqttProvider.notifier).publishThresholds(
            tempOn: updated.suhuMin,
            tempOff: updated.suhuMax,
            humidLow: updated.kelembapanMin,
            humidHigh: updated.kelembapanMax,
          );
      deviceOk = sent == 4;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    ref.invalidate(incubatorSettingsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(deviceOk
          ? 'Tersimpan: server ✓, perangkat ✓'
          : 'Tersimpan di server ✓, perangkat ✗ (offline) — selaraskan saat online'),
    ));
  }

  /// Kirim ulang nilai form ke perangkat (tombol Selaraskan).
  void _syncToDevice() {
    final sent = ref.read(mqttProvider.notifier).publishThresholds(
          tempOn: double.tryParse(_suhuMinController.text) ?? 0,
          tempOff: double.tryParse(_suhuMaxController.text) ?? 0,
          humidLow: double.tryParse(_lembapMinController.text) ?? 0,
          humidHigh: double.tryParse(_lembapMaxController.text) ?? 0,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent == 4
          ? 'Ambang dikirim ke perangkat'
          : 'Perangkat offline — hubungkan MQTT dulu'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(incubatorSettingsProvider);
    final mqtt = ref.watch(mqttProvider);

    return Scaffold(
      appBar: const DetailAppBar(title: 'Pengaturan Inkubator'),
      body: settingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(message: friendlyApiError(err), onRetry: () => ref.refresh(incubatorSettingsProvider)),
        data: (settings) {
          if (_suhuMinController.text.isEmpty) _initFromSettings(settings);

          // Bandingkan DB (form) vs aktual perangkat (telemetri thresh_*).
          final mismatch = _mismatchText(
            suhuMin: double.tryParse(_suhuMinController.text),
            suhuMax: double.tryParse(_suhuMaxController.text),
            lembapMin: double.tryParse(_lembapMinController.text),
            lembapMax: double.tryParse(_lembapMaxController.text),
            mqtt: mqtt,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mismatch != null) ...[
                    Card(
                      color: const Color(0xFFFFF8E1),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined, color: Color(0xFFF5A524)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(mismatch, style: const TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: _syncToDevice,
                              child: const Text('Selaraskan'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Suhu Minimum', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _suhuMinController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final val = double.tryParse(v!);
                      if (val == null || val < 0 || val > 50) return '0-50°C';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Suhu Maksimum', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _suhuMaxController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final val = double.tryParse(v!);
                      if (val == null || val < 0 || val > 50) return '0-50°C';
                      if (val <= double.parse(_suhuMinController.text)) return 'Harus > Suhu Min';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Kelembapan Minimum', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _lembapMinController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final val = double.tryParse(v!);
                      if (val == null || val < 0 || val > 100) return '0-100%';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Kelembapan Maksimum', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _lembapMaxController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final val = double.tryParse(v!);
                      if (val == null || val < 0 || val > 100) return '0-100%';
                      if (val <= double.parse(_lembapMinController.text)) return 'Harus > Kelembapan Min';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Interval Rotasi (menit)', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final val = int.tryParse(v!);
                      if (val == null || val < 30) return 'Minimal 30 menit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
