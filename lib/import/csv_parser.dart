import 'ofx_parser.dart' show parseMoney;
import 'parsed.dart';

/// Parses bank CSV exports (Nubank, Inter, Itaú-style…): detects the delimiter,
/// the header row and the date/description/amount columns.
ParsedStatement parseCsv(String text) {
  final rows = _rows(text);
  if (rows.length < 2) throw ImportException('Nenhuma movimentação encontrada.', 'O arquivo CSV está vazio.');

  // header = first row that has a date-ish and an amount-ish column
  int hi = -1;
  late Map<String, int> col;
  for (var i = 0; i < rows.length && i < 15; i++) {
    final c = _columns(rows[i]);
    if (c.containsKey('date') && (c.containsKey('amount') || c.containsKey('debit') || c.containsKey('credit'))) { hi = i; col = c; break; }
  }
  if (hi < 0) {
    throw ImportException('Não conseguimos ler este arquivo.', 'Não achamos as colunas de data e valor. Exporte o extrato do banco como CSV com cabeçalho.');
  }

  final header = rows[hi].map(_norm).toList();
  // Card exports (e.g. Nubank "date,category,title,amount") list purchases as positive numbers.
  final inverted = header.contains('title') && header.contains('category') && !header.contains('descricao');

  final txs = <ParsedTx>[];
  for (var i = hi + 1; i < rows.length; i++) {
    final r = rows[i];
    String? at(String k) => col[k] != null && col[k]! < r.length ? r[col[k]!].trim() : null;
    final date = _date(at('date') ?? '');
    if (date == null) continue;
    double? v;
    if (col.containsKey('amount')) {
      v = parseMoney(at('amount') ?? '');
    } else {
      final d = parseMoney(at('debit') ?? ''), c = parseMoney(at('credit') ?? '');
      v = (c ?? 0).abs() - (d ?? 0).abs();
      if (d == null && c == null) v = null;
    }
    if (v == null || v == 0) continue;
    if (inverted) v = -v;
    final desc = (at('desc') ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final cat = at('category');
    txs.add(ParsedTx(
      date: date, amount: v, description: desc.isEmpty ? 'Sem descrição' : desc,
      extId: (at('id')?.isEmpty ?? true) ? null : at('id'),
      category: (cat == null || cat.isEmpty) ? null : cat,
    ));
  }
  if (txs.isEmpty) throw ImportException('Nenhuma movimentação encontrada.', 'O arquivo foi lido, mas nenhuma linha tinha data e valor válidos.');
  return ParsedStatement(format: 'CSV', txs: txs, isCreditCard: inverted, inverted: inverted);
}

String _norm(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  var o = s.trim().toLowerCase().replaceAll('﻿', '');
  for (var i = 0; i < from.length; i++) { o = o.replaceAll(from[i], to[i]); }
  return o.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
}

Map<String, int> _columns(List<String> header) {
  const aliases = {
    'date': ['data', 'date', 'dt', 'data lancamento', 'data da compra', 'data movimentacao'],
    'desc': ['descricao', 'description', 'historico', 'lancamento', 'title', 'titulo', 'estabelecimento', 'memo', 'detalhes'],
    'amount': ['valor', 'amount', 'quantia', 'valor rs', 'valor r'],
    'debit': ['debito', 'saida', 'saidas'],
    'credit': ['credito', 'entrada', 'entradas'],
    'id': ['identificador', 'id', 'fitid', 'codigo'],
    'category': ['categoria', 'category'],
  };
  final out = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final h = _norm(header[i]);
    aliases.forEach((k, names) {
      if (!out.containsKey(k) && names.contains(h)) out[k] = i;
    });
  }
  return out;
}

DateTime? _date(String s) {
  s = s.trim();
  var m = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})').firstMatch(s);
  if (m != null) {
    var y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
    return _valid(y, int.parse(m.group(2)!), int.parse(m.group(1)!));
  }
  m = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (m != null) return _valid(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  return null;
}

DateTime? _valid(int y, int mo, int d) => (mo < 1 || mo > 12 || d < 1 || d > 31) ? null : DateTime(y, mo, d);

/// RFC 4180 reader with delimiter detection (`,` `;` or tab).
List<List<String>> _rows(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  final sample = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final probe = lines.where((l) => l.trim().isNotEmpty).take(8).join('\n');
  var delim = ',';
  var best = -1;
  for (final d in [',', ';', '\t']) {
    final n = RegExp(RegExp.escape(d)).allMatches(probe).length;
    if (n > best) { best = n; delim = d; }
  }
  if (sample.isEmpty) return [];

  final rows = <List<String>>[];
  var row = <String>[];
  final f = StringBuffer();
  var inQ = false;
  void endField() { row.add(f.toString()); f.clear(); }
  void endRow() {
    endField();
    if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (inQ) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') { f.write('"'); i++; } else { inQ = false; }
      } else { f.write(ch); }
    } else if (ch == '"') { inQ = true; }
    else if (ch == delim) { endField(); }
    else if (ch == '\n') { endRow(); }
    else if (ch == '\r') { /* handled with \n */ }
    else { f.write(ch); }
  }
  if (f.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
