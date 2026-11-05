import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../nav.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.cardId});
  final String cardId;
  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  String tab = 'Atual';

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final card = a.cardById(widget.cardId);
    final parcels = a.items(card).where((i) => i.isInstallment).toList();

    final rows = switch (tab) {
      'Anteriores' => [for (final (m, v) in card.prev) _InvRow(m, v == 0 ? 'Sem compras' : 'Paga', v, InvStatus.paga)],
      'Próximas' => [for (final n in card.next) _InvRow(n.month, n.st == 'Aberta' ? 'Recebendo compras' : 'Só parcelas já lançadas', n.amt, statusFromLabel(n.st))],
      _ => [_InvRow('Novembro', 'Fecha ${card.closeStr} · vence ${card.dueStr}', a.invTotal(card), a.cardStatus(card), current: true)],
    };

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          PageHeader('${card.bank} ${card.nick}'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CardFace(card),
                const SizedBox(height: 22),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  T('Limite disponível', 13, color: c.tx2),
                  T('de ${money(card.lim)}', 13, color: c.tx2),
                ]),
                T(money(card.lim - card.used), 30, bold: true, ls: -.02, color: c.acInk),
                const SizedBox(height: 8),
                Bar(card.used / card.lim, c.tx, c.sf),

                const SizedBox(height: 34),
                const H2('Faturas'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
                  child: Row(children: [
                    for (final k in ['Anteriores', 'Atual', 'Próximas']) ...[
                      if (k != 'Anteriores') const SizedBox(width: 3),
                      Expanded(child: _SegButton(k, tab == k, () => setState(() => tab = k))),
                    ],
                  ]),
                ),
                const SizedBox(height: 8),
                for (final r in rows) r.build(context, () => openInvoice(context, card.id)),

                const SizedBox(height: 30),
                const H2('Compras parceladas'),
                const SizedBox(height: 14),
                for (var i = 0; i < parcels.length; i++) ...[
                  if (i > 0) const SizedBox(height: 18),
                  _ParcelRow(card, parcels[i]),
                ],

                const SizedBox(height: 30),
                const H2('Compras recentes'),
                const SizedBox(height: 2),
                T(card.recentNote, 13, color: c.tx2),
                const SizedBox(height: 6),
                for (final r in card.recent)
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
        ]),
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Container(
        height: 36, alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? c.bg : Colors.transparent, borderRadius: BorderRadius.circular(2), boxShadow: on ? BsColors.shadowSm : null),
        child: T(label, 14, bold: true, color: on ? c.tx : c.tx2),
      ),
    );
  }
}

class _InvRow {
  _InvRow(this.month, this.sub, this.amt, this.st, {this.current = false});
  final String month, sub;
  final double amt;
  final InvStatus st;
  final bool current;

  Widget build(BuildContext context, VoidCallback open) {
    final c = context.c;
    return Tap(
      onTap: current ? open : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(month, 15, bold: true),
                T(sub, 13, color: c.tx2),
              ]),
            ),
            const SizedBox(width: 12),
            StatusTag(st),
            const SizedBox(width: 12),
            SizedBox(width: 92, child: T(money(amt), 15, bold: true, align: TextAlign.right)),
            const SizedBox(width: 12),
            Opacity(opacity: current ? 1 : 0, child: Ph('caret-right', size: 16, color: c.tx2)),
          ]),
        ),
      ),
    );
  }
}

class _ParcelRow extends StatelessWidget {
  const _ParcelRow(this.card, this.i);
  final CreditCard card;
  final CardItem i;
  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final n = i.n!, p = i.p!;
    return Tap(
      onTap: () => openInstallment(context, card.id, i.d),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: T(a.itemName(card.id, i), 15, bold: true)),
          T('${money(i.amt)}/mês', 15, bold: true),
        ]),
        const SizedBox(height: 7),
        Segs([for (var k = 0; k < n; k++) k < p - 1 ? c.tx : k == p - 1 ? c.ac : c.sf2]),
        const SizedBox(height: 7),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          T(p > 0 ? 'Parcela $p de $n' : 'Começa na próxima fatura · $n×', 13, color: c.tx2),
          T('faltam ${money(i.amt * (n - p))}', 13, color: c.tx2),
        ]),
      ]),
    );
  }
}
