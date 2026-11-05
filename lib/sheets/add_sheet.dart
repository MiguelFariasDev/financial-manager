import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'sheet_frame.dart';

void showAddSheet(BuildContext context) {
  final app = context.app;
  showBsSheet(context, (_) => _AddSheet(app: app));
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.app});
  final AppState app;
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  String kind = 'Despesa', amount = '', desc = '', cat = 'Alimentação', method = 'PIX', cardId = 'nu';
  int inst = 1;

  double get amtNum => double.tryParse(amount.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
  bool get invalid => !(amtNum > 0 && desc.trim().isNotEmpty);

  void save() {
    if (invalid) return;
    final a = widget.app;
    final card = a.cardById(cardId);
    final startOff = kTodayDay > card.close ? 1 : 0;
    final nInst = inst > 1 ? inst : 1;
    final per = amtNum / nInst;
    final instOn = method == 'Crédito' && kind == 'Despesa' && inst > 1;
    final nm = desc.trim();
    final acc = method == 'Crédito' ? '${card.bank} ••${card.last}' : method == 'Dinheiro' ? 'Carteira' : 'Itaú conta';
    final tx = Tx(
      id: DateTime.now().millisecondsSinceEpoch,
      d: instOn ? '$nm · 1/$nInst' : nm,
      cat: kind == 'Receita' ? 'Receita' : cat,
      icon: kind == 'Receita' ? 'arrow-down-left' : catIcon(cat),
      amt: kind == 'Despesa' ? -(instOn ? per : amtNum) : amtNum,
      m: method, acc: acc, day: 'Hoje', st: 'paga',
      nov: !(instOn && startOff == 1),
      card: instOn ? cardId : null,
    );
    a.addTx(tx, parcel: instOn ? AddedParcel(cardId, CardItem(nm, cat, per, inst: '1/$nInst', n: nInst, p: startOff == 1 ? 0 : 1)) : null);
    Navigator.of(context).pop();
    a.showToast(instOn
        ? 'Compra em $nInst× de ${money(per)} · 1ª fatura ${mshort(10 + startOff)}'
        : '${kind == 'Despesa' ? 'Despesa' : 'Receita'} salva · ${money(amtNum)}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c, a = widget.app;
    final card = a.cardById(cardId);
    final startOff = kTodayDay > card.close ? 1 : 0;
    final nInst = inst > 1 ? inst : 1;
    final per = amtNum / nInst;
    final isCredit = method == 'Crédito';
    final instOn = isCredit && kind == 'Despesa' && inst > 1;
    final invoiceNote = kTodayDay > card.close
        ? 'Entra na fatura de dezembro (a de novembro fechou em ${card.closeStr}).'
        : 'Entra na fatura de novembro, que vence em ${card.dueStr}.';
    final methods = [('PIX', 'pix-logo'), ('Débito', 'cardholder'), ('Crédito', 'credit-card'), ('Dinheiro', 'money')]
        .where((m) => kind == 'Despesa' || m.$1 != 'Crédito')
        .toList();

    Widget seg(List<(String, bool, VoidCallback)> opts, {double h = 32, double padH = 14, bool expand = false}) => Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
          child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
            for (var i = 0; i < opts.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              (expand ? (Widget w) => Expanded(child: w) : (Widget w) => w)(Tap(
                onTap: opts[i].$3,
                child: Container(
                  height: h, padding: EdgeInsets.symmetric(horizontal: padH), alignment: Alignment.center,
                  decoration: BoxDecoration(color: opts[i].$2 ? c.bg : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                  child: T(opts[i].$1, 14, bold: true, color: opts[i].$2 ? c.tx : c.tx2),
                ),
              )),
            ],
          ]),
        );

    Widget tile(String label, String icon, bool on, VoidCallback onTap, double h) => Tap(
          onTap: onTap,
          child: Container(
            height: h, decoration: BoxDecoration(color: on ? c.ac : c.sf, borderRadius: BorderRadius.circular(2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Ph(icon, size: h > 55 ? 20 : 18, color: on ? c.onAc : c.tx),
              SizedBox(height: h > 55 ? 4 : 2),
              T(label, 12, color: on ? c.onAc : c.tx),
            ]),
          ),
        );

    Widget stepBtn(String icon, VoidCallback f, String label) => IconBox(icon, f, size: 18, label: label);

    return SheetFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: Tap(onTap: () => Navigator.of(context).pop(), child: SizedBox(height: 44, child: Align(alignment: Alignment.centerLeft, widthFactor: 1, child: T('Cancelar', 16, color: c.acInk)))))),
          seg([
            ('Despesa', kind == 'Despesa', () => setState(() => kind = 'Despesa')),
            ('Receita', kind == 'Receita', () => setState(() { kind = 'Receita'; if (method == 'Crédito') method = 'PIX'; })),
          ]),
          const Expanded(child: SizedBox()),
        ]),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          T('R\$', 24, bold: true, color: c.tx2),
          const SizedBox(width: 6),
          SizedBox(
            width: 200,
            child: TextField(
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (v) => setState(() => amount = v),
              style: ts(48, bold: true, color: c.tx, ls: -.02),
              cursorColor: c.ac,
              decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: '0,00', hintStyle: ts(48, bold: true, color: c.tx3, ls: -.02)),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          height: 48, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
          child: TextField(
            onChanged: (v) => setState(() => desc = v),
            style: ts(16, color: c.tx), cursorColor: c.ac, textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Descrição — ex.: Padaria', hintStyle: ts(16, color: c.tx2)),
          ),
        ),
        const SizedBox(height: 20),
        const Kicker('Categoria'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6, mainAxisExtent: null, childAspectRatio: (MediaQuery.of(context).size.width - 44 - 18) / 4 / 62,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [for (final k in cats) tile(k.k, k.icon, cat == k.k, () => setState(() => cat = k.k), 62)],
        ),
        const SizedBox(height: 20),
        const Kicker('Forma de pagamento'),
        const SizedBox(height: 8),
        Row(children: [
          for (var i = 0; i < methods.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: tile(methods[i].$1, methods[i].$2, method == methods[i].$1, () => setState(() => method = methods[i].$1), 52)),
          ],
        ]),
        if (isCredit) ...[
          const SizedBox(height: 12),
          for (final cd in a.cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Tap(
                onTap: () => setState(() => cardId = cd.id),
                child: Container(
                  height: 48, padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: cardId == cd.id ? c.sf : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                  child: Row(children: [
                    Container(width: 28, height: 18, decoration: BoxDecoration(color: cd.bg, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Expanded(child: T('${cd.bank} ${cd.nick} •• ${cd.last}', 15)),
                    Ph(cardId == cd.id ? 'check-circle' : 'circle', size: 20, color: c.ac),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 4),
          T(invoiceNote, 13, italic: true, color: c.tx2),
          const SizedBox(height: 8),
          seg([
            ('À vista', inst <= 1, () => setState(() => inst = 1)),
            ('Parcelada', inst > 1, () => setState(() => inst = inst < 2 ? 2 : inst)),
          ], h: 36, padH: 0, expand: true),
          if (instOn) ...[
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const T('Quantidade de parcelas', 15),
              Row(children: [
                stepBtn('minus', () => setState(() => inst = inst - 1 < 2 ? 2 : inst - 1), 'Menos parcelas'),
                const SizedBox(width: 4),
                SizedBox(width: 44, child: T('$inst×', 20, bold: true, align: TextAlign.center)),
                const SizedBox(width: 4),
                stepBtn('plus', () => setState(() => inst = inst + 1 > 12 ? 12 : inst + 1), 'Mais parcelas'),
              ]),
            ]),
            const SizedBox(height: 12),
            Cols([Stat('Valor total', money(amtNum), valueSize: 17), Stat('Cada parcela', money(per), valueSize: 17, valueColor: c.acInk)], gap: 10),
            const SizedBox(height: 10),
            Cols([Stat('Data da compra', '$kTodayDay nov 2026', valueSize: 15), Stat('Primeira fatura', mshort(10 + startOff), valueSize: 15)], gap: 10),
            const SizedBox(height: 12),
            const Kicker('Prévia do cronograma'),
            const SizedBox(height: 12),
            for (var k = 0; k < nInst; k++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 44, child: T('${k + 1}/$nInst', 14, color: c.tx2)),
                  Expanded(child: T('Fatura de ${mshort(10 + startOff + k)}', 14)),
                  T(money(per), 14, bold: true),
                ]),
              ),
          ],
        ],
        const SizedBox(height: 22),
        PrimaryButton('Salvar ${kind.toLowerCase()}', invalid ? null : save, opacity: invalid ? .45 : 1),
      ]),
    );
  }
}
