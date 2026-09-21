import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Foto lingkaran dengan fallback: tampilkan [fallback] bila [url] kosong
/// atau gagal dimuat. Dipakai avatar user/chick/breeder.
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
    if (url == null || url!.isEmpty) {
      return CircleAvatar(radius: radius, backgroundColor: bg, child: fallback);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      imageBuilder: (_, provider) =>
          CircleAvatar(radius: radius, backgroundImage: provider),
      placeholder: (_, _) => CircleAvatar(
          radius: radius, backgroundColor: bg, child: fallback),
      errorWidget: (_, _, _) =>
          CircleAvatar(radius: radius, backgroundColor: bg, child: fallback),
    );
  }
}

/// Foto kotak leading card dengan fallback ikon.
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
    if (url == null || url!.isEmpty) {
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
        imageUrl: url!,
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
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: fallback,
        ),
      ),
    );
  }
}
