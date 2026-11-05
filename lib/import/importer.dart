import 'dart:typed_data';
import '../data/models.dart';
import '../data/seed.dart';
import 'csv_parser.dart';
import 'decode.dart';
import 'ofx_parser.dart';
import 'parsed.dart';

/// Result of preparing a statement for import (nothing is saved yet).
class ImportPlan {
  ImportPlan({required this.fileName, required this.statement, required this.toImport, required this.duplicates, required this.label});
  final String fileName, label;
  final ParsedStatement statement;
  final List<Tx> toImport;
  final int duplicates;
  int get toReview => toImport.where((t) => t.review).length;
}

const _wd = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _mo = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// Group label used by the movements list ("Hoje", "Ontem, 3 nov", "Seg, 2 nov", "Sáb, 12 out 2025").
String dayLabel(DateTime d) {
  final today = DateTime(kToday.year, kToday.month, kToday.day);
  final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Hoje';
  final base = '${_wd[d.weekday - 1]}, ${d.day} ${_mo[d.month - 1]}';
  final withYear = d.year == kToday.year ? base : '$base ${d.year}';
  return diff == 1 ? 'Ontem, ${d.day} ${_mo[d.month - 1]}' : withYear;
}

const _rules = <String, List<String>>{
  'Alimentação': ['mercado', 'supermerc', 'padaria', 'restaurante', 'lanchonete', 'ifood', 'rappi', 'pao de acucar', 'carrefour', 'assai', 'atacadao', 'açaí', 'acai', 'pizza', 'burger', 'cafe', 'cafeteria', 'feira', 'hortifruti', 'mocoto'],
  'Transporte': ['uber', '99 ', '99app', 'cabify', 'posto', 'shell', 'ipiranga', 'combust', 'estaciona', 'pedagio', 'sem parar', 'metro', 'bilhete unico', 'onibus'],
  'Moradia': ['aluguel', 'condominio', 'luz', 'enel', 'energia', 'agua', 'sabesp', 'internet', 'vivo fibra', 'claro', 'tim ', 'gas ', 'iptu'],
  'Saúde': ['farmacia', 'drogasil', 'droga raia', 'pacheco', 'drogaria', 'hospital', 'clinica', 'laboratorio', 'unimed', 'dentista', 'plano de saude'],
  'Lazer': ['cinema', 'netflix', 'spotify', 'disney', 'hbo', 'prime video', 'steam', 'playstation', 'ingresso', 'teatro', 'bar ', 'show'],
  'Compras': ['amazon', 'mercado livre', 'magazine', 'shopee', 'americanas', 'zara', 'renner', 'c&a', 'shein', 'aliexpress', 'apple', 'kabum'],
  'Educação': ['escola', 'faculdade', 'curso', 'udemy', 'alura', 'livraria', 'mensalidade'],
};

String _fold(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  var o = s.toLowerCase();
  for (var i = 0; i < from.length; i++) { o = o.replaceAll(from[i], to[i]); }
  return o;
}

/// Maps a CSV category or the description to one of the app categories; null = unknown.
String? guessCategory(String description, {String? given}) {
  final names = cats.map((c) => c.k).toList();
  if (given != null) {
    final g = _fold(given);
    for (final n in names) { if (_fold(n) == g) return n; }
  }
  final d = ' ${_fold(description)} ';
  for (final e in _rules.entries) {
    for (final k in e.value) { if (d.contains(_fold(k))) return e.key; }
  }
  return null;
}

String _method(ParsedTx t, bool card) {
  if (card) return 'Crédito';
  final h = _fold('${t.description} ${t.hint}');
  if (h.contains('pix')) return 'PIX';
  if (h.contains('dinheiro') || h.contains('saque')) return 'Dinheiro';
  return 'Débito';
}

String _bank(String fileName, ParsedStatement s) {
  final src = _fold('${s.bankName ?? ''} $fileName');
  for (final e in {'itau': 'Itaú', 'nubank': 'Nubank', 'nu_': 'Nubank', 'inter': 'Inter', 'bradesco': 'Bradesco', 'santander': 'Santander', 'caixa': 'Caixa', 'c6': 'C6', 'brasil': 'Banco do Brasil'}.entries) {
    if (src.contains(e.key)) return e.value;
  }
  return s.bankName ?? 'Importado';
}

