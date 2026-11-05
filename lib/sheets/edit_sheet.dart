import 'package:flutter/material.dart';
import '../app.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'sheet_frame.dart';

void showEditSheet(BuildContext context, String cardId, String itemDesc, String currentName) {
  final app = context.app;
  showBsSheet(context, (_) => _EditSheet(app: app, cardId: cardId, itemDesc: itemDesc, name: currentName));
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.app, required this.cardId, required this.itemDesc, required this.name});
  final dynamic app;
  final String cardId, itemDesc, name;
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final ctl = TextEditingController(text: widget.name);
  @override
  void dispose() { ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SheetFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Editar compra', 24, bold: true),
        const SizedBox(height: 18),
        const Kicker('Descrição'),
        const SizedBox(height: 8),
        Container(
          height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
          child: TextField(controller: ctl, style: ts(16, color: c.tx), cursorColor: c.ac, decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true), textAlignVertical: TextAlignVertical.center, onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: 12),
        T('Valor e número de parcelas só mudam apagando a compra e lançando de novo.', 13, italic: true, color: c.tx2),
        const SizedBox(height: 20),
        PrimaryButton('Salvar alterações', () {
          final v = ctl.text.trim();
          if (v.isNotEmpty) widget.app.rename(widget.cardId, widget.itemDesc, v);
          Navigator.of(context).pop();
          widget.app.showToast('Compra atualizada');
        }),
      ]),
    );
  }
}
