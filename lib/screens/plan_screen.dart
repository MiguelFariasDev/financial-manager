import 'package:flutter/material.dart';
import '../app.dart';
import '../data/seed.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.bottomPad});
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final income = a.income, total = a.total;
    final all = a.allCardItems;
    final parcNow = all.where((i) => i.isInstallment && (i.p ?? 0) >= 1).fold(0.0, (s, i) => s + i.amt);
    final variable = (total - fixedExpenses - parcNow).clamp(0.0, double.infinity);
    final parts = <(String, double, Color)>[
      ('Despesas fixas', fixedExpenses, c.tx),
      ('Despesas variáveis', variable, c.c4),
      ('Parcelas de cartões', parcNow, c.ac),
      ('Saldo disponível', a.balance < 0 ? 0 : a.balance, c.sf2),
    ];

    final proj = List.generate(6, (k) {
      final par = all.where((i) => i.isInstallment).fold(0.0, (s, i) {
        final n = i.p! + k;
        return s + (n >= 1 && n <= i.n! ? i.amt : 0);
      });
      return (k: k, par: par, sal: income - fixedExpenses - variable - par);
    });
    final sc = 120 / income;
    final drop = proj.indexWhere((r) => r.k > 0 && proj[r.k - 1].par - r.par >= 300);
    final projNote = drop >= 0
        ? 'Em ${monthNames[(10 + drop) % 12].toLowerCase()} as parcelas caem para ${money(proj[drop].par)} e o saldo do mês sobe para ${money(proj[drop].sal)}.'
        : 'As parcelas se mantêm estáveis nos próximos meses.';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 14, 22, bottomPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Planejamento', 30, bold: true, ls: -.02),
        const SizedBox(height: 2),
        T('${monthNames[kMonthIndex]} 2026', 14, color: c.tx2),
        const SizedBox(height: 24),
        T('Renda mensal', 12, color: c.tx2),
        T(money(income), 40, bold: true, ls: -.03, height: 1.05),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (_, box) => SizedBox(
          height: 10,
          child: Row(children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Container(width: ((box.maxWidth - 6) * parts[i].$2 / income).clamp(0.0, box.maxWidth), color: parts[i].$3),
            ],
          ]),
        )),
        const SizedBox(height: 16),
        for (var i = 0; i < parts.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(children: [
              Swatch(parts[i].$3),
              const SizedBox(width: 10),
              Expanded(child: T(parts[i].$1, 15)),
              T(money(parts[i].$2), 15, bold: true),
            ]),
          ),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const T('Total comprometido', 15),
          T(money(total), 22, bold: true),
        ]),

        const SizedBox(height: 34),
        const H2('Meta de guardar'),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconBox('minus', () => a.setGoal(a.goal - 250), label: 'Diminuir meta'),
          T(money(a.goal), 28, bold: true, ls: -.02),
          IconBox('plus', () => a.setGoal(a.goal + 250), label: 'Aumentar meta'),
        ]),
        const SizedBox(height: 8),
        T(a.goalNote, 14, italic: true, height: 1.45, color: a.margin >= 0 ? c.tx2 : c.mInk),

        const SizedBox(height: 34),
        const H2('Limites por categoria'),
        for (final (k, v) in catData) _LimitRow(k, v),

        const SizedBox(height: 36),
        const H2('Próximos seis meses'),
        const SizedBox(height: 2),
        T('Fixas, média variável e parcelas já lançadas', 13, color: c.tx2),
        const SizedBox(height: 34),
        Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, right: 0, top: 0, child: CustomPaint(painter: _DottedLine(c.tx3), size: const Size(double.infinity, 2))),
          Positioned(right: 0, top: -18, child: T('renda ${money(income)}', 11, color: c.tx2)),
          Row(children: [
            for (var k = 0; k < 6; k++) ...[
              if (k > 0) const SizedBox(width: 10),
              Expanded(
                child: Column(children: [
                  SizedBox(
                    height: 120,
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(height: (proj[k].par * sc).roundToDouble(), color: c.ac),
                      Container(height: ((fixedExpenses + variable) * sc).roundToDouble(), color: c.tx),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  T(mAbbr(10 + k), 12, bold: k == 0),
                  const SizedBox(height: 4),
                  T('${oneDecimalPt(proj[k].sal / 1000)} mil', 11, color: c.acInk),
                ]),
              ),
            ],
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          T('▪ fixas + variáveis', 12, color: c.tx2),
          const SizedBox(width: 16),
          T('▪ parcelas', 12, color: c.acInk),
          const SizedBox(width: 16),
          T('valor = saldo', 12, color: c.tx2),
        ]),
        const SizedBox(height: 12),
        T(projNote, 15, italic: true, height: 1.45),
      ]),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow(this.k, this.v);
  final String k;
  final double v;
  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final lim = a.limits[k] ?? 1000;
    final over = v > lim;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: T(k, 15, bold: true)),
          IconBox('minus', () => a.setLimit(k, lim - 100), size: 18, label: 'Diminuir limite'),
          const SizedBox(width: 4),
          SizedBox(width: 88, child: T(money(lim), 14, bold: true, align: TextAlign.center)),
          const SizedBox(width: 4),
          IconBox('plus', () => a.setLimit(k, lim + 100), size: 18, label: 'Aumentar limite'),
        ]),
        const SizedBox(height: 4),
        Bar(v / lim, over ? c.m : c.ac, c.sf),
        const SizedBox(height: 5),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          T('${money(v)} gastos', 13, color: over ? c.mInk : c.tx2),
          T(over ? 'estourou ${money(v - lim)}' : 'restam ${money(lim - v)}', 13, color: over ? c.mInk : c.tx2),
        ]),
      ]),
    );
  }
}

class _DottedLine extends CustomPainter {
  _DottedLine(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double x = 0; x < size.width; x += 4) { canvas.drawRect(Rect.fromLTWH(x, 0, 2, 2), p); }
  }
  @override
  bool shouldRepaint(_DottedLine o) => o.color != color;
}
