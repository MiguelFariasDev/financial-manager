import 'package:flutter/material.dart';
import '../data/models.dart';
import '../nav.dart';
import '../sheets/category_sheet.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'common.dart';

class TxRow extends StatelessWidget {
  const TxRow(this.t, {super.key, this.showPill = false});
  final Tx t;
  final bool showPill;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fut = t.st == 'futura', pend = t.st == 'pendente';
    final pill = fut ? 'Agendada ${t.due}' : pend ? 'A confirmar' : t.review ? 'Sem categoria' : '';
    final row = Opacity(
      opacity: fut ? .62 : 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            IconTile(t.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                T(t.d, 15, bold: true, maxLines: 1),
                T('${t.cat} · ${t.m} · ${t.acc}', 13, color: c.tx2, maxLines: 1),
              ]),
            ),
            const SizedBox(width: 12),
            if (showPill)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                T(money(t.amt, sign: true), 15, bold: true, color: t.amt > 0 ? c.acInk : c.tx),
                if (pill.isNotEmpty) ...[const SizedBox(height: 3), Pill(pill, fut ? c.sf : c.mSoft, fut ? c.tx2 : c.mInk)],
              ])
            else
              T(money(t.amt, sign: true), 15, bold: true, color: t.amt > 0 ? c.acInk : c.tx),
          ]),
        ),
      ),
    );
    return Tap(
      onTap: t.review ? () => showCategorySheet(context, t) : t.card == null ? null : () => openCard(context, t.card!),
      child: row,
    );
  }
}
