import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/silsilah.dart';
import '../../core/utils/validators.dart';
import '../../data/models/breeder.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../shared/app_form.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/loading_widget.dart';

class BreederFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  const BreederFormScreen({super.key, this.editId});

  bool get isEdit => editId != null;

  @override
  ConsumerState<BreederFormScreen> createState() => _BreederFormScreenState();
}

class _BreederFormScreenState extends ConsumerState<BreederFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suffixController = TextEditingController();
  final _namaController = TextEditingController();
  final _generasiController = TextEditingController(text: 'F0');
  final _varianWarnaController = TextEditingController();

  String _jenisKelamin = 'jantan';
  String _asal = 'beli';
  String _status = 'breeding';
  DateTime? _tanggalLahir;
  String? _parentJantanId;
  String? _parentBetinaId;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _suffixController.dispose();
    _namaController.dispose();
    _generasiController.dispose();
    _varianWarnaController.dispose();
    super.dispose();
  }

  bool get _isAnak => _parentJantanId != null && _parentBetinaId != null;

  String get _prefix {
    if (_isAnak) return prefixTelur(_parentJantanId!, _parentBetinaId!);
    return prefixBreederF0(_jenisKelamin);
  }

  String get _assembledId => '$_prefix${_suffixController.text.trim().padLeft(2, '0')}';

  void _initFromBreeder(Breeder b) {
    if (_initialized) return;
    _initialized = true;
    _namaController.text = b.nama ?? '';
    _jenisKelamin = b.jenisKelamin;
    _generasiController.text = b.generasi;
    _varianWarnaController.text = b.varianWarna;
    _asal = b.asal;
    _status = b.status;
    _tanggalLahir = b.tanggalLahir;
    _parentJantanId = b.parentJantanId;
    _parentBetinaId = b.parentBetinaId;
    if (_isAnak) {
      _suffixController.text = suffixOfAnak(b.id);
    } else {
      final m = RegExp(r'^(JB|BB)(\d+)$').firstMatch(b.id);
      _suffixController.text = m?.group(2) ?? '';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _assembledId;
    setState(() => _isSaving = true);

    final breeder = Breeder(
      id: id,
      nama: _namaController.text.trim().isEmpty ? null : _namaController.text.trim(),
      jenisKelamin: _jenisKelamin,
      tanggalLahir: _tanggalLahir,
      generasi: _generasiController.text.trim(),
      varianWarna: _varianWarnaController.text.trim(),
      asal: _asal,
      status: _status,
      parentJantanId: _parentJantanId,
      parentBetinaId: _parentBetinaId,
    );

    bool ok = false;
    String? errMsg;
    if (widget.isEdit) {
      await ref.read(breederUpdateProvider.notifier).updateBreeder(widget.editId!, breeder);
      final state = ref.read(breederUpdateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(breederUpdateProvider.notifier).reset();
    } else {
      await ref.read(breederCreateProvider.notifier).create(breeder);
      final state = ref.read(breederCreateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(breederCreateProvider.notifier).reset();
    }
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $errMsg'), backgroundColor: AppColors.critical),
      );
      return;
    }

    ref.invalidate(breedersListProvider);
    if (widget.isEdit) ref.invalidate(breederDetailProvider(widget.editId!));
    ref.invalidate(dashboardProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEdit ? 'Indukan berhasil diubah' : 'Indukan berhasil ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
      final detail = ref.watch(breederDetailProvider(widget.editId!));
      return Scaffold(
        appBar: DetailAppBar(title: 'Edit Indukan ${widget.editId}'),
        body: detail.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => Center(child: Text(friendlyApiError(e))),
          data: (b) {
            _initFromBreeder(b);
            return _form(jantanList, betinaList, lockedLineage: true);
          },
        ),
      );
    }

    breedersAsync.whenData((list) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _suffixController.text.isEmpty) {
            final ids = list.map((b) => b.id).toList();
            int next;
            if (_isAnak) {
              next = nextNomorPasangan(ids, _parentJantanId!, _parentBetinaId!);
            } else {
              next = nextNomorF0(ids, _jenisKelamin);
            }
            setState(() => _suffixController.text = pad2(next));
          }
        }));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Indukan'),
      body: _form(jantanList, betinaList, lockedLineage: false),
    );
  }

  Widget _form(List<Breeder> jantanList, List<Breeder> betinaList, {required bool lockedLineage}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppLabel('Jenis Kelamin *'),
            DropdownButtonFormField<String>(
              initialValue: _jenisKelamin,
              items: const [
                DropdownMenuItem(value: 'jantan', child: Text('Jantan (JB)')),
                DropdownMenuItem(value: 'betina', child: Text('Betina (BB)')),
              ],
              onChanged: lockedLineage
                  ? null
                  : (v) => setState(() {
                        _jenisKelamin = v!;
                        _suffixController.clear();
                      }),
            ),
            const SizedBox(height: 16),
            const AppLabel('Parent Jantan (kosong = F0)'),
            DropdownButtonFormField<String?>(
              initialValue: _parentJantanId,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Tidak ada (F0) --')),
                ...jantanList.map((b) => DropdownMenuItem<String?>(value: b.id, child: Text(b.nama ?? b.id))),
              ],
              onChanged: lockedLineage
                  ? null
                  : (v) => setState(() {
                        _parentJantanId = v;
                        _suffixController.clear();
                      }),
            ),
            const SizedBox(height: 16),
            const AppLabel('Parent Betina (kosong = F0)'),
            DropdownButtonFormField<String?>(
              initialValue: _parentBetinaId,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('-- Tidak ada (F0) --')),
                ...betinaList.map((b) => DropdownMenuItem<String?>(value: b.id, child: Text(b.nama ?? b.id))),
              ],
              onChanged: lockedLineage
                  ? null
                  : (v) => setState(() {
                        _parentBetinaId = v;
                        _suffixController.clear();
                      }),
            ),
            if (lockedLineage)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Jenis kelamin & parent dikunci (prefix silsilah). Hanya nomor yang bisa diubah.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            const AppLabel('Nomor ID (suffix) *'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    _prefix,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _suffixController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '01 / 02'),
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
                'ID akhir: $_assembledId ${_isAnak ? "(anak)" : "(F0)"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            const AppLabel('Nama'),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(hintText: 'Opsional'),
            ),
            const SizedBox(height: 16),
            const AppLabel('Tanggal Lahir'),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(_tanggalLahir == null
                        ? 'Pilih tanggal'
                        : formatDate(_tanggalLahir!.toIso8601String())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AppLabel('Generasi *'),
            TextFormField(
              controller: _generasiController,
              validator: validateRequired,
            ),
            const SizedBox(height: 16),
            const AppLabel('Varian Warna *'),
            TextFormField(
              controller: _varianWarnaController,
              decoration: const InputDecoration(hintText: 'Hijau / Biru / Putih'),
              validator: validateRequired,
            ),
            const SizedBox(height: 16),
            const AppLabel('Asal *'),
            DropdownButtonFormField<String>(
              initialValue: _asal,
              items: const [
                DropdownMenuItem(value: 'beli', child: Text('Beli')),
                DropdownMenuItem(value: 'ternak_sendiri', child: Text('Ternak Sendiri')),
              ],
              onChanged: (v) => setState(() => _asal = v!),
            ),
            const SizedBox(height: 16),
            const AppLabel('Status *'),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'breeding', child: Text('Aktif')),
                DropdownMenuItem(value: 'resting', child: Text('Istirahat')),
                DropdownMenuItem(value: 'ready_for_sale', child: Text('Siap Jual')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

}
