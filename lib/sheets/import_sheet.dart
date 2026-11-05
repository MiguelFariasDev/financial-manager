import 'dart:async';
import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'sheet_frame.dart';

void showImportSheet(BuildContext context) {
  final app = context.app;
  showBsSheet(context, (_) => _ImportSheet(app: app));
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({required this.app});
  final AppState app;
  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  String phase = 'pick';
  String file = '';
  Timer? _t;
  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  void pick(ImportFile f) {
    setState(() { phase = 'loading'; file = f.name; });
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 1400), () { if (mounted) setState(() => phase = f.bad ? 'error' : 'done'); });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SheetFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Importar extrato', 24, bold: true),
        ...switch (phase) {
          'loading' => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 44),
                child: Center(child: Column(children: [const Spinner(), const SizedBox(height: 14), T('Lendo $file…', 15, italic: true, color: c.tx2)])),
              ),
            ],
          'error' => [
              const SizedBox(height: 26),
              Ph('warning-octagon', size: 38, color: c.mInk),
              const SizedBox(height: 10),
              const T('Não conseguimos ler este arquivo.', 20, bold: true),
              const SizedBox(height: 10),
              T('Planilhas do Excel ainda não são aceitas. No app do banco, exporte o extrato como OFX ou CSV e tente de novo.', 15, color: c.tx2, height: 1.5),
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: PrimaryButton('Escolher outro arquivo', () => setState(() => phase = 'pick'), height: 44, fontSize: 16, expand: false)),
            ],
          'done' => [
              const SizedBox(height: 16),
              T('Itaú · Conta corrente ••3021 · outubro', 15, color: c.tx2),
              const SizedBox(height: 20),
              Cols([
                _Big('42', 'importadas', c.acInk),
                _Big('3', 'ignoradas', c.tx),
                _Big('2', 'para revisar', c.mInk),
              ]),
              const SizedBox(height: 16),
              T('As 3 ignoradas já existiam (lançadas manualmente). As 2 para revisar estão sem categoria.', 14, italic: true, color: c.tx2, height: 1.5),
              const SizedBox(height: 22),
              PrimaryButton('Concluir', () {
                Navigator.of(context).pop();
                widget.app.showToast('42 movimentações importadas');
              }),
            ],
          _ => [
              const SizedBox(height: 6),
              T('Arquivos OFX ou CSV do seu banco. Nada é enviado sem a sua confirmação.', 15, color: c.tx2, height: 1.5),
              const SizedBox(height: 18),
              const Kicker('Arquivos recentes'),
              const SizedBox(height: 8),
              for (final f in importFiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Tap(
                    onTap: () => pick(f),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56), padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
                      child: Row(children: [
                        Ph(f.icon, size: 24, color: c.acInk),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [T(f.name, 15, bold: true), T('${f.type} · ${f.size}', 13, color: c.tx2)])),
                        Ph('caret-right', size: 20, color: c.tx2),
                      ]),
                    ),
                  ),
                ),
            ],
        },
      ]),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.n, this.label, this.color);
  final String n, label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        T(n, 34, bold: true, color: color),
        T(label, 13, color: context.c.tx2),
      ]);
}
