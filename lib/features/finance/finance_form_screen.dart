import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/validators.dart';
import '../../data/models/breeder.dart';
import '../../data/models/chick.dart';
import '../../data/models/egg.dart';
import '../../data/models/finance_entry.dart';
import '../../data/models/sale.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/providers/finance_provider.dart';
import '../../data/providers/sales_provider.dart';
import '../../shared/app_form.dart';
import '../../shared/detail_app_bar.dart';

class FinanceFormScreen extends ConsumerStatefulWidget {
  const FinanceFormScreen({super.key});

  @override
  ConsumerState<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends ConsumerState<FinanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _catatanController = TextEditingController();
  final _pembeliController = TextEditingController();

  DateTime _tanggal = DateTime.now();
  String _tipe = 'Pemasukan';
  String _kategori = 'Penjualan Telur';
  String? _referensiId;
  bool _isSaving = false;
  bool _idPrefilled = false;

  static const _kategoriMasuk = [
    'Penjualan Telur',
    'Penjualan Anakan',
    'Penjualan Indukan',
    'Lainnya',
  ];
  static const _kategoriKeluar = [
    'Pakan Indukan',
    'Pakan Anakan',
    'Listrik',
    'Peralatan',
    'Kesehatan/Obat',
    'Lainnya',
  ];

  List<String> get _kategoriOptions =>
      _tipe == 'Pemasukan' ? _kategoriMasuk : _kategoriKeluar;

  bool get _isPenjualan => _kategori.startsWith('Penjualan');
  bool get _isLainnya => _kategori == 'Lainnya';

