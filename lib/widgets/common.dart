import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/seed.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'icons.dart';

/// Themed text: size in px, tx colour by default.
class T extends StatelessWidget {
  const T(this.text, this.size,
      {super.key, this.bold = false, this.italic = false, this.color, this.ls = 0, this.height, this.align, this.maxLines, this.upper = false});
  final String text;
  final double size, ls;
  final bool bold, italic, upper;
  final Color? color;
  final double? height;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: ts(size, bold: bold, italic: italic, color: color ?? context.c.tx, ls: ls, height: height),
      );
}

class Ph extends StatelessWidget {
  const Ph(this.name, {super.key, this.size = 20, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: phosphor(name, size: size, color: color ?? context.c.tx));
}

/// 11px uppercase kicker used for datelines and field labels.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => T(text.toUpperCase(), 11, bold: true, ls: .1, color: color ?? context.c.tx2);
}

class H2 extends StatelessWidget {
  const H2(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => T(text, 21, bold: true);
}

/// Tappable area with a minimum 44px target.
class Tap extends StatelessWidget {
  const Tap({super.key, required this.onTap, required this.child, this.label});
  final VoidCallback? onTap;
  final Widget child;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true, label: label,
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
      );
}

class TextLink extends StatelessWidget {
  const TextLink(this.text, this.onTap, {super.key, this.color, this.size = 14});
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: T(text, size, color: color ?? context.c.acInk)),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, this.onTap, {super.key, this.height = 52, this.fontSize = 17, this.opacity = 1, this.expand = true, this.padding = 18.0});
  final String label;
  final VoidCallback? onTap;
  final double height, fontSize, opacity, padding;
  final bool expand;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final box = Container(
      height: height,
      width: expand ? double.infinity : null,
      padding: expand ? null : EdgeInsets.symmetric(horizontal: padding),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.ac, borderRadius: BorderRadius.circular(2)),
      child: T(label, fontSize, bold: true, color: c.onAc),
    );
    return Opacity(opacity: opacity, child: Tap(onTap: onTap, child: box));
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(this.label, this.onTap, {super.key, this.icon});
  final String label;
  final String? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Container(
        height: icon == null ? 52 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Ph(icon!, size: 20), const SizedBox(width: 8)],
          T(label, icon == null ? 17 : 16, bold: true),
        ]),
      ),
    );
  }
}

/// 44x44 square button on the `sf` surface (or bare).
class IconBox extends StatelessWidget {
  const IconBox(this.icon, this.onTap, {super.key, this.size = 22, this.bg = true, this.label, this.color});
  final String icon;
  final VoidCallback onTap;
  final double size;
  final bool bg;
  final String? label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap, label: label,
      child: Container(
        width: 44, height: 44, alignment: Alignment.center,
        decoration: BoxDecoration(color: bg ? c.sf : null, borderRadius: BorderRadius.circular(2)),
        child: Ph(icon, size: size, color: color),
      ),
    );
  }
}

/// 40x40 icon tile used in list rows.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key});
  final String icon;
  @override
  Widget build(BuildContext context) => Container(
        width: 40, height: 40, alignment: Alignment.center,
        decoration: BoxDecoration(color: context.c.sf, borderRadius: BorderRadius.circular(2)),
        child: Ph(icon, size: 20),
      );
}

class TagInfo {
  const TagInfo(this.label, this.bg, this.fg, this.icon, {this.border});
  final String label, icon;
  final Color bg, fg;
  final Color? border;
}

TagInfo tagFor(BuildContext context, InvStatus st) {
  final c = context.c;
  switch (st) {
    case InvStatus.aberta: return TagInfo('Aberta', c.acSoft, c.acInk, 'circle-dashed');
    case InvStatus.fechada: return TagInfo('Fechada', c.mSoft, c.mInk, 'lock-simple');
    case InvStatus.paga: return TagInfo('Paga', c.sf, c.tx2, 'check');
    case InvStatus.atrasada: return TagInfo('Atrasada', c.m, c.onAc, 'warning');
    case InvStatus.prevista: return TagInfo('Prevista', Colors.transparent, c.tx2, 'clock', border: c.sf2);
  }
}

