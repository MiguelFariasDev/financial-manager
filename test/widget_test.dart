import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_manager/app.dart';
import 'package:financial_manager/state/app_state.dart';
import 'package:financial_manager/util/format.dart';

Future<void> _font(String family, String path) async {
  final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await l.load();
}

void main() {
  setUpAll(() async {
    await _font('SourceSerif4', 'assets/fonts/SourceSerif4-Var.ttf');
    await _font('PhosphorDuotone', 'assets/fonts/Phosphor-Duotone.ttf');
  });

  test('money formats pt-BR', () {
    expect(money(8152.9), 'R\$ 8.152,90');
    expect(money(-680, sign: true), '− R\$ 680,00');
    expect(money(12500, sign: true), '+ R\$ 12.500,00');
  });

  test('month figures match the design', () {
    final a = AppState();
    expect(a.spent, closeTo(5842.9, .001));
    expect(a.total, closeTo(8152.9, .001));
    expect(a.balance, closeTo(4347.1, .001));
    expect(a.invTotal(a.cardById('nu')), closeTo(2184.6, .001));
    expect(a.invTotal(a.cardById('it')), closeTo(1315.5, .001));
    expect(a.goalNote, contains('você ainda poderia gastar R\$ 2.347,10'));
  });

  testWidgets('tabs, card, invoice and add sheet render without errors', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final a = AppState();
    await t.pumpWidget(CadernoApp(state: a));
    await t.pump(const Duration(milliseconds: 1300));
    expect(find.text('Bom dia, Marina.'), findsOneWidget);
    expect(find.text('R\$ 8.152,90'), findsWidgets);

    await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await t.pump();

    for (final label in ['Movimentações', 'Cartões', 'Planejamento', 'Perfil', 'Início']) {
      await t.tap(find.text(label).last);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: label);
    }

    await t.tap(find.text('Cartões').last);
    await t.pump();
    await t.tap(find.text('Nubank').first);
    await t.pumpAndSettle();
    expect(find.text('Compras parceladas'), findsOneWidget);
    await t.tap(find.text('iPhone 16 Pro').first);
    await t.pumpAndSettle();
    expect(find.text('Cronograma'), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pumpAndSettle();
    }

    a.setTab(0);
    await t.pumpAndSettle();
    await t.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Nova movimentação'));
    await t.pumpAndSettle();
    expect(find.text('Salvar despesa'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
