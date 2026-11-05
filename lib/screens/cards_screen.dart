import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../nav.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key, required this.bottomPad});
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final totalLim = a.cards.fold(0.0, (s, e) => s + e.lim);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 14, 22, bottomPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Cartões', 30, bold: true, ls: -.02),
        const SizedBox(height: 2),
        T('${a.cards.length} cartões · ${money(totalLim)} de limite somado', 14, color: c.tx2),
        const SizedBox(height: 24),
        for (var i = 0; i < a.cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 36),
          _CardBlock(a.cards[i]),
        ],
      ]),
    );
  }
}

class _CardBlock extends StatelessWidget {
  const _CardBlock(this.card);
  final CreditCard card;
  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    return Tap(
      onTap: () => openCard(context, card.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CardFace(card, dotsRight: true),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            T('Fatura atual', 12, color: c.tx2),
            T(money(a.invTotal(card)), 22, bold: true),
          ]),
          StatusTag(a.cardStatus(card)),
        ]),
        const SizedBox(height: 14),
        Bar(card.used / card.lim, c.tx, c.sf),
        const SizedBox(height: 14),
        Cols([
          Stat('Usado', money(card.used), valueSize: 13),
          Stat('Disponível', money(card.lim - card.used), valueSize: 13, valueColor: c.acInk),
          Stat('Limite', money(card.lim), valueSize: 13),
        ], gap: 10),
        const SizedBox(height: 14),
        T('Fecha ${card.closeStr} · Vence ${card.dueStr}', 13, color: c.tx2),
      ]),
    );
  }
}
