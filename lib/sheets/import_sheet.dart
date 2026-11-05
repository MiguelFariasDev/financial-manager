import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../import/file_source.dart';
import '../import/importer.dart';
import '../import/parsed.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
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

enum _Phase { pick, loading, error, preview }

class _ImportSheetState extends State<_ImportSheet> {
  _Phase phase = _Phase.pick;
  String file = '';
  ImportException? error;
  ImportPlan? plan;
  bool _alive = true;

  @override
  void dispose() { _alive = false; super.dispose(); }

  Future<void> choose() async {
    PickedFile? picked;
    try {
      picked = await pickStatementFile();
    } catch (_) {
      if (!_alive) return;
      setState(() { phase = _Phase.error; error = ImportException('Não conseguimos abrir o arquivo.', 'Tente escolher o arquivo de novo.'); });
      return;
    }
    if (picked == null || !_alive) return;
    setState(() { phase = _Phase.loading; file = picked!.name; });
    // let the spinner paint before parsing large files
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final p = prepareImport(
        fileName: picked.name, bytes: picked.bytes, existing: widget.app.allTxs,
        batchId: DateTime.now().microsecondsSinceEpoch.toString(),
      );
      if (_alive) setState(() { plan = p; phase = _Phase.preview; });
    } on ImportException catch (e) {
      if (_alive) setState(() { error = e; phase = _Phase.error; });
    } catch (_) {
      if (_alive) setState(() { error = ImportException('Não conseguimos ler este arquivo.', 'O conteúdo não parece um extrato OFX ou CSV válido.'); phase = _Phase.error; });
    }
  }

  void confirm() {
    final p = plan!;
    final batchId = p.toImport.first.importId!;
    widget.app.commitImport(ImportBatch(id: batchId, name: p.fileName, count: p.toImport.length, at: kNow), p.toImport);
    Navigator.of(context).pop();
    widget.app.showToast('${p.toImport.length} ${p.toImport.length == 1 ? 'movimentação importada' : 'movimentações importadas'}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SheetFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Importar extrato', 24, bold: true),
        ...switch (phase) {
          _Phase.loading => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 44),
                child: Center(child: Column(children: [const Spinner(), const SizedBox(height: 14), T('Lendo $file…', 15, italic: true, color: c.tx2)])),
              ),
            ],
          _Phase.error => [
              const SizedBox(height: 26),
              Ph('warning-octagon', size: 38, color: c.mInk),
              const SizedBox(height: 10),
              T(error!.title, 20, bold: true),
              const SizedBox(height: 10),
              T(error!.message, 15, color: c.tx2, height: 1.5),
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: PrimaryButton('Escolher outro arquivo', choose, height: 44, fontSize: 16, expand: false)),
            ],
          _Phase.preview => _preview(c),
          _Phase.pick => [
              const SizedBox(height: 6),
              T('Arquivos OFX ou CSV do seu banco. O arquivo é lido só neste aparelho e nada é gravado sem a sua confirmação.', 15, color: c.tx2, height: 1.5),
              const SizedBox(height: 22),
              PrimaryButton('Escolher arquivo', choose),
              const SizedBox(height: 14),
              T('No app do banco: Extrato → Exportar → OFX (ou CSV).', 13, italic: true, color: c.tx2),
            ],
        },
      ]),
    );
  }

  List<Widget> _preview(BsColors c) {
    final p = plan!;
    final n = p.toImport.length;
    final notes = <String>[
      if (p.duplicates > 0)
        '${p.duplicates} ${p.duplicates == 1 ? 'já existia' : 'já existiam'} (lançadas antes, manualmente ou em outra importação) e não serão repetidas.',
      if (p.toReview > 0)
        '${p.toReview} ${p.toReview == 1 ? 'está sem categoria' : 'estão sem categoria'}: toque nelas em Movimentações para escolher.',
      if (p.statement.isCreditCard)
        'Arquivo de cartão: as compras entram em Movimentações como crédito, mas ainda não são ligadas às faturas dos cartões cadastrados.',
    ];
    return [
      const SizedBox(height: 16),
      T(p.label, 15, color: c.tx2),
      const SizedBox(height: 20),
      Cols([
        _Big('$n', 'a importar', n > 0 ? c.acInk : c.tx),
        _Big('${p.duplicates}', 'já existiam', c.tx),
        _Big('${p.toReview}', 'para revisar', p.toReview > 0 ? c.mInk : c.tx),
      ]),
      if (n > 0) ...[
        const SizedBox(height: 16),
        T('Entradas ${money(p.toImport.where((t) => t.amt > 0).fold(0.0, (s, t) => s + t.amt))} · Saídas ${money(p.toImport.where((t) => t.amt < 0).fold(0.0, (s, t) => s - t.amt))}', 14, color: c.tx2),
      ],
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 14),
        for (final t in notes) Padding(padding: const EdgeInsets.only(bottom: 6), child: T(t, 14, italic: true, color: c.tx2, height: 1.5)),
      ],
      if (n == 0) ...[
        const SizedBox(height: 10),
        T('Não há nada novo neste arquivo.', 15, bold: true),
      ],
      const SizedBox(height: 22),
      n > 0
          ? PrimaryButton('Importar $n ${n == 1 ? 'movimentação' : 'movimentações'}', confirm)
          : PrimaryButton('Fechar', () => Navigator.of(context).pop()),
      Center(child: TextLink('Escolher outro arquivo', choose, size: 15)),
    ];
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
