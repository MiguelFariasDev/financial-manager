import 'package:flutter/material.dart';
import '../app.dart';
import '../data/seed.dart';
import '../sheets/pay_sheet.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.cardId});
  final String cardId;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final card = a.cardById(cardId);
    final all = a.items(card);
    final total = a.invTotal(card);
    final st = a.cardStatus(card);

    final byCat = <String, double>{};
    for (final i in all.where((i) => i.p != 0)) { byCat[i.cat] = (byCat[i.cat] ?? 0) + i.amt; }
    final catList = byCat.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    final pal = c.catPalette;
    Color catColor(int i) => i < pal.length ? pal[i] : c.c5;

    final insts = all.where((i) => i.isInstallment && (i.p ?? 0) > 0).toList();
    final buys = all.where((i) => !i.isInstallment).toList();
    final paid = st == InvStatus.paga;
    final (note, noteColor) = paid
        ? ('Paga integralmente em 4 de novembro.', c.acInk)
        : st == InvStatus.fechada
            ? ('Fechada. Vence em 6 dias — pague até ${card.dueStr} para evitar juros.', c.mInk)
            : ('Aberta — ainda recebe compras até ${card.closeStr}.', c.tx2);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const PageHeader('Fatura'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Kicker('Novembro · ${card.bank} •• ${card.last}')),
                  StatusTag(st, withIcon: true),
                ]),
                const SizedBox(height: 10),
                T(money(total), 48, bold: true, ls: -.03, height: 1),
                const SizedBox(height: 10),
                T(note, 15, italic: true, color: noteColor),
                const SizedBox(height: 22),
                Cols([Stat('Fechamento', card.closeStr, valueSize: 17), Stat('Vencimento', card.dueStr, valueSize: 17)]),

                const SizedBox(height: 32),
                const H2('Por categoria'),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (_, box) => SizedBox(
                  height: 10,
                  child: Row(children: [
                    for (var i = 0; i < catList.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Container(width: (box.maxWidth - 2 * (catList.length - 1)) * catList[i].value / total, color: catColor(i)),
                    ],
                  ]),
                )),
                const SizedBox(height: 14),
                for (var i = 0; i < catList.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    child: Row(children: [
                      Swatch(catColor(i)),
                      const SizedBox(width: 10),
                      Expanded(child: T(catList[i].key, 14)),
                      T('${(catList[i].value / total * 100).round()}%', 14, color: c.tx2),
                      SizedBox(width: 84, child: T(money(catList[i].value), 14, bold: true, align: TextAlign.right)),
                    ]),
                  ),

                if (insts.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const H2('Parcelas cobradas'),
                    T(money(insts.fold(0.0, (s, i) => s + i.amt)), 14, color: c.tx2),
                  ]),
                  const SizedBox(height: 6),
                  for (final r in insts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40, alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
                          child: T(r.inst!, 13, bold: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            T(a.itemName(card.id, r), 15, bold: true),
                            T('${r.cat} · parcela ${r.inst}', 13, color: c.tx2),
                          ]),
                        ),
                        T(money(r.amt), 15, bold: true),
                      ]),
                    ),
                ],

                const SizedBox(height: 28),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const H2('Compras'),
                  T(money(buys.fold(0.0, (s, i) => s + i.amt)), 14, color: c.tx2),
                ]),
                const SizedBox(height: 6),
                for (final r in buys)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      IconTile(catIcon(r.cat)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          T(r.d, 15, bold: true),
                          T('${r.cat} · ${r.date}', 13, color: c.tx2),
                        ]),
                      ),
                      T(money(r.amt), 15, bold: true),
                    ]),
                  ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
            color: c.bg,
            child: paid
                ? SizedBox(
                    height: 52,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Ph('check-circle', size: 22, color: c.acInk),
                      const SizedBox(width: 8),
                      T('Pago em 4 de novembro', 16, bold: true, color: c.acInk),
                    ]),
                  )
                : PrimaryButton('Registrar pagamento', () => showPaySheet(context, cardId)),
          ),
        ]),
      ),
    );
  }
}
