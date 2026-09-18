import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../data/providers/api_client_provider.dart';
import '../../../data/providers/secure_storage_provider.dart';

class ApiKeySettings extends ConsumerStatefulWidget {
  const ApiKeySettings({super.key});

  @override
  ConsumerState<ApiKeySettings> createState() => _ApiKeySettingsState();
}

class _ApiKeySettingsState extends ConsumerState<ApiKeySettings> {
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final storage = ref.read(secureStorageProvider);
    final key = await storage.read(key: 'api_key');
    _controller.text = key ?? '';
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final storage = ref.read(secureStorageProvider);
    final v = _controller.text.trim();
    if (v.isEmpty) {
      await storage.delete(key: 'api_key');
    } else {
      await storage.write(key: 'api_key', value: v);
    }
    ref.read(apiKeyProvider.notifier).state = v.isEmpty ? null : v;
    if (mounted) {
      setState(() => _testResult = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key tersimpan')));
    }
  }

  /// Kembalikan ke default .env (hapus override simpanan).
  Future<void> _reset() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'api_key');
    ref.read(apiKeyProvider.notifier).state = null;
    _controller.clear();
    if (mounted) {
      setState(() => _testResult = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kembali ke API Key default (.env)')),
      );
    }
  }

  /// Test connection: GET /auth/me (MOBILE.md §6.20).
  Future<void> _test() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/auth/me');
      if (!mounted) return;
      setState(() => _testResult = 'OK (${res.statusCode})');
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      setState(() => _testResult = code == 401
          ? 'Gagal: 401 — API Key salah'
          : code != null
              ? 'Gagal: HTTP $code'
              : 'Gagal: tidak terhubung (${e.type.name})');
    } catch (_) {
      if (mounted) setState(() => _testResult = 'Gagal: error tak dikenal');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('API Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Kosong = pakai default (.env). Default saat ini: ${AppConstants.apiKeyAndroid.isEmpty ? '-' : 'terisi'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Masukkan API Key'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _save, child: const Text('Simpan API Key')),
                OutlinedButton(onPressed: _reset, child: const Text('Reset default')),
                OutlinedButton(
                  onPressed: _isTesting ? null : _test,
                  child: Text(_isTesting ? 'Mengetes...' : 'Test koneksi'),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(_testResult!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
