import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/validators.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/users_provider.dart';
import '../../shared/app_form.dart';
import '../../shared/detail_app_bar.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _fotoController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'staff';
  bool _isSaving = false;
  bool _obscure = true;
  bool _idPrefilled = false;

  @override
  void dispose() {
    _idController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _fotoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await ref.read(userCreateProvider.notifier).create(
      id: _idController.text.trim(),
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
      fotoUrl: _fotoController.text.trim().isEmpty ? null : _fotoController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    final state = ref.read(userCreateProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    ref.invalidate(usersListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(userCreateProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengguna berhasil ditambahkan')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);

    if (!_idPrefilled) {
      usersAsync.whenData((list) {
        if (!_idPrefilled) {
          _idPrefilled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _idController.text.isEmpty) {
              setState(() {
                _idController.text = nextId(
                  list.map((e) => e.id).toList(),
                  'USR-',
                );
              });
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Pengguna'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'ID Pengguna *',
                controller: _idController,
                validator: validateRequired,
                hint: 'USR-001',
              ),
              AppTextField(
                label: 'Nama *',
                controller: _namaController,
                validator: validateRequired,
              ),
              AppTextField(
                label: 'Email *',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                hint: 'user@example.com',
              ),
              AppTextField(
                label: 'URL Foto',
                controller: _fotoController,
                keyboardType: TextInputType.url,
                hint: 'https://... (opsional)',
              ),
              const AppLabel('Password *'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: validatePassword,
              ),
              const SizedBox(height: 16),
              const AppLabel('Role *'),
              DropdownButtonFormField<String>(
                initialValue: _role,
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(value: 'pemilik', child: Text('Pemilik')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              SaveButton(isSaving: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

}
