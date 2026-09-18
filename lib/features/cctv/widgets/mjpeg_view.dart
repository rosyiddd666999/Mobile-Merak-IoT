import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mjpeg_view/mjpeg_view.dart';

/// Pembungkus package mjpeg_view dengan header auth (MOBILE.md §6.19.6).
/// MJPEG package tidak support header -> kirim via HttpClient ber-header.
class HeaderHttpClient extends http.BaseClient {
  final Map<String, String> headers;
  final http.Client _inner = http.Client();

  HeaderHttpClient(this.headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}

/// Player MJPEG multipart (JANGAN pakai Image.network — hanya 1 frame).
class MjpegPlayerView extends StatelessWidget {
  final Uri feedUri;
  final http.Client? client;
  final VoidCallback onError;
  final String label;

  const MjpegPlayerView({
    super.key,
    required this.feedUri,
    this.client,
    required this.onError,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MjpegView(
          // Key diganti saat Hubungkan Ulang -> paksa koneksi baru (?t=).
          key: ValueKey(feedUri.toString()),
          uri: feedUri.toString(),
          client: client,
          // Server resize ≤1280x720; batasi ~25 FPS di client (MOBILE.md §6.19.7).
          fps: 25,
          fit: BoxFit.contain,
          timeout: const Duration(seconds: 10),
          loadingWidget: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          onError: (_, _) => onError(),
          errorWidget: (_) => const SizedBox.shrink(),
          doneWidget: (_) => const SizedBox.shrink(),
        ),
        // Overlay grid + label ala CctvPage.jsx (non-interaktif).
        IgnorePointer(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                  ),
                ),
                child: Text(
                  '$label | LIVE MONITORING',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
