import 'dart:convert';
import '../state/app_state.dart';

String _csvCell(String s) => '"${s.replaceAll('"', '""')}"';

/// Movimentações as CSV (UTF-8, `;` separated, decimal comma for Brazilian spreadsheets).
String transactionsCsv(AppState a) {
  final b = StringBuffer('descricao;categoria;valor;forma;conta;dia;situacao\n');
  for (final t in a.allTxs) {
    b.writeln([_csvCell(t.d), _csvCell(t.cat), t.amt.toStringAsFixed(2).replaceAll('.', ','), t.m, _csvCell(t.acc), _csvCell(t.day), t.st].join(';'));
  }
  return b.toString();
}

String backupJson(AppState a) => const JsonEncoder.withIndent('  ').convert({
      'versao': 1,
      'meta': a.goal,
      'limites': a.limits,
      'movimentacoes': a.allTxs.map((t) => t.toJson()).toList(),
      'faturasPagas': a.paid,
      'parcelasAdicionadas': a.addedParcels.map((p) => {'cardId': p.cardId, 'item': p.item.toJson()}).toList(),
      'renomeadas': a.edits,
    });
