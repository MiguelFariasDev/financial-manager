import 'package:flutter/material.dart';
import 'screens/card_detail_screen.dart';
import 'screens/installment_screen.dart';
import 'screens/invoice_screen.dart';

Route<T> _route<T>(Widget w) => PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => w,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .02), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );

void openCard(BuildContext c, String id) => Navigator.of(c).push(_route(CardDetailScreen(cardId: id)));
void openInvoice(BuildContext c, String id) => Navigator.of(c).push(_route(InvoiceScreen(cardId: id)));
void openInstallment(BuildContext c, String cardId, String d) =>
    Navigator.of(c).push(_route(InstallmentScreen(cardId: cardId, itemDesc: d)));
