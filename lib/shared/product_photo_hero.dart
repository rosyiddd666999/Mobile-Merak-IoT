import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Hero foto besar ala detail produk ecommerce: full-width, rasio 4:3,
/// overlay chip status + tombol fullscreen dengan pinch-zoom.
class ProductPhotoHero extends StatelessWidget {
  final String? url;
  final String heroTag;
  final Widget? statusChip;
  final Widget fallback;
  final double height;

  const ProductPhotoHero({
    super.key,
    this.url,
    required this.heroTag,
    this.statusChip,
    required this.fallback,
    this.height = 300,
  });

  String? get _clean {
    final v = url?.trim() ?? '';
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final clean = _clean;
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (clean == null)
                _FallbackView(fallback: fallback)
              else
                CachedNetworkImage(
                  imageUrl: clean,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _FallbackView(fallback: fallback),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.statusAlert.withValues(alpha: 0.1),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: AppColors.statusAlert,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Foto gagal dimuat',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.statusAlert,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Gradasi bawah agar overlay terbaca.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black38,
                      ],
                      stops: [0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              if (statusChip != null)
                Positioned(left: 16, top: 16, child: statusChip!),
              if (clean != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(100),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => openProductPhotoFullscreen(
                        context,
                        url: clean,
                        heroTag: '${heroTag}_fullscreen',
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              // Tap gambar juga membuka fullscreen.
              if (clean != null)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => openProductPhotoFullscreen(
                        context,
                        url: clean,
                        heroTag: '${heroTag}_fullscreen',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackView extends StatelessWidget {
  final Widget fallback;

  const _FallbackView({required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        fallback,
        const SizedBox(height: 8),
        const Text(
          'Belum ada foto',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Dialog fullscreen hitam dengan pinch-zoom via [InteractiveViewer].
void openProductPhotoFullscreen(
  BuildContext context, {
  required String url,
  required String heroTag,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: MediaQuery.of(context).padding.top + 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Tutup',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
