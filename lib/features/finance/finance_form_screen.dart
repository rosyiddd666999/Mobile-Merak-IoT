import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/id_generator.dart';
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggal = picked);
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
              _label('ID Entri *'),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(hintText: 'FIN-001'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Tanggal *'),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(formatDate(_tanggal.toIso8601String())),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Tipe *'),
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
              _label('Kategori *'),
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
              ],
              if (_isPenjualan) ...[
                const SizedBox(height: 16),
                _label('Referensi Terjual *'),
                _referensiDropdown(eggsAsync, chicksAsync, breedersAsync),
                const SizedBox(height: 16),
                _label('Pembeli *'),
                TextFormField(
                  controller: _pembeliController,
                  decoration: const InputDecoration(hintText: 'Nama pembeli'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
              ],
              const SizedBox(height: 16),
              _label('Jumlah (Rp) *'),
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Angka positif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Catatan'),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
