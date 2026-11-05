import 'dart:async';
import 'package:flutter/material.dart';
import '../app.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'sheet_frame.dart';

void showPaySheet(BuildContext context, String cardId) {
  final app = context.app;
  showBsSheet(context, (_) => _PaySheet(app: app, cardId: cardId));
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.app, required this.cardId});
  final AppState app;
  final String cardId;
  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String opt = 'Total', from = 'Itaú · Conta corrente', phase = 'form';
  Timer? _t;
  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final card = widget.app.cardById(widget.cardId);
    final total = widget.app.invTotal(card);
    final minV = total * .15;
    final amt = opt == 'Total' ? total : minV;

    Widget radioRow(String label, String right, bool on, VoidCallback onTap, {bool strong = true}) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Tap(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52), padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: on ? c.sf : Colors.transparent, borderRadius: BorderRadius.circular(2)),
              child: Row(children: [
                Ph(on ? 'radio-button' : 'circle', size: 22, color: c.ac),
                const SizedBox(width: 12),
                Expanded(child: T(label, 15)),
                strong ? T(right, 15, bold: true) : T(right, 13, color: c.tx2),
              ]),
            ),
          ),
        );

    return SheetFrame(
      child: switch (phase) {
        'loading' => Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(children: [const Spinner(), const SizedBox(height: 14), T('Registrando pagamento…', 15, italic: true, color: c.tx2)]),
          ),
        'done' => Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Ph('seal-check', size: 44, color: c.acInk),
              const SizedBox(height: 8),
              const T('Pagamento registrado.', 24, bold: true),
              const SizedBox(height: 8),
              T('${money(amt)} saíram de $from. O limite do cartão será liberado em até 2 dias úteis.', 15, color: c.tx2, height: 1.5),
              const SizedBox(height: 14),
              PrimaryButton('Fechar', () => Navigator.of(context).pop()),
            ]),
          ),
        _ => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const T('Registrar pagamento', 24, bold: true),
            T('Fatura de novembro · ${card.bank} •• ${card.last}', 14, color: c.tx2),
            const SizedBox(height: 20),
            const Kicker('Valor'),
            const SizedBox(height: 8),
            radioRow('Total', money(total), opt == 'Total', () => setState(() => opt = 'Total')),
            radioRow('Mínimo', money(minV), opt == 'Mínimo', () => setState(() => opt = 'Mínimo')),
            const SizedBox(height: 14),
            const Kicker('Pago com'),
            const SizedBox(height: 8),
            radioRow('Itaú · Conta corrente', 'R\$ 12.300,00', from == 'Itaú · Conta corrente', () => setState(() => from = 'Itaú · Conta corrente'), strong: false),
            radioRow('Nubank · Conta', 'R\$ 6.120,35', from == 'Nubank · Conta', () => setState(() => from = 'Nubank · Conta'), strong: false),
            const SizedBox(height: 10),
            T(opt == 'Total' ? 'Registra a saída na conta escolhida e marca a fatura como paga.' : 'Pagar o mínimo gera juros rotativos sobre o restante no próximo mês.', 13, italic: true, color: c.tx2),
            const SizedBox(height: 18),
            PrimaryButton('Confirmar ${money(amt)}', () {
              setState(() => phase = 'loading');
              _t?.cancel();
              _t = Timer(const Duration(milliseconds: 1100), () {
                if (opt == 'Total') widget.app.markPaid(widget.cardId);
                if (mounted) setState(() => phase = 'done');
              });
            }),
          ]),
      },
    );
  }
}
