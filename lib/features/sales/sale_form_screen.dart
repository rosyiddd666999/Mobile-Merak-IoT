import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/sale.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/providers/sales_provider.dart';
import '../../shared/detail_app_bar.dart';

class SaleFormScreen extends ConsumerStatefulWidget {
  final String? initialItem;
  final String? initialRef;

  const SaleFormScreen({super.key, this.initialItem, this.initialRef});

  @override
  ConsumerState<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends ConsumerState<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _itemController = TextEditingController();
  final _referensiController = TextEditingController();
  final _pembeliController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _hargaController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime _tanggal = DateTime.now();
  String _status = 'Booking';
  String _jenis = 'Indukan';
  String? _referensiId;
  bool _isSaving = false;
  bool _idPrefilled = false;
  bool _prefilled = false;

  static const _jenisOptions = ['Telur', 'Anakan', 'Indukan'];

  @override
  void dispose() {
    _idController.dispose();
    _itemController.dispose();
    _referensiController.dispose();
    _pembeliController.dispose();
    _qtyController.dispose();
    _hargaController.dispose();
    _catatanController.dispose();
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
    setState(() => _isSaving = true);

    final sale = Sale(
      id: _idController.text.trim(),
      tanggal: _tanggal.toIso8601String().substring(0, 10),
      item: _itemController.text.trim(),
      referensiId: _referensiController.text.trim(),
      pembeli: _pembeliController.text.trim(),
      qty: int.parse(_qtyController.text.trim()),
      hargaSatuan: double.parse(_hargaController.text.trim()),
      status: _status,
      catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
    );

    await ref.read(saleCreateProvider.notifier).create(sale);
    if (!mounted) return;
    setState(() => _isSaving = false);

    final state = ref.read(saleCreateProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    ref.invalidate(salesListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(saleCreateProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Penjualan berhasil ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider);

    // Prefill sekali dari query (mis. tombol Buat SPH).
    if (!_prefilled) {
      _prefilled = true;
      if (widget.initialItem != null && widget.initialItem!.isNotEmpty) {
        _itemController.text = widget.initialItem!;
      }
      if (widget.initialRef != null && widget.initialRef!.isNotEmpty) {
        _referensiId = widget.initialRef;
        _referensiController.text = widget.initialRef!;
      }
    }

    if (!_idPrefilled) {
      salesAsync.whenData((list) {
        if (!_idPrefilled) {
          _idPrefilled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _idController.text.isEmpty) {
              setState(() {
                _idController.text = nextId(
                  list.map((e) => e.id).toList(),
                  'SLS-',
                );
              });
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Penjualan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('ID Penjualan *'),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(hintText: 'SLS-001'),
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
              _label('Jenis *'),
              DropdownButtonFormField<String>(
                initialValue: _jenis,
                items: _jenisOptions
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _jenis = v!;
                  _referensiId = null;
                  _referensiController.clear();
                }),
              ),
              const SizedBox(height: 16),
              _label('Item *'),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(hintText: 'Anakan merak biru'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Referensi ID'),
              _referensiDropdown(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _applyRefToItem,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Isi item dari referensi'),
              ),
              const SizedBox(height: 16),
              _label('Pembeli *'),
              TextFormField(
                controller: _pembeliController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Qty *'),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Minimal 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Harga Satuan (Rp) *'),
              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Angka positif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _label('Status *'),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'Booking', child: Text('Booking')),
                  DropdownMenuItem(value: 'DP', child: Text('DP')),
                  DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                ],
                onChanged: (v) => setState(() => _status = v!),
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

  /// Dropdown ID sesuai jenis (Telur/Anakan/Indukan), sinkron ke controller.
  Widget _referensiDropdown() {
    final List<DropdownMenuItem<String>> items;
    switch (_jenis) {
      case 'Telur':
        final eggs = ref.watch(eggsListProvider).valueOrNull ?? const [];
        items = [for (final e in eggs) DropdownMenuItem(value: e.id, child: Text(e.id))];
        break;
      case 'Anakan':
        final chicks = ref.watch(chicksListProvider).valueOrNull ?? const [];
        items = [for (final c in chicks) DropdownMenuItem(value: c.id, child: Text(c.id))];
        break;
      default:
        final breeders = ref.watch(breedersListProvider).valueOrNull ?? const [];
        items = [
          for (final b in breeders)
            DropdownMenuItem(
              value: b.id,
              child: Text(b.nama?.isNotEmpty == true ? '${b.nama} (${b.id})' : b.id),
            ),
        ];
        break;
    }
    final valid = _referensiId != null && items.any((i) => i.value == _referensiId);
    return DropdownButtonFormField<String>(
      initialValue: valid ? _referensiId : null,
      items: items,
      decoration: const InputDecoration(hintText: 'Pilih ID (opsional)'),
      onChanged: (v) => setState(() {
        _referensiId = v;
        _referensiController.text = v ?? '';
      }),
    );
  }

  void _applyRefToItem() {
    if (_referensiId == null || _referensiId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih referensi dulu')),
      );
      return;
    }
    setState(() => _itemController.text = '$_jenis $_referensiId');
  }
}
