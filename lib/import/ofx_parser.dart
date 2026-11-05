import 'parsed.dart';

/// Parses OFX 1.x (SGML, unclosed tags) and 2.x (XML) statements.
ParsedStatement parseOfx(String text) {
  if (!RegExp(r'<OFX>', caseSensitive: false).hasMatch(text) && !text.toUpperCase().contains('<STMTTRN>')) {
    throw ImportException('Não conseguimos ler este arquivo.', 'Ele não parece um extrato OFX válido.');
  }

  String? tag(String block, String name) {
    final m = RegExp('<$name>([^<\\r\\n]*)', caseSensitive: false).firstMatch(block);
    final v = m?.group(1)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  final isCard = RegExp(r'<CCSTMTRS>|<CREDITCARDMSGSRSV1>', caseSensitive: false).hasMatch(text);
  final blocks = RegExp(r'<STMTTRN>(.*?)(?=</STMTTRN>|<STMTTRN>|</BANKTRANLIST>|$)', caseSensitive: false, dotAll: true)
      .allMatches(text)
      .map((m) => m.group(1)!);

  final txs = <ParsedTx>[];
  for (final b in blocks) {
    final dt = tag(b, 'DTPOSTED'), amt = tag(b, 'TRNAMT');
    if (dt == null || amt == null) continue;
    final date = _ofxDate(dt), value = _ofxAmount(amt);
    if (date == null || value == null) continue;
    final name = tag(b, 'NAME'), memo = tag(b, 'MEMO');
    final desc = _clean([?name, if (memo != null && memo != name) memo].join(' · '));
    txs.add(ParsedTx(
      date: date, amount: value,
      description: desc.isEmpty ? 'Sem descrição' : desc,
      extId: tag(b, 'FITID'),
      hint: '${tag(b, 'TRNTYPE') ?? ''} $memo ${name ?? ''}',
    ));
  }
  if (txs.isEmpty) throw ImportException('Nenhuma movimentação encontrada.', 'O arquivo foi lido, mas não tem lançamentos.');

  final acct = tag(text, 'ACCTID');
  return ParsedStatement(
    format: 'OFX', txs: txs, isCreditCard: isCard,
    bankName: tag(text, 'ORG'),
    accountLast: acct == null ? null : (acct.length > 4 ? acct.substring(acct.length - 4) : acct),
  );
}

String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// YYYYMMDD[HHMMSS[.XXX][[-3:BRT]]] → date (time ignored; the timezone must not shift the day).
DateTime? _ofxDate(String s) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})').firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return DateTime(y, mo, d);
}

double? _ofxAmount(String s) => parseMoney(s);

/// Parses "1.234,56", "-1234.56", "R$ 1.234,56", "(12,30)", "12,30-" → double.
double? parseMoney(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'R\$|\s'), '');
  if (s.isEmpty) return null;
  var neg = false;
  if (s.startsWith('(') && s.endsWith(')')) { neg = true; s = s.substring(1, s.length - 1); }
  if (s.endsWith('-')) { neg = true; s = s.substring(0, s.length - 1); }
  if (s.startsWith('-')) { neg = true; s = s.substring(1); }
  if (s.startsWith('+')) s = s.substring(1);
  if (!RegExp(r'^[0-9.,]+$').hasMatch(s)) return null;
  final lastDot = s.lastIndexOf('.'), lastComma = s.lastIndexOf(',');
  if (lastDot >= 0 && lastComma >= 0) {
    final decimalIsComma = lastComma > lastDot;
    s = decimalIsComma ? s.replaceAll('.', '').replaceAll(',', '.') : s.replaceAll(',', '');
  } else if (lastComma >= 0) {
    s = s.replaceAll(RegExp(r',(?=.*,)'), '').replaceAll(',', '.');
  } else if (lastDot >= 0) {
    // "1.234" or "1.234.567" are thousands; "12.5" / "1234.56" are decimals.
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) s = s.replaceAll('.', '');
  }
  final v = double.tryParse(s);
  if (v == null) return null;
  return neg ? -v : v;
}
