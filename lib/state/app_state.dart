import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../util/format.dart';

enum InvStatus { aberta, fechada, paga, atrasada, prevista }

class AppState extends ChangeNotifier {
  AppState({this._prefs}) {
    _restore();
  }
  final SharedPreferences? _prefs;
  static const _key = 'caderno.state.v1';

  // ---- persisted state ----
  bool dark = false;
  double goal = 2000;
  bool remind = true;
  Map<String, double> limits = Map.of(defaultLimits);
  List<Tx> added = [];
  List<AddedParcel> addedParcels = [];
  Map<String, bool> paid = {};
  Map<String, String> edits = {}; // "cardId:descricao" -> novo nome
  List<ImportBatch> batches = [];

  // ---- ephemeral UI state ----
  int tab = 0; // 0 home, 1 tx, 2 cards, 3 plan, 4 profile
  String toast = '';
  int toastSeq = 0;

  final cards = seedCards;

  static Future<AppState> load() async => AppState(prefs: await SharedPreferences.getInstance());

  void _restore() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      dark = j['dark'] ?? false;
      goal = (j['goal'] as num?)?.toDouble() ?? goal;
      remind = j['remind'] ?? true;
      limits = {...defaultLimits, ...((j['limits'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ?? {})};
      added = ((j['added'] as List?) ?? []).map((e) => Tx.fromJson(Map<String, dynamic>.from(e))).toList();
      addedParcels = ((j['addedParcels'] as List?) ?? [])
          .map((e) => AddedParcel(e['cardId'], CardItem.fromJson(Map<String, dynamic>.from(e['item']))))
          .toList();
      paid = ((j['paid'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v == true));
      edits = ((j['edits'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as String));
      batches = ((j['batches'] as List?) ?? []).map((e) => ImportBatch.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      // corrupted store: start from seed
    }
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode({
        'dark': dark, 'goal': goal, 'remind': remind, 'limits': limits,
        'added': added.map((t) => t.toJson()).toList(),
        'addedParcels': addedParcels.map((a) => {'cardId': a.cardId, 'item': a.item.toJson()}).toList(),
        'paid': paid, 'edits': edits, 'batches': batches.map((b) => b.toJson()).toList(),
      }),
    );
  }

  void _commit() {
    _save();
    notifyListeners();
  }

  // ---- actions ----
  void setDark(bool v) { dark = v; _commit(); }
  void toggleDark() => setDark(!dark);
  void setTab(int t) { tab = t; notifyListeners(); }
  void setGoal(double v) { goal = v < 0 ? 0 : v; _commit(); }
  void toggleRemind() { remind = !remind; _commit(); }
  void setLimit(String cat, double v) { limits = {...limits, cat: v < 100 ? 100 : v}; _commit(); }
  void rename(String cardId, String d, String name) { edits = {...edits, '$cardId:$d': name}; _commit(); }
  void markPaid(String cardId) { paid = {...paid, cardId: true}; _commit(); }
  /// Saves an import plan as one batch (can be undone as a whole).
  void commitImport(ImportBatch batch, List<Tx> txs) {
    added = [...txs, ...added];
    batches = [batch, ...batches];
    _commit();
  }

  void undoImport(String batchId) {
    final b = batches.where((b) => b.id == batchId).firstOrNull;
    added = added.where((t) => t.importId != batchId).toList();
    batches = batches.where((b) => b.id != batchId).toList();
    _commit();
    if (b != null) showToast('Importação desfeita · ${b.name}');
  }

  void recategorize(int id, String cat) {
    added = [for (final t in added) t.id == id ? t.copyWith(cat: cat, icon: catIcon(cat), review: false) : t];
    _commit();
  }

  void addTx(Tx t, {AddedParcel? parcel}) {
    added = [t, ...added];
    if (parcel != null) addedParcels = [parcel, ...addedParcels];
    _commit();
  }

  void showToast(String msg) {
    toast = msg;
    final seq = ++toastSeq;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (seq == toastSeq) { toast = ''; notifyListeners(); }
    });
  }

  // ---- card queries ----
  CreditCard cardById(String id) => cards.firstWhere((c) => c.id == id);
  List<CardItem> items(CreditCard c) => [...c.items, ...addedParcels.where((x) => x.cardId == c.id).map((x) => x.item)];
  double invTotal(CreditCard c) => items(c).where((i) => i.p != 0).fold(0.0, (a, i) => a + i.amt);
  InvStatus cardStatus(CreditCard c) => paid[c.id] == true ? InvStatus.paga : (c.baseStatus == 'Fechada' ? InvStatus.fechada : InvStatus.aberta);
  String itemName(String cardId, CardItem i) => edits['$cardId:${i.d}'] ?? i.d;

  // ---- month figures ----
  /// Seed + added movements, newest first (ties keep insertion order).
  List<Tx> get allTxs {
    final all = [...added, ...seedTxs];
    final idx = {for (var i = 0; i < all.length; i++) all[i].id: i};
    all.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
    });
    return all;
  }

  bool _thisMonth(Tx t) => t.monthIdx == kMonthIndex;
  double get income => baseIncome + added.where((t) => t.amt > 0 && _thisMonth(t)).fold(0.0, (a, t) => a + t.amt);
  double get spent => baseSpent + added.where((t) => t.amt < 0 && t.nov && _thisMonth(t)).fold(0.0, (a, t) => a - t.amt);
  double get commit => baseCommit;
  double get total => spent + commit;
  double get balance => income - total;
  double get margin => balance - goal;
  double get marginPerDay => margin.abs() / 27;
  String get goalNote => margin >= 0
      ? 'Meta de guardar ${money(goal)}: você ainda poderia gastar ${money(margin)} (cerca de ${money(marginPerDay)} por dia) sem comprometê-la.'
      : 'Para guardar ${money(goal)}, seria preciso cortar ${money(-margin)} — cerca de ${money(marginPerDay)} a menos por dia.';

  List<CardItem> get allCardItems => cards.expand(items).toList();

  String monthShort(int m) => mshort(m);
}
