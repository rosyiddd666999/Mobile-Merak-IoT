import 'package:flutter/material.dart';

/// Logo mitra kerjasama — dipakai di splash, login, dan header menu utama.
/// Sekali buat, parameter dinamis via [size].
class PartnerLogos extends StatelessWidget {
  final double size;
  final bool showLabel;

  const PartnerLogos({super.key, this.size = 40, this.showLabel = false});

  static const _assets = [
    'assets/images/logo-kel-merak.jpeg',
    'assets/images/logo-pertamina.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _assets.length; i++) ...[
          if (i > 0) SizedBox(width: size * 0.22),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.07),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.25),
              border: Border.all(color: const Color(0xFFE6ECEA)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.18),
              child: Image.asset(_assets[i], fit: BoxFit.cover),
            ),
          ),
        ],
      ],
    );
    if (!showLabel) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Didukung oleh',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        row,
      ],
    );
  }
}
