import 'package:flutter/material.dart';

/// Broadsheet palette (light/dark), ported from the Finance App prototype.
class BsColors extends ThemeExtension<BsColors> {
  const BsColors({
    required this.bg, required this.sf, required this.sf2,
    required this.tx, required this.tx2, required this.tx3,
    required this.ac, required this.acInk, required this.acSoft,
    required this.m, required this.mInk, required this.mSoft,
    required this.onAc, required this.c2, required this.c3,
    required this.c4, required this.c5, required this.dark,
  });

  final Color bg, sf, sf2, tx, tx2, tx3, ac, acInk, acSoft, m, mInk, mSoft, onAc, c2, c3, c4, c5;
  final bool dark;

  static const light = BsColors(
    bg: Color(0xFFF3F2F2), sf: Color(0xFFEAE7E7), sf2: Color(0xFFD7D3D3),
    tx: Color(0xFF201E1D), tx2: Color(0xFF605D5D), tx3: Color(0xFF9B9797),
    ac: Color(0xFF0088B0), acInk: Color(0xFF006786), acSoft: Color(0xFFCBEEFF),
    m: Color(0xFFD6006C), mInk: Color(0xFFAA0B56), mSoft: Color(0xFFFFDEE6),
    onAc: Color(0xFFF3F2F2), c2: Color(0xFF38A6CF), c3: Color(0xFF99E0FF),
    c4: Color(0xFF7D7979), c5: Color(0xFFBAB6B6), dark: false,
  );

  static const darkTheme = BsColors(
    bg: Color(0xFF1B1918), sf: Color(0xFF2D2B2B), sf2: Color(0xFF444141),
    tx: Color(0xFFF3F2F2), tx2: Color(0xFFBAB6B6), tx3: Color(0xFF7D7979),
    ac: Color(0xFF62C5EE), acInk: Color(0xFF99E0FF), acSoft: Color(0xFF0A303E),
    m: Color(0xFFFF90B1), mInk: Color(0xFFFFC0D0), mSoft: Color(0xFF4B1528),
    onAc: Color(0xFF1B1918), c2: Color(0xFF1186AC), c3: Color(0xFF004961),
    c4: Color(0xFF9B9797), c5: Color(0xFF605D5D), dark: true,
  );

  /// Category palette used by the invoice breakdown.
  List<Color> get catPalette => [tx, ac, c2, c3, c4, c5];

  // Shadows from the design system (--shadow-sm/md/lg).
  static const _sh = Color(0xFF2D2B2B);
  static List<BoxShadow> get shadowSm => [BoxShadow(color: _sh.withValues(alpha: .14), blurRadius: 2, offset: const Offset(0, 1))];
  static List<BoxShadow> get shadowMd => [BoxShadow(color: _sh.withValues(alpha: .16), blurRadius: 10, offset: const Offset(0, 3))];
  static List<BoxShadow> get shadowLg => [BoxShadow(color: _sh.withValues(alpha: .22), blurRadius: 32, offset: const Offset(0, 12))];

  @override
  BsColors copyWith() => this;

  @override
  BsColors lerp(ThemeExtension<BsColors>? other, double t) {
    if (other is! BsColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return BsColors(
      bg: l(bg, other.bg), sf: l(sf, other.sf), sf2: l(sf2, other.sf2),
      tx: l(tx, other.tx), tx2: l(tx2, other.tx2), tx3: l(tx3, other.tx3),
      ac: l(ac, other.ac), acInk: l(acInk, other.acInk), acSoft: l(acSoft, other.acSoft),
      m: l(m, other.m), mInk: l(mInk, other.mInk), mSoft: l(mSoft, other.mSoft),
      onAc: l(onAc, other.onAc), c2: l(c2, other.c2), c3: l(c3, other.c3),
      c4: l(c4, other.c4), c5: l(c5, other.c5), dark: t < .5 ? dark : other.dark,
    );
  }
}

extension BsContext on BuildContext {
  BsColors get c => Theme.of(this).extension<BsColors>()!;
}
