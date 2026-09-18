import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_client_provider.dart';
import 'secure_storage_provider.dart';

final currentUserProvider = StateProvider<User?>((ref) => null);

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthResponse?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthResponse?> {
  @override
  Future<AuthResponse?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) return null;
    ref.read(jwtTokenProvider.notifier).state = token;
    // User lengkap diisi via fetchMe() oleh splash setelah preload.
    return AuthResponse(accessToken: token, tokenType: 'bearer', user: User(
      id: '',
      email: '',
      nama: '',
      role: '',
    ));
  }

  Future<User?> fetchMe() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/auth/me');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final user = User.fromJson(data);
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 401) {
        await forceLogout();
        return null;
      }
      if (!kReleaseMode) {
        debugPrint('[AUTH fetchMe] failed: status=${e.response?.statusCode} type=${e.type.name} message=${e.message}');
        debugPrintStack(stackTrace: st, label: 'fetchMe');
      }
      return null;
    } catch (e, st) {
      if (!kReleaseMode) {
        debugPrint('[AUTH fetchMe] unexpected error: $e');
        debugPrintStack(stackTrace: st, label: 'fetchMe');
      }
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Format login tidak dikenal');
      }
      final authResponse = AuthResponse.fromJson(data);

      final storage = ref.read(secureStorageProvider);
      await storage.write(key: 'jwt_token', value: authResponse.accessToken);
      ref.read(jwtTokenProvider.notifier).state = authResponse.accessToken;

      ref.read(currentUserProvider.notifier).state = authResponse.user;
      return authResponse;
    });
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'jwt_token');
    ref.read(jwtTokenProvider.notifier).state = null;
    ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncData(null);
  }

  /// Dipanggil interceptor saat 401: bersihkan token + redirect ke login.
  Future<void> forceLogout() async {
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'jwt_token');
    } catch (_) {}
    ref.read(jwtTokenProvider.notifier).state = null;
    ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}

/// Preload api_key + jwt dari secure storage ke StateProvider (MOBILE.md §7.1).
Future<void> preloadAuthState(WidgetRef ref) async {
  final storage = ref.read(secureStorageProvider);
  try {
    final apiKey = await storage.read(key: 'api_key');
    if (apiKey != null && apiKey.isNotEmpty) {
      ref.read(apiKeyProvider.notifier).state = apiKey;
    }
  } catch (_) {}
  try {
    final token = await storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) {
      ref.read(jwtTokenProvider.notifier).state = token;
    }
  } catch (_) {}
}
