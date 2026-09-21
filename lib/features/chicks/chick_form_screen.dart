import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/silsilah.dart';
import '../../core/utils/validators.dart';
import '../../data/models/chick.dart';
import '../../data/models/egg.dart';
import '../../data/providers/api_client_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/services/upload_service.dart';
import '../../shared/app_form.dart';
import '../../shared/app_photo_picker.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/loading_widget.dart';

class ChickFormScreen extends ConsumerStatefulWidget {
  final String? editId;
  const ChickFormScreen({super.key, this.editId});

  bool get isEdit => editId != null;

  @override
  ConsumerState<ChickFormScreen> createState() => _ChickFormScreenState();
}

class _ChickFormScreenState extends ConsumerState<ChickFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _suffixController = TextEditingController();
  final _beratController = TextEditingController();
  final _skorController = TextEditingController(text: 'Sehat');
  final _catatanController = TextEditingController();
  PickedPhoto? _photo;

  String? _eggId;
  DateTime _tanggalMenetas = DateTime.now();
  String _status = 'newborn';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _suffixController.dispose();
    _beratController.dispose();
    _skorController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String get _prefix => _eggId == null ? '—' : prefixChick(_eggId!);
  String get _assembledId {
    final s = _suffixController.text.trim().toUpperCase().replaceFirst(RegExp(r'^C'), '');
    return '$_prefix${s.padLeft(2, '0')}';
  }

  void _initFromChick(Chick chick) {
    if (_initialized) return;
    _initialized = true;
    _eggId = chick.eggId;
    final s = suffixOfChick(chick.id);
    _suffixController.text = s.startsWith('C') ? s.substring(1) : s;
    _beratController.text = '${chick.beratAwal}';
    _skorController.text = chick.skorKesehatan;
    _photo = PickedPhoto(url: chick.fotoUrl);
    _catatanController.text = chick.catatan ?? '';
    _status = chick.status;
    try {
      _tanggalMenetas = DateTime.parse(chick.tanggalMenetas);
    } catch (_) {}
  }

  void _suggestSuffix(List<Chick> chicks) {
    if (widget.isEdit || _initialized || _eggId == null) return;
    if (_suffixController.text.isNotEmpty) return;
    final next = nextNomorChick(chicks.map((e) => e.id).toList(), _eggId!);
    setState(() => _suffixController.text = pad2(next));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eggId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih egg asal'), backgroundColor: AppColors.critical),
      );
      return;
    }
    final id = _assembledId;
    final prefixErr = validateChickId(id, _eggId!);
    if (prefixErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prefixErr), backgroundColor: AppColors.critical),
      );
      return;
    }
    setState(() => _isSaving = true);

    // Upload foto device dulu (gagal = save dibatalkan).
    final previousUrl = _photo?.url;
    String? fotoUrl = _photo?.url;
    if (_photo?.file != null) {
      try {
        final up = await UploadService(ref.read(apiClientProvider))
            .uploadPhoto(_photo!.file!, UploadFolder.chicks);
        fotoUrl = up.url;
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload foto gagal: ${friendlyApiError(e)}')),
        );
        return;
      }
    }

    final chick = Chick(
      id: id,
      eggId: _eggId!,
      tanggalMenetas: _tanggalMenetas.toIso8601String().substring(0, 10),
      beratAwal: double.parse(_beratController.text.trim()),
      skorKesehatan: _skorController.text.trim(),
      status: _status,
      fotoUrl: fotoUrl,
      catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
    );

    bool ok = false;
    String? errMsg;
    if (widget.isEdit) {
      await ref.read(chickUpdateProvider.notifier).updateChick(widget.editId!, chick);
      final state = ref.read(chickUpdateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(chickUpdateProvider.notifier).reset();
    } else {
      await ref.read(chickCreateProvider.notifier).create(chick);
      final state = ref.read(chickCreateProvider);
      ok = !state.hasError;
      if (state.hasError) errMsg = friendlyApiError(state.error!);
      ref.read(chickCreateProvider.notifier).reset();
    }
    if (!mounted) return;

    // Sinkron status telur -> Menetas (abaikan gagal diam-diam).
    if (ok && !widget.isEdit) {
      try {
        final eggList = ref.read(eggsListProvider).valueOrNull;
        Egg? egg;
        if (eggList != null) {
          for (final e in eggList) {
            if (e.id == _eggId) {
              egg = e;
              break;
            }
          }
        }
        if (egg != null && egg.akhir != 'Menetas' && egg.akhir.isNotEmpty) {
          await ref.read(eggUpdateProvider.notifier).updateEgg(egg.id, egg.copyWith(akhir: 'Menetas'));
          ref.read(eggUpdateProvider.notifier).reset();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $errMsg'), backgroundColor: AppColors.critical),
      );
      return;
    }

    // Foto diganti/dihapus saat edit: bersihkan file lama (BACKEND.md §13.3).
    final oldKey = UploadService.objectKeyFromUrl(previousUrl);
    if (widget.isEdit &&
        oldKey != null &&
        oldKey.isNotEmpty &&
        previousUrl != fotoUrl) {
      UploadService(ref.read(apiClientProvider)).deletePhoto(oldKey);
    }

    ref.invalidate(chicksListProvider);
    if (widget.isEdit) ref.invalidate(chickDetailProvider(widget.editId!));
    ref.invalidate(eggsListProvider);
    ref.invalidate(dashboardProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.isEdit ? 'Anakan berhasil diubah' : 'Anakan berhasil ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final chicksAsync = ref.watch(chicksListProvider);
    final eggsAsync = ref.watch(eggsListProvider);
    final eggList = eggsAsync.maybeWhen(data: (l) => l, orElse: () => <Egg>[]);

    if (widget.isEdit) {
      final detail = ref.watch(chickDetailProvider(widget.editId!));
      return Scaffold(
        appBar: DetailAppBar(title: 'Edit Anakan ${widget.editId}'),
        body: detail.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => Center(child: Text(friendlyApiError(e))),
          data: (chick) {
            _initFromChick(chick);
            return _form(chicksAsync.valueOrNull ?? [], eggList, lockedEgg: true);
          },
        ),
      );
    }

    chicksAsync.whenData((list) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _suggestSuffix(list);
        }));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Anakan'),
      body: _form(chicksAsync.valueOrNull ?? [], eggList, lockedEgg: false),
    );
  }

  Widget _form(List<Chick> chicks, List<Egg> eggList, {required bool lockedEgg}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppLabel('Egg Asal *'),
            DropdownButtonFormField<String?>(
              initialValue: _eggId,
              items: eggList
                  .map((e) => DropdownMenuItem<String?>(
                        value: e.id,
                        child: Text('${e.id} (Slot ${e.slot})'),
                      ))
                  .toList(),
              onChanged: lockedEgg
                  ? null
                  : (v) => setState(() {
                        _eggId = v;
                        _suffixController.clear();
                        _suggestSuffix(chicks);
                      }),
              validator: (v) => v == null ? 'Pilih egg' : null,
            ),
            if (lockedEgg)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Egg asal dikunci. Hanya nomor -C{NN} yang bisa diubah.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            const AppLabel('Nomor anakan (suffix -C) *'),
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
                      final clean = v!.trim().toUpperCase().replaceFirst(RegExp(r'^C'), '');
                      final n = int.tryParse(clean);
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
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            DatePickerField(
              label: 'Tanggal Menetas *',
              value: _tanggalMenetas,
              onChanged: (d) => setState(() => _tanggalMenetas = d),
            ),
            AppTextField(
              label: 'Berat Awal (gram) *',
              controller: _beratController,
              keyboardType: TextInputType.number,
              validator: (v) {
                final req = validateRequired(v); if (req != null) return req;
                final n = double.tryParse(v!);
                if (n == null || n <= 0) return 'Angka positif';
                return null;
              },
            ),
            AppTextField(
              label: 'Skor Kesehatan *',
              controller: _skorController,
              validator: validateRequired,
            ),
            const AppLabel('Status *'),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'newborn', child: Text('Baru Menetas')),
                DropdownMenuItem(value: 'growing', child: Text('Tumbuh')),
                DropdownMenuItem(value: 'ready_for_sale', child: Text('Siap Jual')),
                DropdownMenuItem(value: 'sold', child: Text('Terjual')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            AppPhotoPicker(
              label: 'Foto',
              initialUrl: _photo?.url,
              folder: UploadFolder.chicks,
              onChanged: (p) => _photo = p,
            ),
            AppTextField(
              label: 'Catatan',
              controller: _catatanController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SaveButton(isSaving: _isSaving, isEdit: widget.isEdit, onPressed: _save),
          ],
        ),
      ),
    );
  }

}
