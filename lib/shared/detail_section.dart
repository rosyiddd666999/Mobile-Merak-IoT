import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Judul section detail — gantikan `_sectionTitle` di 6 detail screen.
class DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DetailSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Baris info ikon + label + value — gantikan `_infoRow` di 6 detail.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Divider tipis antar section detail.
class DetailDivider extends StatelessWidget {
  const DetailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5);
  }
}

/// Kartu catatan — gantikan blok `if (x.catatan != null)` di 4 detail.
class DetailNote extends StatelessWidget {
  final String? note;

  const DetailNote(this.note, {super.key});

  @override
  Widget build(BuildContext context) {
    if (note == null || note!.trim().isEmpty) return const SizedBox.shrink();
    return DetailSection(
      title: 'Catatan',
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(note!, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ],
    );
  }
}
