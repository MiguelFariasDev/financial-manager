import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_manager/app.dart';
import 'package:financial_manager/data/models.dart';
import 'package:financial_manager/data/seed.dart';
import 'package:financial_manager/import/csv_parser.dart';
import 'package:financial_manager/import/file_source.dart';
import 'package:financial_manager/import/importer.dart';
import 'package:financial_manager/import/ofx_parser.dart';
import 'package:financial_manager/import/parsed.dart';
import 'package:financial_manager/state/app_state.dart';
import 'package:financial_manager/util/format.dart';

const ofxV1 = '''OFXHEADER:100
DATA:OFXSGML
VERSION:102
CHARSET:1252
ENCODING:USASCII

<OFX>
<SIGNONMSGSRSV1><SONRS><STATUS><CODE>0<SEVERITY>INFO</STATUS><DTSERVER>20251101120000[-3:BRT]<LANGUAGE>POR<FI><ORG>ITAU UNIBANCO<FID>341</FI></SONRS></SIGNONMSGSRSV1>
<BANKMSGSRSV1><STMTTRNRS><TRNUID>1<STMTRS><CURDEF>BRL
<BANKACCTFROM><BANKID>0341<ACCTID>12345-3021<ACCTTYPE>CHECKING</BANKACCTFROM>
<BANKTRANLIST><DTSTART>20251001<DTEND>20251031
<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20251003120000[-3:BRT]<TRNAMT>-186.40<FITID>A1<MEMO>PAO DE ACUCAR 123
<STMTTRN><TRNTYPE>PAYMENT<DTPOSTED>20251005<TRNAMT>-32.90<FITID>A2<MEMO>UBER *TRIP
<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20251006<TRNAMT>12500.00<FITID>A3<MEMO>SALARIO ACME LTDA
<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20251007<TRNAMT>-89,90<FITID>A4<NAME>PIX ENVIADO<MEMO>JOSÉ DA SILVA
<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20251008<TRNAMT>-45.00<FITID>A5<MEMO>OFICINA DO ZE
</BANKTRANLIST></STMTRS></STMTTRNRS></BANKMSGSRSV1></OFX>
''';

const ofxXml = '''<?xml version="1.0" encoding="UTF-8"?>
<OFX><BANKMSGSRSV1><STMTTRNRS><STMTRS><BANKACCTFROM><ACCTID>7714</ACCTID></BANKACCTFROM><BANKTRANLIST>
<STMTTRN><TRNTYPE>DEBIT</TRNTYPE><DTPOSTED>20251010</DTPOSTED><TRNAMT>-19.90</TRNAMT><FITID>X1</FITID><MEMO>Netflix</MEMO></STMTTRN>
</BANKTRANLIST></STMTRS></STMTTRNRS></BANKMSGSRSV1></OFX>''';

const nubankConta = '''Data,Valor,Identificador,Descrição
03/10/2025,-186.40,id-1,Compra no débito - Padaria Estrela
04/10/2025,12500.00,id-2,Transferência recebida pelo Pix - ACME LTDA
05/10/2025,-1250.50,id-3,Transferência enviada pelo Pix - João
''';

const nubankCartao = '''date,category,title,amount
2025-10-02,restaurante,Mocotó,186.00
2025-10-03,transporte,Uber *Trip,32.90
2025-10-04,,Loja Desconhecida,70.00
''';

const brCsv = '''Extrato Conta Corrente
Agência: 1234;Conta: 56789-0
;;
Data;Histórico;Valor
05/10/2025;"PAGTO ""LUZ"" ENEL";-1.234,56
06/10/2025;SALÁRIO;12.500,00
07/10/25;SAQUE ATM;(200,00)
''';

