import 'package:flutter/material.dart';
import '../core/network/app_failure.dart';
import '../core/theme.dart';

/// Tampilan error standar.
/// - Konstruktor `message` (lama): pesan polos + tombol "Coba Lagi".
/// - `AppErrorWidget.failure`: dari [AppFailure] agar tiap request non-200
///   punya pesan + aksi spesifik (sesi berakhir -> "Masuk Kembali",
///   tanpa "Coba Lagi" sia-sia).
class AppErrorWidget extends StatelessWidget {
  final String? message;
  final AppFailure? failure;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;

  const AppErrorWidget({super.key, required this.message, this.onRetry})
      : failure = null,
        onLogin = null;

  const AppErrorWidget.failure({
    super.key,
    required this.failure,
    this.onRetry,
    this.onLogin,
  }) : message = null;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    final color = f == null
        ? AppColors.critical
        : (f.needsLogin ? AppColors.warning : AppColors.critical);
    final text = message ??
        (f!.action.isEmpty
            ? f.message.replaceFirst('Gagal  ', '')
            : f.message);
    final icon = f?.icon ?? Icons.error_outline;
    final showRetry =
        onRetry != null && (f == null || f.retryable);
    final showLogin = f?.needsLogin == true && onLogin != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (showLogin) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Masuk Kembali'),
              ),
            ] else if (showRetry) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
