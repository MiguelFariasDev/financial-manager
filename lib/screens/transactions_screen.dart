import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../sheets/import_sheet.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/tx_row.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.bottomPad});
  final double bottomPad;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String filter = 'Todas', cat = 'Todas', q = '';
  bool catOpen = false;
  int month = kMonthIndex;

  static const filters = ['Todas', 'Receitas', 'Despesas', 'PIX', 'Débito', 'Crédito', 'Dinheiro'];

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final monthTxs = a.allTxs.where((t) => t.monthIdx == month).toList();
    var list = monthTxs;
    list = list.where((t) => filter == 'Todas' || (filter == 'Receitas' && t.amt > 0) || (filter == 'Despesas' && t.amt < 0) || t.m == filter).toList();
    if (cat != 'Todas') list = list.where((t) => t.cat == cat).toList();
    final query = q.trim().toLowerCase();
    if (query.isNotEmpty) list = list.where((t) => t.d.toLowerCase().contains(query)).toList();

    final groups = <String, List<Tx>>{};
    for (final t in list) { groups.putIfAbsent(t.day, () => []).add(t); }
    final labels = groups.keys.toList(); // allTxs is already newest-first
    groups['Agendadas']?.sort((x, y) => x.date.compareTo(y.date));
    final done = list.where((t) => t.st != 'futura');
    final inSum = done.where((t) => t.amt > 0).fold(0.0, (s, t) => s + t.amt);
    final outSum = done.where((t) => t.amt < 0).fold(0.0, (s, t) => s - t.amt);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 14, 22, widget.bottomPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const T('Movimentações', 30, bold: true, ls: -.02),
          IconBox('file-arrow-down', () => showImportSheet(context), label: 'Importar extrato'),
        ]),
        const SizedBox(height: 16),
        Container(
          height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
          child: Row(children: [
            Ph('magnifying-glass', size: 18, color: c.tx2),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                style: ts(16, color: c.tx),
                cursorColor: c.ac,
                decoration: InputDecoration(
                  isCollapsed: true, border: InputBorder.none, hintText: 'Buscar descrição',
                  hintStyle: ts(16, color: c.tx2),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Transform.translate(offset: const Offset(-12, 0), child: IconBox('caret-left', () => setState(() => month = month > -60 ? month - 1 : month), bg: false, size: 18, label: 'Mês anterior')),
          T(monthTitle(month), 17, bold: true),
          Transform.translate(offset: const Offset(12, 0), child: IconBox('caret-right', () => setState(() => month = month < 11 ? month + 1 : 11), bg: false, size: 18, label: 'Próximo mês')),
        ]),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal, clipBehavior: Clip.none,
            children: [for (final f in filters) Padding(padding: const EdgeInsets.only(right: 6), child: _Chip(f, filter == f, () => setState(() => filter = f)))],
          ),
        ),
        const SizedBox(height: 8),
        Tap(
          onTap: () => setState(() => catOpen = !catOpen),
          child: SizedBox(
            height: 36,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(width: 12),
              Ph('tag', size: 16, color: c.acInk),
              const SizedBox(width: 6),
              T('Categoria: $cat', 14, color: c.acInk),
              const SizedBox(width: 6),
              Ph(catOpen ? 'caret-up' : 'caret-down', size: 14, color: c.acInk),
            ]),
          ),
        ),
        if (catOpen) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final k in ['Todas', 'Receita', ...cats.map((e) => e.k)])
              _Chip(k, cat == k, () => setState(() { cat = k; catOpen = false; }), height: 34, size: 13, pad: 12),
          ]),
        ],
        if (groups.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            _Sum('Entradas', money(inSum, sign: true), c.acInk),
            const SizedBox(width: 24),
            _Sum('Saídas', money(-outSum, sign: true), c.tx),
          ]),
          for (final g in labels) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Kicker(g),
                Kicker(money(groups[g]!.fold(0.0, (s, t) => s + t.amt), sign: true)),
              ]),
            ),
            for (final t in groups[g]!) TxRow(t, showPill: true),
          ],
        ] else
          _Empty(
            icon: monthTxs.isEmpty ? 'tray' : 'magnifying-glass',
            title: monthTxs.isEmpty ? 'Nada em ${monthNames[month % 12].toLowerCase()}.' : 'Nenhum resultado.',
            body: monthTxs.isEmpty
                ? 'Ainda não há movimentações neste mês. Importe o extrato do banco para preencher de uma vez.'
                : 'Nenhuma movimentação corresponde aos filtros escolhidos.',
            cta: monthTxs.isEmpty ? 'Importar extrato' : 'Limpar filtros',
            onTap: monthTxs.isEmpty ? () => showImportSheet(context) : () => setState(() { filter = 'Todas'; cat = 'Todas'; q = ''; }),
          ),
      ]),
    );
  }
}

class _Sum extends StatelessWidget {
  const _Sum(this.label, this.value, this.valueColor);
  final String label, value;
  final Color valueColor;
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: '$label ', style: ts(13, color: context.c.tx2)),
        TextSpan(text: value, style: ts(13, bold: true, color: valueColor)),
      ]));
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.on, this.onTap, {this.height = 36, this.size = 14, this.pad = 14});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final double height, size, pad;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tap(
      onTap: onTap,
      child: Container(
        height: height, padding: EdgeInsets.symmetric(horizontal: pad), alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? c.tx : c.sf, borderRadius: BorderRadius.circular(2)),
        child: T(label, size, color: on ? c.bg : c.tx),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.body, required this.cta, required this.onTap});
  final String icon, title, body, cta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 56, 8, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Ph(icon, size: 40, color: c.tx2),
        const SizedBox(height: 10),
        T(title, 24, bold: true),
        const SizedBox(height: 10),
        T(body, 15, italic: true, color: c.tx2, height: 1.5),
        const SizedBox(height: 18),
        PrimaryButton(cta, onTap, height: 44, fontSize: 16, expand: false),
      ]),
    );
  }
}