InvStatus statusFromLabel(String s) => switch (s) {
      'Aberta' => InvStatus.aberta,
      'Fechada' => InvStatus.fechada,
      'Paga' => InvStatus.paga,
      'Atrasada' => InvStatus.atrasada,
      _ => InvStatus.prevista,
    };

class StatusTag extends StatelessWidget {
  const StatusTag(this.status, {super.key, this.withIcon = false});
  final InvStatus status;
  final bool withIcon;
  @override
  Widget build(BuildContext context) {
    final t = tagFor(context, status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: withIcon ? 9 : 8, vertical: 3),
      decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(2), border: t.border == null ? null : Border.all(color: t.border!)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (withIcon) ...[Ph(t.icon, size: 12, color: t.fg), const SizedBox(width: 4)],
        T(t.label, withIcon ? 12 : 11, color: t.fg),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, this.bg, this.fg, {super.key});
  final String text;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2)),
        child: T(text, 11, color: fg),
      );
}

/// Segmented progress strips (installments), `gap` 2px.
class Segs extends StatelessWidget {
  const Segs(this.colors, {super.key, this.height = 5});
  final List<Color> colors;
  final double height;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < colors.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(child: Container(height: height, color: colors[i])),
        ],
      ]);
}

/// Flat horizontal bar: [fill] fraction of the [track].
class Bar extends StatelessWidget {
  const Bar(this.fraction, this.fill, this.track, {super.key, this.height = 6});
  final double fraction, height;
  final Color fill, track;
  @override
  Widget build(BuildContext context) => Container(
        height: height, color: track, alignment: Alignment.centerLeft,
        child: FractionallySizedBox(widthFactor: fraction.clamp(0, 1), child: Container(height: height, color: fill)),
      );
}

class Swatch extends StatelessWidget {
  const Swatch(this.color, {super.key, this.size = 10});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, color: color);
}

/// Sticky top bar of pushed pages: back chevron, title, optional trailing.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(children: [
        Tap(
          label: 'Voltar',
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox(width: 44, height: 44, child: Align(alignment: Alignment.centerLeft, child: Ph('caret-left', size: 20, color: c.acInk))),
        ),
        Expanded(child: Center(child: T(title, 16, bold: true))),
        SizedBox(width: trailing == null ? 44 : 62, child: trailing),
      ]),
    );
  }
}

/// The physical card face with the halftone dot screen.
class CardFace extends StatelessWidget {
  const CardFace(this.card, {super.key, this.dotsRight = false});
  final dynamic card; // CreditCard
  final bool dotsRight;
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFF3F2F2);
    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: card.bg, borderRadius: BorderRadius.circular(4),
        boxShadow: BsColors.shadowMd,
      ),
      foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: ink.withValues(alpha: .12))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          painter: _DotsPainter(rightAligned: dotsRight),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T(card.bank, 19, bold: true, color: ink),
                  T(card.nick, 14, italic: true, color: ink.withValues(alpha: .8)),
                ]),
                const Ph('contactless-payment', size: 26, color: ink),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                T('•••• ${card.last}', 18, color: ink, ls: .14),
                T(card.net, 13, color: ink.withValues(alpha: .8)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.rightAligned});
  final bool rightAligned;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFF3F2F2).withValues(alpha: .16);
    const step = 7.0;
    final ox = rightAligned ? size.width % step : 0.0;
    for (double y = 0; y < size.height + step; y += step) {
      for (double x = ox; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x + step / 2, y + step / 2), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.rightAligned != rightAligned;
}

/// A 3-column "label / value" grid used in several summaries.
class Stat extends StatelessWidget {
  const Stat(this.label, this.value, {super.key, this.sub, this.valueColor, this.valueSize = 16});
  final String label, value;
  final String? sub;
  final Color? valueColor;
  final double valueSize;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      T(label, 12, color: c.tx2),
      const SizedBox(height: 2),
      T(value, valueSize, bold: true, color: valueColor),
      if (sub != null) T(sub!, 13, color: c.tx2),
    ]);
  }
}

class Cols extends StatelessWidget {
  const Cols(this.children, {super.key, this.gap = 12});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: children[i]),
        ],
      ]);
}

String dayLine() => 'Quarta, $kTodayDay de ${monthNames[kMonthIndex].toLowerCase()}';

double clamp01(double v) => math.max(0, math.min(1, v));
