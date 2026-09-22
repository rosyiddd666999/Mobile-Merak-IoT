import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Bersihkan URL: trim + anggap kosong bila hanya spasi.
String? _cleanUrl(String? url) {
  final v = url?.trim() ?? '';
  return v.isEmpty ? null : v;
}

/// Ikon penanda "URL ada tapi gagal dimuat" (bedakan dari "belum ada foto").
Widget _brokenIcon(double size, Color color) => Icon(
      Icons.broken_image_outlined,
      size: size,
      color: color,
    );

/// Foto lingkaran: tampilkan foto bila URL valid, [fallback] bila kosong,
/// ikon rusak bila URL ada tapi gagal dimuat. Dipakai avatar user/chick/breeder.
class AppPhotoCircle extends StatelessWidget {
  final String? url;
  final double radius;
  final Widget fallback;
  final Color backgroundColor;

  const AppPhotoCircle({
    super.key,
    this.url,
    this.radius = 24,
    required this.fallback,
    this.backgroundColor = AppColors.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor.withValues(alpha: 0.12);
    final clean = _cleanUrl(url);
    if (clean == null) {
      return CircleAvatar(radius: radius, backgroundColor: bg, child: fallback);
    }
    return CachedNetworkImage(
      imageUrl: clean,
      imageBuilder: (_, provider) =>
          CircleAvatar(radius: radius, backgroundImage: provider),
      placeholder: (_, _) => CircleAvatar(
          radius: radius, backgroundColor: bg, child: fallback),
      errorWidget: (_, _, _) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.statusAlert.withValues(alpha: 0.1),
        child: _brokenIcon(radius, AppColors.statusAlert),
      ),
    );
  }
}

/// Foto kotak leading card: perilaku sama dengan [AppPhotoCircle].
class AppPhotoBox extends StatelessWidget {
  final String? url;
  final double size;
  final Widget fallback;

  const AppPhotoBox({
    super.key,
    this.url,
    this.size = 56,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final clean = _cleanUrl(url);
    if (clean == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: fallback,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: clean,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          width: size,
          height: size,
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          child: fallback,
        ),
        errorWidget: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.statusAlert.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _brokenIcon(
              size * 0.5, AppColors.statusAlert),
        ),
      ),
    );
  }
}
