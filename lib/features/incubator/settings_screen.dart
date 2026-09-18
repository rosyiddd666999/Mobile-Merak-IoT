import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/api_error.dart';
import '../../data/models/incubator_settings.dart';
import '../../data/providers/incubator_provider.dart';
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

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan tersimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(incubatorSettingsProvider);

    return Scaffold(
      appBar: const DetailAppBar(title: 'Pengaturan Inkubator'),
      body: settingsAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(message: friendlyApiError(err), onRetry: () => ref.refresh(incubatorSettingsProvider)),
        data: (settings) {
          if (_suhuMinController.text.isEmpty) _initFromSettings(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Suhu Minimum', style: Theme.of(context).textTheme.titleMedium),
                  TextFormField(
                    controller: _suhuMinController,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final val = double.tryParse(v);
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
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final val = double.tryParse(v);
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
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final val = double.tryParse(v);
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
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final val = double.tryParse(v);
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
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      final val = int.tryParse(v);
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
