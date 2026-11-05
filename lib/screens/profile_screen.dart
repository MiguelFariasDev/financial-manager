import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../data/seed.dart';
import '../nav.dart';
import '../sheets/import_sheet.dart';
import '../theme/tokens.dart';
import '../util/export.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.bottomPad});
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    const accounts = [
      ('Itaú', 'Conta corrente ••3021', 'R\$ 12.300,00', 'bank'),
      ('Nubank', 'Conta ••7714', 'R\$ 6.120,35', 'bank'),
      ('Carteira', 'Dinheiro', 'R\$ 0,00', 'wallet'),
    ];
    const history = [
      ('extrato_itau_outubro.ofx', '3 nov · 42 importadas', 'file-text'),
      ('nubank_conta_2026-09.csv', '4 out · 37 importadas', 'file-csv'),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 14, 22, bottomPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Perfil', 30, bold: true, ls: -.02),
        const SizedBox(height: 18),
        Row(children: [
          Container(width: 56, height: 56, alignment: Alignment.center, decoration: BoxDecoration(color: c.ac, borderRadius: BorderRadius.circular(2)), child: T('M', 26, bold: true, color: c.onAc)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const T('Marina Alves', 19, bold: true),
            Row(children: [Ph('device-mobile', size: 13, color: c.tx2), const SizedBox(width: 5), T('Dados guardados só neste aparelho', 13, color: c.tx2)]),
          ]),
        ]),

        const SizedBox(height: 32),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Renda mensal'),
          T('Acme Ltda · todo dia 3', 13, color: c.tx2),
        ]),
        const SizedBox(height: 4),
        T('R\$ 12.500,00', 26, bold: true),

        const SizedBox(height: 32),
        const H2('Contas bancárias'),
        const SizedBox(height: 6),
        for (final (name, sub, bal, icon) in accounts)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                IconTile(icon),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [T(name, 15, bold: true), T(sub, 13, color: c.tx2)])),
                T(bal, 15, bold: true),
              ]),
            ),
          ),

        const SizedBox(height: 28),
        const H2('Cartões cadastrados'),
        const SizedBox(height: 6),
        for (final card in a.cards)
          Tap(
            onTap: () => openCard(context, card.id),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(width: 40, height: 26, decoration: BoxDecoration(color: card.bg, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      T('${card.bank} ${card.nick}', 15, bold: true),
                      T('•• ${card.last} · limite ${_m(card.lim)}', 13, color: c.tx2),
                    ]),
                  ),
                  Ph('caret-right', size: 20, color: c.tx2),
                ]),
              ),
            ),
          ),

        const SizedBox(height: 28),
        const H2('Categorias'),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final k in cats)
            Container(
              height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Ph(k.icon, size: 18), const SizedBox(width: 6), T(k.k, 14)]),
            ),
        ]),

        const SizedBox(height: 32),
        const H2('Preferências'),
        const SizedBox(height: 14),
        const Kicker('Tema'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _ThemeButton('Claro', !a.dark, () => a.setDark(false))),
          const SizedBox(width: 6),
          Expanded(child: _ThemeButton('Escuro', a.dark, () => a.setDark(true))),
        ]),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const T('Lembrar vencimentos', 15, bold: true),
              T('Aviso 3 dias antes de faturas e contas', 13, color: c.tx2),
            ])),
            Semantics(
              toggled: a.remind, label: 'Lembrar vencimentos',
              child: Tap(
                onTap: a.toggleRemind,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52, height: 32,
                  decoration: BoxDecoration(color: a.remind ? c.ac : c.sf2, borderRadius: BorderRadius.circular(16)),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: a.remind ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(padding: const EdgeInsets.all(3), child: Container(width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: c.bg))),
                  ),
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 28),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const H2('Importações'),
          TextLink('Importar extrato', () => showImportSheet(context)),
        ]),
        const SizedBox(height: 2),
        for (final (name, sub, icon) in history)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Ph(icon, size: 24, color: c.acInk),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [T(name, 15, bold: true, maxLines: 1), T(sub, 13, color: c.tx2)])),
                Tap(onTap: () => a.showToast('Importação desfeita · $name'), child: SizedBox(height: 44, child: Center(child: T('Desfazer', 14, color: c.mInk)))),
              ]),
            ),
          ),

        const SizedBox(height: 28),
        const H2('Exportar dados'),
        const SizedBox(height: 6),
        T('Uma cópia completa para guardar fora do aparelho.', 14, italic: true, color: c.tx2),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: SecondaryButton('CSV', () async {
            await Clipboard.setData(ClipboardData(text: transactionsCsv(a)));
            a.showToast('Movimentações.csv copiado');
          }, icon: 'file-csv')),
          const SizedBox(width: 8),
          Expanded(child: SecondaryButton('Backup completo', () async {
            await Clipboard.setData(ClipboardData(text: backupJson(a)));
            a.showToast('Backup completo copiado');
          }, icon: 'file-code')),
        ]),
      ]),
    );
  }

  static String _m(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Container(
        height: 44, alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? c.tx : c.sf, borderRadius: BorderRadius.circular(2)),
        child: T(label, 16, bold: true, color: on ? c.bg : c.tx),
      ),
    );
  }
}
