import 'package:flutter/material.dart';

/// Logo mitra kerjasama — dipakai di splash, login, dan header menu utama.
/// Sekali buat, parameter dinamis via [size].
/// [wide]: mode header — logo kotak tetap [size]×[size], logo Pertamina
/// yang memanjang menyesuaikan lebar ([size]×2.8) dengan fit contain.
class PartnerLogos extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool wide;

  const PartnerLogos({
    super.key,
    this.size = 40,
    this.showLabel = false,
    this.wide = false,
  });

  static const _squareLogo = 'assets/images/logo-kel-merak.jpeg';
  static const _wideLogo = 'assets/images/logo-pertamina.jpeg';

  Widget _box(String asset, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.05),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(_wideLogo, width: wide ? size * 2.8 : size, height: size),
        SizedBox(width: size * 0.22),
        _box(_squareLogo, width: size, height: size),
      ],
    );
    if (!showLabel) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Didukung oleh',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        row,
      ],
    );
  }
}
