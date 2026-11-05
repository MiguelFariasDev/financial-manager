import 'package:flutter/material.dart';

class Cat {
  const Cat(this.k, this.icon);
  final String k, icon;
}

class Tx {
  Tx({
    required this.id, required this.d, required this.cat, required this.icon,
    required this.amt, required this.m, required this.acc, required this.day,
    required this.st, required this.date, this.due, this.card, this.nov = true,
    this.importId, this.extId, this.review = false,
  });
  final int id;
  final String d, cat, icon, m, acc, day, st; // st: paga | futura | pendente
  final double amt;
  final DateTime date;
  final String? due, card, importId, extId;
  final bool nov, review; // review = imported without a category

  /// Months since January 2026 (november 2026 = 10).
  int get monthIdx => (date.year - 2026) * 12 + date.month - 1;

  Tx copyWith({String? cat, String? icon, bool? review}) => Tx(
        id: id, d: d, cat: cat ?? this.cat, icon: icon ?? this.icon, amt: amt, m: m, acc: acc, day: day, st: st,
        date: date, due: due, card: card, nov: nov, importId: importId, extId: extId, review: review ?? this.review,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'd': d, 'cat': cat, 'icon': icon, 'amt': amt, 'm': m, 'acc': acc,
        'day': day, 'st': st, 'due': due, 'card': card, 'nov': nov,
        'date': date.toIso8601String(), 'importId': importId, 'extId': extId, 'review': review,
      };
  factory Tx.fromJson(Map<String, dynamic> j) => Tx(
        id: j['id'], d: j['d'], cat: j['cat'], icon: j['icon'], amt: (j['amt'] as num).toDouble(),
        m: j['m'], acc: j['acc'], day: j['day'], st: j['st'], due: j['due'], card: j['card'], nov: j['nov'] ?? true,
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime(2026, 11, 4),
        importId: j['importId'], extId: j['extId'], review: j['review'] ?? false,
      );
}

class ImportBatch {
  const ImportBatch({required this.id, required this.name, required this.count, required this.at});
  final String id, name;
  final int count;
  final DateTime at;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'count': count, 'at': at.toIso8601String()};
  factory ImportBatch.fromJson(Map<String, dynamic> j) =>
      ImportBatch(id: j['id'], name: j['name'], count: j['count'], at: DateTime.parse(j['at']));
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
