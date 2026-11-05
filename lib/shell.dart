import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'screens/cards_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transactions_screen.dart';
import 'sheets/add_sheet.dart';
import 'theme/tokens.dart';
import 'widgets/common.dart';

/// Main scaffold: five tabs, floating "+" button and the toast layer.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  bool booting = true;
  Timer? _t;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1100), () { if (!mounted) return; _pulse.stop(); setState(() => booting = false); });
  }

  @override
  void dispose() { _t?.cancel(); _pulse.dispose(); super.dispose(); }

  static const tabs = [
    ('Início', 'newspaper'), ('Movimentações', 'arrows-down-up'), ('Cartões', 'cards'),
    ('Planejamento', 'target'), ('Perfil', 'user-circle'),
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    final inset = MediaQuery.of(context).padding.bottom;
    final barH = 58 + (inset > 10 ? inset : 10.0);
    final bottomPad = barH + 34;

    final body = switch (a.tab) {
      0 => booting ? _Skeleton(_pulse) : HomeScreen(bottomPad: bottomPad),
      1 => TransactionsScreen(bottomPad: bottomPad),
      2 => CardsScreen(bottomPad: bottomPad),
      3 => PlanScreen(bottomPad: bottomPad),
      _ => ProfileScreen(bottomPad: bottomPad),
    };

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: SafeArea(bottom: false, child: body)),
        if (a.tab <= 2)
          Positioned(
            right: 20, bottom: barH + 18,
            child: Tap(
              label: 'Nova movimentação',
              onTap: () => showAddSheet(context),
              child: Container(
                width: 58, height: 58, alignment: Alignment.center,
                decoration: BoxDecoration(color: c.ac, borderRadius: BorderRadius.circular(4), boxShadow: BsColors.shadowMd),
                child: Ph('plus', size: 26, color: c.onAc),
              ),
            ),
          ),
        Positioned(
          left: 0, right: 0, bottom: 0, height: barH,
          child: Container(
            color: c.sf, padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Row(children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Tap(
                    onTap: () => a.setTab(i),
                    child: SizedBox(
                      height: 50,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Ph(tabs[i].$2, size: 24, color: a.tab == i ? c.acInk : c.tx2),
                        const SizedBox(height: 3),
                        FittedBox(fit: BoxFit.scaleDown, child: T(tabs[i].$1, 11, bold: a.tab == i, color: a.tab == i ? c.acInk : c.tx2)),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton(this.pulse);
  final Animation<double> pulse;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget b(double h, {double? w, double fw = 1}) => Container(height: h, width: w, color: c.sf);
    return FadeTransition(
      opacity: Tween(begin: .55, end: 1.0).animate(pulse),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: LayoutBuilder(builder: (_, box) {
          final w = box.maxWidth;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            b(14, w: w * .45), const SizedBox(height: 18),
            b(30, w: w * .70), const SizedBox(height: 38),
            b(12, w: w * .35), const SizedBox(height: 18),
            b(52, w: w * .85), const SizedBox(height: 18),
            b(6, w: w), const SizedBox(height: 32),
            Row(children: [Expanded(child: b(44)), const SizedBox(width: 14), Expanded(child: b(44)), const SizedBox(width: 14), Expanded(child: b(44))]),
            const SizedBox(height: 10),
            T('Atualizando saldos…', 13, italic: true, color: c.tx2),
          ]);
        }),
      ),
    );
  }
}

/// Toast overlay, mounted above the navigator via MaterialApp.builder.
class ToastLayer extends StatelessWidget {
  const ToastLayer({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final a = context.app, c = context.c;
    return Stack(children: [
      child,
      if (a.toast.isNotEmpty)
        Positioned(
          top: MediaQuery.of(context).padding.top + 6, left: 22, right: 22,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: c.tx, borderRadius: BorderRadius.circular(4), boxShadow: BsColors.shadowLg),
              child: Row(children: [
                Ph('check-circle', size: 20, color: c.bg),
                const SizedBox(width: 10),
                Expanded(child: T(a.toast, 15, color: c.bg)),
              ]),
            ),
          ),
        ),
    ]);
  }
}
