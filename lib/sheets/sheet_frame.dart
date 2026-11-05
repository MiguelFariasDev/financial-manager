import 'package:flutter/material.dart';
import '../theme/tokens.dart';

Future<T?> showBsSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF201E1D).withValues(alpha: .45),
    elevation: 0,
    builder: builder,
  );
}

/// Bottom sheet chrome: paper background, 10px top radius, grab handle.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * .88),
      child: Container(
        decoration: BoxDecoration(color: c.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
        padding: EdgeInsets.fromLTRB(22, 10, 22, 36 + mq.viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 38, height: 5, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: c.sf2, borderRadius: BorderRadius.circular(3)))),
            child,
          ]),
        ),
      ),
    );
  }
}

class Spinner extends StatelessWidget {
  const Spinner({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 34, height: 34,
      child: CircularProgressIndicator(strokeWidth: 3, color: c.ac, backgroundColor: c.sf2),
    );
  }
}
