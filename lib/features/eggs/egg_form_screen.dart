import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/silsilah.dart';
import '../../core/utils/validators.dart';
import '../../data/models/breeder.dart';
import '../../data/models/egg.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../shared/app_form.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/loading_widget.dart';
import 'widgets/slot_picker.dart';

class EggFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  const EggFormScreen({super.key, this.editId});

  bool get isEdit => editId != null;

  @override
  ConsumerState<EggFormScreen> createState() => _EggFormScreenState();
}

class _EggFormScreenState extends ConsumerState<EggFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suffixController = TextEditingController();
  final _slotController = TextEditingController();
  final _catatanController = TextEditingController();

  int? _selectedSlot;
  String? _indukJantanId;
  String? _indukBetinaId;
  String _fertilitas = 'Belum dicek';
  String _akhir = 'Proses';
  DateTime _tanggalMasuk = DateTime.now();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _suffixController.dispose();
    _slotController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String get _prefix {
    if (_indukJantanId == null || _indukBetinaId == null) return '—';
    return prefixTelur(_indukJantanId!, _indukBetinaId!);
  }

  String get _assembledId =>
      '$_prefix${_suffixController.text.trim().padLeft(2, '0')}';

  void _initFromEgg(Egg egg) {
    if (_initialized) return;
    _initialized = true;
    _indukJantanId = egg.indukJantanId;
    _indukBetinaId = egg.indukBetinaId;
    _suffixController.text = suffixOfAnak(egg.id).isEmpty
        ? ''
        : suffixOfAnak(egg.id);
    _slotController.text = '${egg.slot}';
    _selectedSlot = egg.slot;
    _catatanController.text = egg.catatan ?? '';
    _fertilitas = egg.fertilitas;
    _akhir = egg.akhir;
    try {
      _tanggalMasuk = DateTime.parse(egg.tanggalMasuk);
    } catch (_) {}
  }

  void _suggestSuffix(List<Egg> eggs) {
    if (widget.isEdit || _initialized) return;
    if (_indukJantanId == null || _indukBetinaId == null) return;
    if (_suffixController.text.isNotEmpty) return;
    final next = nextNomorPasangan(
      eggs.map((e) => e.id).toList(),
      _indukJantanId!,
      _indukBetinaId!,
    );
    setState(() => _suffixController.text = pad2(next));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMasuk,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tanggalMasuk = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_indukJantanId == null || _indukBetinaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih indukan jantan dan betina'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }
    final id = _assembledId;
    final prefixErr = validateTelurId(id, _indukJantanId!, _indukBetinaId!);
    if (prefixErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prefixErr), backgroundColor: AppColors.critical),
      );
      return;
    }
    final slot = _selectedSlot ?? int.tryParse(_slotController.text.trim());
    if (slot == null || slot < 1 || slot > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih slot 1-100 pada peta slot'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }
    // Cek ulang bentrok (data bisa berubah sejak form dibuka).
    final latest = ref.read(eggsListProvider).valueOrNull ?? const <Egg>[];
    final clash = latest.any(
      (e) =>
          e.slot == slot &&
          e.akhir == 'Proses' &&
          e.id != (widget.editId ?? ''),
    );
    if (clash) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot $slot sudah terisi, pilih slot lain'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    final egg = Egg(
      id: id,
      slot: slot,
      indukJantanId: _indukJantanId!,
      indukBetinaId: _indukBetinaId!,
      tanggalMasuk: _tanggalMasuk.toIso8601String().substring(0, 10),
      fertilitas: _fertilitas,
      akhir: _akhir,
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
    );

    bool ok = false;
    String? errMsg;
    if (widget.isEdit) {
      await ref.read(eggUpdateProvider.notifier).updateEgg(widget.editId!, egg);
      final state = ref.read(eggUpdateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(eggUpdateProvider.notifier).reset();
    } else {
      await ref.read(eggCreateProvider.notifier).create(egg);
      final state = ref.read(eggCreateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(eggCreateProvider.notifier).reset();
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $errMsg'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    ref.invalidate(eggsListProvider);
    if (widget.isEdit) ref.invalidate(eggDetailProvider(widget.editId!));
    ref.invalidate(dashboardProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEdit
              ? 'Telur berhasil diubah'
              : 'Telur berhasil ditambahkan',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final eggsAsync = ref.watch(eggsListProvider);
    final breedersAsync = ref.watch(breedersListProvider);
    final jantanList = breedersAsync.maybeWhen(
      data: (list) => list.where((b) => b.jenisKelamin == 'jantan').toList(),
      orElse: () => <Breeder>[],
    );
    final betinaList = breedersAsync.maybeWhen(
      data: (list) => list.where((b) => b.jenisKelamin == 'betina').toList(),
      orElse: () => <Breeder>[],
    );

    if (widget.isEdit) {
      final detail = ref.watch(eggDetailProvider(widget.editId!));
      return Scaffold(
        appBar: DetailAppBar(title: 'Edit Telur ${widget.editId}'),
        body: detail.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => Center(child: Text(friendlyApiError(e))),
          data: (egg) {
            _initFromEgg(egg);
            return _form(
              eggsAsync.valueOrNull ?? [],
              jantanList,
              betinaList,
              lockedParents: true,
            );
          },
        ),
      );
    }

    eggsAsync.whenData(
      (list) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _suggestSuffix(list);
      }),
    );
    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Telur'),
      body: _form(
        eggsAsync.valueOrNull ?? [],
        jantanList,
        betinaList,
        lockedParents: false,
      ),
    );
  }

  Widget _form(
    List<Egg> eggs,
    List<Breeder> jantanList,
    List<Breeder> betinaList, {
    required bool lockedParents,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppLabel('Indukan Jantan *'),
            DropdownButtonFormField<String?>(
              initialValue: _indukJantanId,
              items: jantanList
                  .map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.nama ?? b.id),
                    ),
                  )
                  .toList(),
              onChanged: lockedParents
                  ? null
                  : (v) => setState(() {
                      _indukJantanId = v;
                      _suffixController.clear();
                      _suggestSuffix(eggs);
                    }),
              validator: (v) => v == null ? 'Pilih indukan' : null,
            ),
            const SizedBox(height: 16),
            const AppLabel('Indukan Betina *'),
            DropdownButtonFormField<String?>(
              initialValue: _indukBetinaId,
              items: betinaList
                  .map(
                    (b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.nama ?? b.id),
                    ),
                  )
                  .toList(),
              onChanged: lockedParents
                  ? null
                  : (v) => setState(() {
                      _indukBetinaId = v;
                      _suffixController.clear();
                      _suggestSuffix(eggs);
                    }),
              validator: (v) => v == null ? 'Pilih indukan' : null,
            ),
            if (lockedParents)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Indukan dikunci (prefix silsilah). Hanya nomor yang bisa diubah.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const AppLabel('Nomor telur (suffix) *'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    _prefix,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _suffixController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '01 / 02 / 03'),
                    validator: (v) {
                      final req = validateRequired(v); if (req != null) return req;
                      final n = int.tryParse(v!.trim());
                      if (n == null || n < 1 || n > 99) return '1-99';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'ID akhir: $_assembledId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AppLabel('Tanggal Masuk *'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(formatDate(_tanggalMasuk.toIso8601String())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AppLabel('Fertilitas *'),
            DropdownButtonFormField<String>(
              initialValue: _fertilitas,
              items: const [
                DropdownMenuItem(
                  value: 'Belum dicek',
                  child: Text('Belum dicek'),
                ),
                DropdownMenuItem(value: 'Fertil', child: Text('Fertil')),
                DropdownMenuItem(value: 'Infertil', child: Text('Infertil')),
              ],
              onChanged: (v) => setState(() => _fertilitas = v!),
            ),
            const SizedBox(height: 16),
            const AppLabel('Akhir *'),
            DropdownButtonFormField<String>(
              initialValue: _akhir,
              items: const [
                DropdownMenuItem(value: 'Proses', child: Text('Proses')),
                DropdownMenuItem(value: 'Menetas', child: Text('Menetas')),
                DropdownMenuItem(value: 'Gagal', child: Text('Gagal')),
              ],
              onChanged: (v) => setState(() => _akhir = v!),
            ),
            const SizedBox(height: 16),
            const AppLabel('Slot *'),
            SlotPicker(
              occupiedSlots: {
                for (final e in eggs)
                  if (e.akhir == 'Proses' && e.id != (widget.editId ?? ''))
                    e.slot,
              },
              initialSlot:
                  _selectedSlot ?? int.tryParse(_slotController.text.trim()),
              onChanged: (slot) => setState(() {
                _selectedSlot = slot;
                _slotController.text = slot != null ? '$slot' : '';
              }),
              validator: (slot) {
                if (slot == null || slot < 1 || slot > 100) {
                  return 'Pilih slot 1-100';
                }
                return null;
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Terisi = ada telur berstatus Proses. Menetas/Gagal dianggap sudah keluar.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            const AppLabel('Catatan'),
            TextFormField(controller: _catatanController, maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

}
