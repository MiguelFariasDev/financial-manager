import 'package:flutter/material.dart';

class Cat {
  const Cat(this.k, this.icon);
  final String k, icon;
}

class Tx {
  Tx({
    required this.id, required this.d, required this.cat, required this.icon,
    required this.amt, required this.m, required this.acc, required this.day,
    required this.st, this.due, this.card, this.nov = true,
  });
  final int id;
  final String d, cat, icon, m, acc, day, st; // st: paga | futura | pendente
  final double amt;
  final String? due, card;
  final bool nov;

  Map<String, dynamic> toJson() => {
        'id': id, 'd': d, 'cat': cat, 'icon': icon, 'amt': amt, 'm': m, 'acc': acc,
        'day': day, 'st': st, 'due': due, 'card': card, 'nov': nov,
      };
  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'], d: j['d'], cat: j['cat'], icon: j['icon'], amt: (j['amt'] as num).toDouble(),
        m: j['m'], acc: j['acc'], day: j['day'], st: j['st'], due: j['due'], card: j['card'], nov: j['nov'] ?? true,
      );
}

class CardItem {
  const CardItem(this.d, this.cat, this.amt, {this.inst, this.n, this.p, this.date});
  final String d, cat;
  final double amt;
  final String? inst, date;
  final int? n, p;
  bool get isInstallment => inst != null;

  Map<String, dynamic> toJson() => {'d': d, 'cat': cat, 'amt': amt, 'inst': inst, 'n': n, 'p': p, 'date': date};
  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(j['d'], j['cat'], (j['amt'] as num).toDouble(),
      inst: j['inst'], n: j['n'], p: j['p'], date: j['date']);
}

class CardRecent {
  const CardRecent(this.d, this.cat, this.amt, this.date);
  final String d, cat, date;
  final double amt;
}

class NextInv {
  const NextInv(this.month, this.amt, this.st);
  final String month, st;
  final double amt;
}

class CreditCard {
  const CreditCard({
    required this.id, required this.bank, required this.nick, required this.last,
    required this.lim, required this.used, required this.close, required this.closeStr,
    required this.dueStr, required this.bg, required this.net, required this.baseStatus,
    required this.items, required this.recent, required this.recentNote,
    required this.prev, required this.next,
  });
  final String id, bank, nick, last, closeStr, dueStr, net, baseStatus, recentNote;
  final double lim, used;
  final int close;
  final Color bg;
  final List<CardItem> items;
  final List<CardRecent> recent;
  final List<(String, double)> prev;
  final List<NextInv> next;
}

class ImportFile {
  const ImportFile(this.name, this.type, this.size, this.icon, {this.bad = false});
  final String name, type, size, icon;
  final bool bad;
}

class AddedParcel {
  const AddedParcel(this.cardId, this.item);
  final String cardId;
  final CardItem item;
}
