import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Badge LIVE / MENYAMBUNG / OFFLINE (MOBILE.md §6.19/§9).
class CctvStatusBadge extends StatelessWidget {
  final bool? reachable;
  final bool checking;

  const CctvStatusBadge({super.key, required this.reachable, required this.checking});

  @override
  Widget build(BuildContext context) {
    final label = checking
        ? 'MENYAMBUNG'
        : reachable == true
            ? 'LIVE'
            : reachable == false
                ? 'OFFLINE'
                : 'MENYAMBUNG';
    final color = checking || reachable == null
        ? AppColors.warning
        : reachable == true
            ? AppColors.success
            : AppColors.critical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
