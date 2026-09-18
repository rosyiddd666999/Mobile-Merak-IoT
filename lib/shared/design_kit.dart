import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Chip status pill — 1 status = 1 warna tetap (DESIGN.md §1).
class StatusChip extends StatelessWidget {
  final String label;
  final AppStatus status;

  const StatusChip({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: status == AppStatus.neutral ? AppColors.textMuted : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Header section: judul 16/700 + trailing meta 12 teal (DESIGN.md §1).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const SectionHeader({super.key, required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty state standar: icon + teks (DESIGN.md §2).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner info collapsible (compatibility, BKSDA, dsb — DESIGN.md §2/§4).
class CollapsibleBanner extends StatefulWidget {
  final String collapsedLabel;
  final String title;
  final String body;
  final IconData icon;
  final bool initiallyExpanded;

  const CollapsibleBanner({
    super.key,
    required this.collapsedLabel,
    required this.title,
    required this.body,
    required this.icon,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleBanner> createState() => _CollapsibleBannerState();
}

class _CollapsibleBannerState extends State<CollapsibleBanner> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(widget.icon, size: 18, color: AppColors.primaryTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_less, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(widget.icon, size: 18, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.collapsedLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AppColors.textMuted),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Teks "-" untuk data kosong (disepakati: tampil, muted, bukan warna status).
class EmptyValue extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;

  const EmptyValue({super.key, this.fontSize = 13, this.fontWeight = FontWeight.w500});

  @override
  Widget build(BuildContext context) {
    return Text(
      '-',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: AppColors.emptyValue,
      ),
    );
  }
}
