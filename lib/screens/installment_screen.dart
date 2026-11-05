import 'package:flutter/material.dart';
import '../app.dart';
import '../sheets/edit_sheet.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class InstallmentScreen extends StatelessWidget {
  const InstallmentScreen({super.key, required this.cardId, required this.itemDesc});
  final String cardId, itemDesc;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final card = a.cardById(cardId);
    final it = a.items(card).firstWhere((i) => i.d == itemDesc && i.isInstallment);
    final name = a.itemName(cardId, it);
    final n = it.n!, p = it.p!, pr = it.amt;
    final cardPaid = a.paid[cardId] == true;
    final paidN = (p - 1 < 0 ? 0 : p - 1) + (p >= 1 && cardPaid ? 1 : 0);
    String mo(int i) => mshort(10 + i - p);
    final income = a.income;
    void edit() => showEditSheet(context, cardId, itemDesc, name);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          PageHeader('Compra parcelada', trailing: Tap(onTap: edit, child: Align(alignment: Alignment.centerRight, child: T('Editar', 16, color: c.acInk)))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Kicker('${card.bank} ${card.nick} •• ${card.last}'),
                const SizedBox(height: 6),
                T(name, 28, bold: true, ls: -.02),
                const SizedBox(height: 12),
                T(money(pr * n), 44, bold: true, ls: -.03, height: 1.05),
                const SizedBox(height: 4),
                T('em $n× de ${money(pr)}', 16, italic: true, color: c.tx2),
                const SizedBox(height: 20),
                Segs([for (var k = 0; k < n; k++) k < paidN ? c.tx : k == p - 1 ? c.ac : c.sf2], height: 6),
                const SizedBox(height: 16),
                Cols([
                  Stat('Pagas', '$paidN de $n', sub: money(pr * paidN)),
                  Stat('Faltam', '${n - paidN}', sub: money(pr * (n - paidN))),
                  Stat('Quita em', mo(n)),
                ]),

                const SizedBox(height: 34),
                const H2('Impacto nos próximos meses'),
                const SizedBox(height: 6),
                T('Esta compra pesa ${money(pr)} por mês (${oneDecimalPt(pr / income * 100)}% da renda). Depois da última parcela, em ${mo(n)}, esse valor volta para o seu saldo.',
                    15, italic: true, color: c.tx2, height: 1.45),
                const SizedBox(height: 14),
                Row(children: [
                  for (var k = 0; k < 6; k++) ...[
                    if (k > 0) const SizedBox(width: 6),
                    Expanded(child: _Next(mAbbr(10 + k), (p + k) >= 1 && (p + k) <= n ? money(pr, symbol: false) : null)),
                  ],
                ]),

                const SizedBox(height: 34),
                const H2('Cronograma'),
                const SizedBox(height: 10),
                for (var i = 1; i <= n; i++) _TimelineRow(i: i, n: n, p: p, cardPaid: cardPaid, dueStr: card.dueStr, month: mo(i), amt: pr),
                const SizedBox(height: 22),
                SecondaryButton('Editar compra', edit),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Next extends StatelessWidget {
  const _Next(this.month, this.value);
  final String month;
  final String? value;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final on = value != null;
    return Column(children: [
      T(month, 12, color: c.tx2),
      Container(height: 6, margin: const EdgeInsets.symmetric(vertical: 6), color: on ? c.ac : c.sf),
      T(value ?? '—', 12, bold: true, color: on ? c.tx : c.tx2),
    ]);
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.i, required this.n, required this.p, required this.cardPaid, required this.dueStr, required this.month, required this.amt});
  final int i, n, p;
  final bool cardPaid;
  final String dueStr, month;
  final double amt;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final done = i < p || (i == p && cardPaid);
    final cur = i == p && !cardPaid;
    final st = done ? 'Paga' : i == p ? 'Na fatura atual · $dueStr' : 'Futura';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 14,
            child: Stack(children: [
              Positioned(left: 6, top: 0, bottom: 0, width: 2, child: Container(color: i <= p ? c.tx : c.sf2)),
              Positioned(
                left: 0, top: 16,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: done ? c.tx : cur ? c.ac : c.sf2, border: Border.all(color: c.bg, width: 2)),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T('$i/$n · fatura de $month', 15, bold: true),
                T(st, 13, color: cur ? c.acInk : c.tx2),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Opacity(opacity: done ? .6 : 1, child: T(money(amt), 15, bold: true)),
          ),
        ]),
      ),
    );
  }
}
