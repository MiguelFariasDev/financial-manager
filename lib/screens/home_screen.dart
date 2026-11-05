import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../nav.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/tx_row.dart';

/// Início — "Primeira página" (dashboard A).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bottomPad});
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final income = a.income, spent = a.spent, commit = a.commit;
    final nuPaid = a.paid['nu'] == true, itPaid = a.paid['it'] == true;

    final dues = <_Due>[
      _Due('10', 'Fatura Nubank', 'Dia a dia ••4821', 2184.6, nuPaid ? 'Paga' : 'em 6 dias', urgent: !nuPaid, paid: nuPaid, cardId: 'nu'),
      _Due('15', 'Condomínio', 'PIX agendado', 680, 'em 11 dias'),
      _Due('18', 'Internet Vivo', 'Débito automático', 129.9, 'em 14 dias'),
      _Due('20', 'Fatura Itaú', 'Personnalité ••0937', 1315.5, itPaid ? 'Paga' : 'em 16 dias', paid: itPaid, cardId: 'it'),
    ];
    final months6 = <(String, double)>[('Jun', 6120), ('Jul', 7480), ('Ago', 6950), ('Set', 8210), ('Out', 7640), ('Nov', spent)];
    final recent = a.allTxs.where((t) => t.st != 'futura').take(4).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 14, 22, bottomPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          T('Bom dia, $kUserName.', 28, bold: true, ls: -.02),
          Transform.translate(
            offset: const Offset(10, 0),
            child: IconBox(a.dark ? 'sun' : 'moon', a.toggleDark, bg: false, label: 'Alternar tema'),
          ),
        ]),
        const SizedBox(height: 10),
        Container(height: 3, color: c.tx),
        const SizedBox(height: 2),
        Container(height: 1, color: c.tx),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Kicker(dayLine(), color: c.tx),
            Kicker('Dia $kTodayDay de $kDaysInMonth', color: c.tx),
          ]),
        ),
        Container(height: 1, color: c.tx),

        const SizedBox(height: 26),
        Kicker('Despesas de ${monthNames[kMonthIndex].toLowerCase()}', color: c.acInk),
        const SizedBox(height: 8),
        T(money(a.total), 50, bold: true, ls: -.03, height: 1),
        const SizedBox(height: 12),
        T('${money(spent)} já pagos e ${money(commit)} ainda por sair, contra uma receita de ${money(income)}.', 16,
            italic: true, color: c.tx2, height: 1.45),

        const SizedBox(height: 20),
        _MonthBar(spent: spent / income, commit: commit / income),
        const SizedBox(height: 14),
        Cols([
          Stat('Receita', money(income)),
          Stat('Já gasto', money(spent)),
          Stat('Ainda vai sair', money(commit)),
        ]),

        const SizedBox(height: 26),
        T('Saldo do mês · receita − despesas', 12, color: c.tx2),
        T(money(a.balance), 28, bold: true, ls: -.02, color: a.balance < 0 ? c.mInk : c.acInk),
        const SizedBox(height: 6),
        T(a.goalNote, 14, italic: true, height: 1.45, color: a.margin >= 0 ? c.tx2 : c.mInk),

        const SizedBox(height: 30),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            T('Saldo em contas hoje', 12, color: c.tx2),
            const SizedBox(height: 2),
            T('R\$ 18.420,35', 22, bold: true),
          ]),
          T('Itaú 12.300,00\nNubank 6.120,35', 13, color: c.tx2, height: 1.4, align: TextAlign.right),
        ]),
        const SizedBox(height: 6),
        T('Inclui dinheiro já comprometido — por isso é maior que o disponível.', 13, italic: true, color: c.tx2),

        const SizedBox(height: 40),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Vencimentos'),
          T('próximos 16 dias', 13, color: c.tx2),
        ]),
        const SizedBox(height: 8),
        for (final d in dues) _DueRow(d),

        const SizedBox(height: 36),
        const H2('Onde foi o dinheiro'),
        const SizedBox(height: 14),
        for (var i = 0; i < catData.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _CatRow(catData[i].$1, catData[i].$2, i == 0 ? c.tx : c.ac),
        ],

        const SizedBox(height: 36),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Seis meses'),
          T('média R\$ 7.040', 13, color: c.tx2),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < months6.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  T(oneDecimalPt(months6[i].$2 / 1000), 11, color: c.tx2, height: 1.2),
                  const SizedBox(height: 6),
                  Container(height: (months6[i].$2 / 9000 * 84).roundToDouble(), color: i == 5 ? c.ac : c.sf2),
                  const SizedBox(height: 6),
                  T(months6[i].$1, 12, bold: i == 5, height: 1.2),
                ]),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 36),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Faturas'),
          TextLink('Ver cartões', () => a.setTab(2)),
        ]),
        const SizedBox(height: 4),
        for (final card in a.cards) _InvoiceRow(card),

        const SizedBox(height: 32),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Últimas movimentações'),
          TextLink('Ver todas', () => a.setTab(1)),
        ]),
        for (final t in recent) TxRow(t),
      ]),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.spent, required this.commit});
  final double spent, commit;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = clamp01(spent), m = clamp01(commit).clamp(0.0, 1 - s);
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth;
      return SizedBox(
        height: 6,
        child: Row(children: [
          Container(width: w * s, color: c.tx),
          const SizedBox(width: 2),
          Container(width: w * m, color: c.tx3),
          const SizedBox(width: 2),
          Expanded(child: Container(color: c.ac)),
        ]),
      );
    });
  }
}

class _Due {
  _Due(this.day, this.title, this.sub, this.amt, this.when, {this.urgent = false, this.paid = false, this.cardId});
  final String day, title, sub, when;
  final double amt;
  final bool urgent, paid;
  final String? cardId;
}

class _DueRow extends StatelessWidget {
  const _DueRow(this.d);
  final _Due d;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: d.cardId == null ? null : () => openInvoice(context, d.cardId!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: Column(children: [
              T(d.day, 24, bold: true, height: 1, color: d.urgent ? c.mInk : c.tx),
              T('NOV', 11, ls: .08, color: c.tx2),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T(d.title, 15, bold: true),
              T('${d.when} · ${d.sub}', 13, color: d.urgent ? c.mInk : d.paid ? c.acInk : c.tx2),
            ]),
          ),
          T(money(d.amt), 15, bold: true),
        ]),
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  const _CatRow(this.k, this.v, this.color);
  final String k;
  final double v;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      SizedBox(width: 96, child: T(k, 14)),
      const SizedBox(width: 10),
      Expanded(child: Bar(v / 2150, color, c.sf, height: 8)),
      const SizedBox(width: 10),
      SizedBox(width: 82, child: T(money(v, symbol: false), 14, bold: true, align: TextAlign.right)),
    ]);
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.card);
  final CreditCard card;
  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    return Tap(
      onTap: () => openInvoice(context, card.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(width: 30, height: 20, decoration: BoxDecoration(color: card.bg, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              T('${card.bank} ${card.nick}', 15, bold: true),
              T('vence ${card.dueStr}', 13, color: c.tx2),
            ]),
          ),
          const SizedBox(width: 12),
          StatusTag(a.cardStatus(card)),
          const SizedBox(width: 12),
          SizedBox(width: 92, child: T(money(a.invTotal(card)), 15, bold: true, align: TextAlign.right)),
        ]),
      ),
    );
  }
}
