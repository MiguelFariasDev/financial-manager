import 'package:flutter/widgets.dart';
import 'phosphor_data.dart';

const _family = 'PhosphorDuotone';

/// Duotone Phosphor icon by prototype name (without the `ph-` prefix).
Widget phosphor(String name, {required double size, required Color color}) {
  final (primary, secondary) = phosphorDuotone[name] ?? phosphorDuotone['receipt']!;
  Widget glyph(int cp, Color col) => Text(
        String.fromCharCode(cp),
        style: TextStyle(fontFamily: _family, fontSize: size, color: col, height: 1, decoration: TextDecoration.none),
      );
  return SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      glyph(secondary, color.withValues(alpha: color.a * .2)),
      glyph(primary, color),
    ]),
  );
}
