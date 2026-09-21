import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Pembungkus standar: Card + InkWell + Padding(16).
/// Gantikan pola `Card > InkWell > Padding > Row/Column` yang diduplikat
/// di breeder/egg/chick/sale/finance card + user_tile.
class AppTappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const AppTappableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Leading box 56x56 / 44x44 standar untuk card baris.
class AppLeadingBox extends StatelessWidget {
  final Widget child;
  final double size;
  final Color? color;

  const AppLeadingBox({
    super.key,
    required this.child,
    this.size = 56,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? AppColors.primaryTeal).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Card baris standar: leading + title/subtitle/meta + trailing/chevron.
/// Parameter dinamis agar 5 card + UserTile cukup pakai satu widget.
class AppRowCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? meta;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const AppRowCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTappableCard(
      onTap: onTap,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (meta != null) ...[
                  const SizedBox(height: 6),
                  meta!,
                ],
              ],
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}
