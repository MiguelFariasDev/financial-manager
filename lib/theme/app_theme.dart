import 'package:flutter/material.dart';
import 'tokens.dart';

const kFont = 'SourceSerif4';

/// Text style helper: size in px, optional weight 600, italic, letter spacing in em.
TextStyle ts(double size, {bool bold = false, bool italic = false, Color? color, double ls = 0, double? height}) {
  return TextStyle(
    fontFamily: kFont,
    fontSize: size,
    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontVariations: [FontVariation('wght', bold ? 600 : 400)],
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: ls * size,
    height: height,
    color: color,
  );
}

ThemeData buildTheme(BsColors c) {
  return ThemeData(
    useMaterial3: true,
    brightness: c.dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: kFont,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(seedColor: c.ac, brightness: c.dark ? Brightness.dark : Brightness.light).copyWith(
      primary: c.ac, surface: c.bg, onSurface: c.tx,
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.ac, selectionColor: c.acSoft),
    extensions: [c],
  );
}
