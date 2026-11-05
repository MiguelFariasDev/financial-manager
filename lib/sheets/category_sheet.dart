import 'package:flutter/material.dart';
import '../app.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'sheet_frame.dart';

/// Lets the user choose a category for an imported movement that had none.
void showCategorySheet(BuildContext context, Tx t) {
  final app = context.app;
  showBsSheet(context, (ctx) {
    final c = ctx.c;
    return SheetFrame(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const T('Escolher categoria', 24, bold: true),
        const SizedBox(height: 4),
        T(t.d, 14, color: c.tx2, maxLines: 1),
        const SizedBox(height: 18),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final k in cats)
            Tap(
              onTap: () { app.recategorize(t.id, k.k); Navigator.of(ctx).pop(); },
              child: Container(
                height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: c.sf, borderRadius: BorderRadius.circular(2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [Ph(k.icon, size: 18), const SizedBox(width: 8), T(k.k, 14)]),
              ),
            ),
        ]),
      ]),
    );
  });
}