/// Builds the transactions to import and counts duplicates of what is already on the device.
ImportPlan planImport({
  required String fileName,
  required ParsedStatement statement,
  required List<Tx> existing,
  required String batchId,
}) {
  final bank = _bank(fileName, statement);
  final acc = statement.isCreditCard
      ? (statement.accountLast != null ? '$bank ••${statement.accountLast}' : '$bank cartão')
      : '$bank conta';

  // Existing movements can each absorb one imported line with the same day and amount
  // (manual entries rarely match the bank's description, so the description is ignored).
  final pool = <String, int>{};
  String key(DateTime d, double a) => '${d.year}-${d.month}-${d.day}|${a.toStringAsFixed(2)}';
  for (final t in existing) { pool[key(t.date, t.amt)] = (pool[key(t.date, t.amt)] ?? 0) + 1; }
  final knownIds = existing.map((t) => t.extId).whereType<String>().toSet();
  final seenIds = <String>{};

  final out = <Tx>[];
  var dup = 0;
  var n = 0;
  for (final p in statement.txs) {
    if (p.extId != null) {
      if (knownIds.contains(p.extId) || !seenIds.add(p.extId!)) { dup++; continue; }
    } else {
      final k = key(p.date, p.amount);
      if ((pool[k] ?? 0) > 0) { pool[k] = pool[k]! - 1; dup++; continue; }
    }
    final income = p.amount > 0;
    final cat = income ? 'Receita' : guessCategory(p.description, given: p.category);
    final review = !income && cat == null;
    final shownCat = income ? 'Receita' : (cat ?? 'Outros');
    out.add(Tx(
      id: DateTime.now().microsecondsSinceEpoch + n++,
      d: p.description, cat: shownCat,
      icon: income ? 'arrow-down-left' : catIcon(shownCat),
      amt: double.parse(p.amount.toStringAsFixed(2)),
      m: _method(p, statement.isCreditCard), acc: acc,
      day: dayLabel(p.date), st: 'paga', date: p.date,
      importId: batchId, extId: p.extId, review: review,
    ));
  }

  final months = out.map((t) => t.date).toList()..sort();
  final label = months.isEmpty
      ? acc
      : '$acc · ${_mo[months.first.month - 1]}${months.first.month != months.last.month || months.first.year != months.last.year ? '–${_mo[months.last.month - 1]}' : ''} ${months.last.year}';
  return ImportPlan(fileName: fileName, statement: statement, toImport: out, duplicates: dup, label: label);
}

/// Picks the parser from the file extension / content.
ImportKind kindOf(String fileName, String text) {
  final n = fileName.toLowerCase();
  if (n.endsWith('.ofx') || n.endsWith('.qfx')) return ImportKind.ofx;
  if (n.endsWith('.csv') || n.endsWith('.txt')) {
    return text.toUpperCase().contains('<STMTTRN>') ? ImportKind.ofx : ImportKind.csv;
  }
  if (text.toUpperCase().contains('<STMTTRN>')) return ImportKind.ofx;
  return ImportKind.unsupported;
}

enum ImportKind { ofx, csv, unsupported }

/// Reads, parses and plans an import. Throws [ImportException] with a user-facing message.
ImportPlan prepareImport({required String fileName, required Uint8List bytes, required List<Tx> existing, required String batchId}) {
  const maxBytes = 10 * 1024 * 1024;
  if (bytes.isEmpty) throw ImportException('Arquivo vazio.', 'Escolha um extrato que tenha movimentações.');
  if (bytes.length > maxBytes) throw ImportException('Arquivo grande demais.', 'O limite é de 10 MB. Exporte um período menor no app do banco.');
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.xlsx') || lower.endsWith('.xls') || lower.endsWith('.pdf')) {
    throw ImportException('Não conseguimos ler este arquivo.', 'Planilhas do Excel e PDFs ainda não são aceitos. No app do banco, exporte o extrato como OFX ou CSV e tente de novo.');
  }
  final text = decodeBankFile(bytes);
  final ParsedStatement st;
  switch (kindOf(fileName, text)) {
    case ImportKind.ofx: st = parseOfx(text);
    case ImportKind.csv: st = parseCsv(text);
    case ImportKind.unsupported:
      throw ImportException('Formato não reconhecido.', 'Use um arquivo OFX ou CSV exportado pelo seu banco.');
  }
  return planImport(fileName: fileName, statement: st, existing: existing, batchId: batchId);
}