void main() {
  group('parseMoney', () {
    test('formats', () {
      expect(parseMoney('1.234,56'), 1234.56);
      expect(parseMoney('-1234.56'), -1234.56);
      expect(parseMoney('R\$ 1.234,56'), 1234.56);
      expect(parseMoney('(12,30)'), -12.3);
      expect(parseMoney('12,30-'), -12.3);
      expect(parseMoney('1.234'), 1234);
      expect(parseMoney('12.5'), 12.5);
      expect(parseMoney('abc'), isNull);
    });
  });

  group('OFX', () {
    test('v1 SGML (latin-1) is parsed with dates, signs, fitid and account', () {
      final s = parseOfx(ofxV1);
      expect(s.txs.length, 5);
      expect(s.txs[0].date, DateTime(2025, 10, 3));
      expect(s.txs[0].amount, -186.4);
      expect(s.txs[0].extId, 'A1');
      expect(s.txs[2].amount, 12500);
      expect(s.txs[3].amount, -89.9); // decimal comma tolerated
      expect(s.txs[3].description, 'PIX ENVIADO · JOSÉ DA SILVA');
      expect(s.accountLast, '3021');
      expect(s.bankName, 'ITAU UNIBANCO');
      expect(s.isCreditCard, isFalse);
    });
    test('v2 XML', () {
      final s = parseOfx(ofxXml);
      expect(s.txs.single.description, 'Netflix');
      expect(s.txs.single.amount, -19.9);
    });
    test('rejects non-OFX', () {
      expect(() => parseOfx('hello'), throwsA(isA<ImportException>()));
    });
  });

  group('CSV', () {
    test('Nubank conta', () {
      final s = parseCsv(nubankConta);
      expect(s.txs.length, 3);
      expect(s.txs[0].amount, -186.4);
      expect(s.txs[0].extId, 'id-1');
      expect(s.txs[1].amount, 12500);
      expect(s.isCreditCard, isFalse);
    });
    test('Nubank cartão: positives are purchases', () {
      final s = parseCsv(nubankCartao);
      expect(s.isCreditCard, isTrue);
      expect(s.txs.map((t) => t.amount), [-186.0, -32.9, -70.0]);
      expect(s.txs[0].category, 'restaurante');
    });
    test('semicolon, preamble, quotes, BR numbers, 2-digit year', () {
      final s = parseCsv(brCsv);
      expect(s.txs.length, 3);
      expect(s.txs[0].description, 'PAGTO "LUZ" ENEL');
      expect(s.txs[0].amount, -1234.56);
      expect(s.txs[1].amount, 12500);
      expect(s.txs[2].amount, -200);
      expect(s.txs[2].date, DateTime(2025, 10, 7));
    });
    test('no recognisable columns', () {
      expect(() => parseCsv('a,b\n1,2\n'), throwsA(isA<ImportException>()));
    });
  });

  group('plan', () {
    test('categorises, flags review, dedupes against existing and by id', () {
      final bytes = Uint8List.fromList(latin1.encode(ofxV1.replaceAll('JOSÉ', 'JOSE')));
      final p1 = prepareImport(fileName: 'extrato_itau_outubro.ofx', bytes: bytes, existing: seedTxs, batchId: 'b1');
      expect(p1.toImport.length, 5);
      expect(p1.duplicates, 0);
      final cats = {for (final t in p1.toImport) t.extId: t.cat};
      expect(cats['A1'], 'Alimentação');
      expect(cats['A2'], 'Transporte');
      expect(cats['A3'], 'Receita');
      expect(cats['A5'], 'Outros');
      expect(p1.toReview, 2); // PIX ENVIADO + OFICINA DO ZE
      expect(p1.toImport.first.acc, 'Itaú conta');
      expect(p1.toImport.first.m, anyOf('Débito', 'PIX'));
      expect(p1.label, contains('out 2025'));

      // second import of the same file: everything is already there
      final again = prepareImport(fileName: 'extrato_itau_outubro.ofx', bytes: bytes, existing: [...p1.toImport, ...seedTxs], batchId: 'b2');
      expect(again.toImport, isEmpty);
      expect(again.duplicates, 5);
    });

    test('matches a manual entry with same day and amount (no id in file)', () {
      const csv = 'Data,Valor,Descrição\n03/11/2026,-2150.00,ALUGUEL NOV\n03/11/2026,-10.00,CAFE\n';
      final p = prepareImport(fileName: 'x.csv', bytes: Uint8List.fromList(utf8.encode(csv)), existing: seedTxs, batchId: 'b');
      expect(p.duplicates, 1); // seed "Aluguel" 3 nov −2150
      expect(p.toImport.single.d, 'CAFE');
      expect(p.toImport.single.day, 'Ontem, 3 nov');
    });

    test('xlsx and unknown formats are rejected with a clear message', () {
      expect(() => prepareImport(fileName: 'planilha_gastos.xlsx', bytes: Uint8List.fromList([1, 2, 3]), existing: [], batchId: 'b'),
          throwsA(isA<ImportException>().having((e) => e.message, 'message', contains('OFX ou CSV'))));
      expect(() => prepareImport(fileName: 'foto.png', bytes: Uint8List.fromList([1, 2, 3]), existing: [], batchId: 'b'),
          throwsA(isA<ImportException>()));
      expect(() => prepareImport(fileName: 'a.csv', bytes: Uint8List(0), existing: [], batchId: 'b'), throwsA(isA<ImportException>()));
    });
  });

  group('state', () {
    test('import affects only its own month and can be undone as a batch', () {
      final a = AppState();
      final before = a.total;
      final p = prepareImport(fileName: 'nubank_conta_2025-10.csv', bytes: Uint8List.fromList(utf8.encode(nubankConta)), existing: a.allTxs, batchId: 'b1');
      a.commitImport(ImportBatch(id: 'b1', name: p.fileName, count: p.toImport.length, at: DateTime(2026, 11, 4)), p.toImport);
      expect(a.added.length, 3);
      expect(a.total, before); // Oct 2025 must not change November
      expect(a.balance, closeTo(4347.1, .001));
      expect(a.allTxs.first.monthIdx, 10);
      a.undoImport('b1');
      expect(a.added, isEmpty);
      expect(a.batches, isEmpty);
    });

    test('recategorize clears the review flag', () {
      final a = AppState();
      final p = prepareImport(fileName: 'c.csv', bytes: Uint8List.fromList(utf8.encode(nubankCartao)), existing: [], batchId: 'b');
      a.commitImport(ImportBatch(id: 'b', name: 'c.csv', count: 3, at: DateTime(2026)), p.toImport);
      final t = a.added.firstWhere((t) => t.review);
      a.recategorize(t.id, 'Compras');
      expect(a.added.firstWhere((x) => x.id == t.id).cat, 'Compras');
      expect(a.added.where((x) => x.review), isEmpty);
    });

    test('month titles', () {
      expect(monthTitle(10), 'Novembro 2026');
      expect(monthTitle(-2), 'Novembro 2025');
      expect(monthTitle(-12), 'Janeiro 2025');
    });
  });

  testWidgets('import sheet: pick → preview → confirm → profile → undo', (t) async {
    Future<void> font(String f, String p) async {
      final l = FontLoader(f)..addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
      await l.load();
    }
    await font('SourceSerif4', 'assets/fonts/SourceSerif4-Var.ttf');
    await font('PhosphorDuotone', 'assets/fonts/Phosphor-Duotone.ttf');
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    final a = AppState();
    PickedFile? next = (name: 'planilha_gastos.xlsx', bytes: Uint8List.fromList([1, 2, 3]));
    pickStatementFile = () async => next;
    await t.pumpWidget(CadernoApp(state: a));
    await t.pump(const Duration(milliseconds: 1300));

    a.setTab(1);
    await t.pump();
    await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Importar extrato'));
    await t.pumpAndSettle();
    await t.tap(find.text('Escolher arquivo'));
    await t.pumpAndSettle();
    expect(find.text('Não conseguimos ler este arquivo.'), findsOneWidget); // xlsx error state

    next = (name: 'nubank_conta_2025-10.csv', bytes: Uint8List.fromList(utf8.encode(nubankConta)));
    await t.tap(find.text('Escolher outro arquivo'));
    await t.pumpAndSettle();
    expect(find.text('Importar 3 movimentações'), findsOneWidget);
    expect(find.text('Nubank conta · out 2025'), findsOneWidget);
    expect(a.added, isEmpty); // nothing saved before confirming
    await t.tap(find.text('Importar 3 movimentações'));
    await t.pumpAndSettle();
    expect(a.added.length, 3);
    expect(a.batches.single.name, 'nubank_conta_2025-10.csv');
    expect(a.toast, '3 movimentações importadas');
    await t.pump(const Duration(seconds: 3));

    a.setTab(4);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Desfazer'));
    await t.tap(find.text('Desfazer'));
    await t.pumpAndSettle();
    expect(a.added, isEmpty);
    await t.pump(const Duration(seconds: 3));
  });
}
