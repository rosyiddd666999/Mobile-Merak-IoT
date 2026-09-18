import 'package:flutter/material.dart';

/// Overlay error + tombol Hubungkan Ulang (MOBILE.md §6.19.4).
class CctvErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CctvErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Hubungkan Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