  @override
  void dispose() {
    _idController.dispose();
    _kategoriController.dispose();
    _jumlahController.dispose();
    _catatanController.dispose();
    _pembeliController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final kategori = _isLainnya ? _kategoriController.text.trim() : _kategori;
    final note = _catatanController.text.trim();
    final catatan = _referensiId != null
        ? 'Ref: $_referensiId${note.isEmpty ? '' : ' · $note'}'
        : (note.isEmpty ? null : note);
    setState(() => _isSaving = true);

    final entry = FinanceEntry(
      id: _idController.text.trim(),
      tanggal: _tanggal.toIso8601String().substring(0, 10),
      tipe: _tipe,
      kategori: kategori,
      jumlah: double.parse(_jumlahController.text.trim()),
      catatan: catatan,
      createdBy: user.id,
    );

    await ref.read(financeCreateProvider.notifier).create(entry);
    if (!mounted) return;
    setState(() => _isSaving = false);

    final state = ref.read(financeCreateProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    // Penjualan tunai (Lunas) -> catat Sale terkait agar stok ter-track.
    String? saleWarning;
    if (_isPenjualan && _referensiId != null) {
      try {
        final sales = await ref.read(salesListProvider.future);
        final sale = Sale(
          id: nextId(sales.map((e) => e.id).toList(), 'SLS-'),
          tanggal: _tanggal.toIso8601String().substring(0, 10),
          item: '$kategori $_referensiId',
          referensiId: _referensiId!,
          pembeli: _pembeliController.text.trim(),
          qty: 1,
          hargaSatuan: double.parse(_jumlahController.text.trim()),
          status: 'Lunas',
          catatan: 'Otomatis dari ${entry.id}',
        );
        await ref.read(saleCreateProvider.notifier).create(sale);
        final saleState = ref.read(saleCreateProvider);
        if (saleState.hasError) {
          saleWarning = friendlyApiError(saleState.error!);
        }
        ref.read(saleCreateProvider.notifier).reset();
      } catch (e) {
        saleWarning = friendlyApiError(e);
      }
    }

    ref.invalidate(financeListProvider);
    ref.invalidate(salesListProvider);
    ref.invalidate(breedersListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(financeCreateProvider.notifier).reset();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saleWarning == null
            ? 'Keuangan berhasil ditambahkan'
            : 'Keuangan tersimpan, sale gagal: $saleWarning'),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final financeAsync = ref.watch(financeListProvider);
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final breedersAsync = ref.watch(breedersListProvider);

    if (!_idPrefilled) {
      financeAsync.whenData((list) {
        if (!_idPrefilled) {
          _idPrefilled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _idController.text.isEmpty) {
              setState(() {
                _idController.text = nextId(
                  list.map((e) => e.id).toList(),
                  'FIN-',
                );
              });
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Keuangan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'ID Entri *',
                controller: _idController,
                validator: validateRequired,
                hint: 'FIN-001',
              ),
              DatePickerField(
                label: 'Tanggal *',
                value: _tanggal,
                onChanged: (v) => setState(() => _tanggal = v),
              ),
              const AppLabel('Tipe *'),
              DropdownButtonFormField<String>(
                initialValue: _tipe,
                items: const [
                  DropdownMenuItem(value: 'Pemasukan', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'Pengeluaran', child: Text('Pengeluaran')),
                ],
                onChanged: (v) => setState(() {
                  _tipe = v!;
                  _kategori = _kategoriOptions.first;
                  _referensiId = null;
                  _kategoriController.clear();
                }),
              ),
              const SizedBox(height: 16),
              const AppLabel('Kategori *'),
              DropdownButtonFormField<String>(
                initialValue: _kategoriOptions.contains(_kategori) ? _kategori : null,
                items: _kategoriOptions
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _kategori = v!;
                  _referensiId = null;
                }),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              if (_isLainnya) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kategoriController,
                  decoration: const InputDecoration(hintText: 'Tulis kategori sendiri'),
                  validator: validateRequired,
                ),
              ],
              if (_isPenjualan) ...[
                const SizedBox(height: 16),
                const AppLabel('Referensi Terjual *'),
                _referensiDropdown(eggsAsync, chicksAsync, breedersAsync),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Pembeli *',
                  controller: _pembeliController,
                  validator: validateRequired,
                  hint: 'Nama pembeli',
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Jumlah (Rp) *',
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final req = validateRequired(v); if (req != null) return req;
                  final n = double.tryParse(v!);
                  if (n == null || n <= 0) return 'Angka positif';
                  return null;
                },
              ),
              AppTextField(
                label: 'Catatan',
                controller: _catatanController,
                maxLines: 3,
              ),
              SaveButton(isSaving: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }


  /// Dropdown ID yang dijual sesuai jenis kategori penjualan.
  Widget _referensiDropdown(
    AsyncValue<List<Egg>> eggsAsync,
    AsyncValue<List<Chick>> chicksAsync,
    AsyncValue<List<Breeder>> breedersAsync,
  ) {
    final List<DropdownMenuItem<String>> items;
    final String hint;
    switch (_kategori) {
      case 'Penjualan Telur':
        final eggs = eggsAsync.valueOrNull ?? const <Egg>[];
        items = [
          for (final e in eggs)
            DropdownMenuItem(value: e.id, child: Text(e.id)),
        ];
        hint = 'Pilih ID telur';
        break;
      case 'Penjualan Anakan':
        final chicks = chicksAsync.valueOrNull ?? const <Chick>[];
        items = [
          for (final c in chicks)
            DropdownMenuItem(value: c.id, child: Text(c.id)),
        ];
        hint = 'Pilih ID anakan';
        break;
      default:
        final breeders = breedersAsync.valueOrNull ?? const <Breeder>[];
        items = [
          for (final b in breeders)
            DropdownMenuItem(
              value: b.id,
              child: Text(
                b.nama?.isNotEmpty == true ? '${b.nama} (${b.id})' : b.id,
              ),
            ),
        ];
        hint = 'Pilih ID indukan';
        break;
    }
    final validSelection =
        _referensiId != null && items.any((i) => i.value == _referensiId);
    return DropdownButtonFormField<String>(
      initialValue: validSelection ? _referensiId : null,
      items: items,
      decoration: InputDecoration(hintText: hint),
      onChanged: (v) => setState(() => _referensiId = v),
      validator: (v) {
        if (v == null) return 'Pilih referensi';
        if (!items.any((i) => i.value == v)) return 'Referensi tidak valid';
        return null;
      },
    );
  }
}
