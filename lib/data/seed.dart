import 'package:flutter/material.dart';
import 'models.dart';

/// Demo reference date used by the prototype (quarta, 4 de novembro de 2026).
/// All seed data below is relative to it.
const kTodayDay = 4;
const kDaysInMonth = 30;
const kMonthIndex = 10; // novembro
const kUserName = 'Marina';
final kToday = DateTime(2026, 11, 4);
/// Moment recorded on import batches.
DateTime get kNow => DateTime.now();

const cats = [
  Cat('Alimentação', 'fork-knife'), Cat('Transporte', 'car-profile'), Cat('Moradia', 'house-line'),
  Cat('Saúde', 'first-aid-kit'), Cat('Lazer', 'film-strip'), Cat('Compras', 'shopping-bag'),
  Cat('Educação', 'graduation-cap'), Cat('Outros', 'dots-three-circle'),
];

String catIcon(String k) => cats.firstWhere((c) => c.k == k, orElse: () => const Cat('', 'receipt')).icon;

final seedTxs = <Tx>[
  Tx(id: 10, d: 'Condomínio', cat: 'Moradia', icon: 'buildings', amt: -680, m: 'PIX', acc: 'Itaú conta', day: 'Agendadas', st: 'futura', due: '15 nov', date: DateTime(2026, 11, 15)),
  Tx(id: 11, d: 'Internet Vivo', cat: 'Moradia', icon: 'wifi-high', amt: -129.9, m: 'Débito', acc: 'Itaú conta', day: 'Agendadas', st: 'futura', due: '18 nov', date: DateTime(2026, 11, 18)),
  Tx(id: 1, d: 'Pão de Açúcar', cat: 'Alimentação', icon: 'basket', amt: -186.4, m: 'Crédito', acc: 'Nubank ••4821', day: 'Hoje', st: 'paga', date: DateTime(2026, 11, 4)),
  Tx(id: 2, d: 'Uber', cat: 'Transporte', icon: 'car-profile', amt: -32.9, m: 'Crédito', acc: 'Nubank ••4821', day: 'Hoje', st: 'paga', date: DateTime(2026, 11, 4)),
  Tx(id: 3, d: 'Salário · Acme Ltda', cat: 'Receita', icon: 'briefcase', amt: 12500, m: 'PIX', acc: 'Itaú conta', day: 'Ontem, 3 nov', st: 'paga', date: DateTime(2026, 11, 3)),
  Tx(id: 4, d: 'Aluguel', cat: 'Moradia', icon: 'house-line', amt: -2150, m: 'PIX', acc: 'Itaú conta', day: 'Ontem, 3 nov', st: 'paga', date: DateTime(2026, 11, 3)),
  Tx(id: 5, d: 'Drogasil', cat: 'Saúde', icon: 'first-aid-kit', amt: -84.7, m: 'Débito', acc: 'Itaú conta', day: 'Seg, 2 nov', st: 'paga', date: DateTime(2026, 11, 2)),
  Tx(id: 6, d: 'Feira livre', cat: 'Alimentação', icon: 'carrot', amt: -48, m: 'Dinheiro', acc: 'Carteira', day: 'Seg, 2 nov', st: 'paga', date: DateTime(2026, 11, 2)),
  Tx(id: 7, d: 'Freela · identidade visual', cat: 'Receita', icon: 'pen-nib', amt: 1800, m: 'PIX', acc: 'Nubank conta', day: 'Dom, 1 nov', st: 'pendente', date: DateTime(2026, 11, 1)),
  Tx(id: 8, d: 'iPhone 16 Pro · 3/10', cat: 'Compras', icon: 'device-mobile', amt: -649.9, m: 'Crédito', acc: 'Nubank ••4821', day: 'Dom, 1 nov', st: 'paga', date: DateTime(2026, 11, 1), card: 'nu'),
  Tx(id: 9, d: 'Cinema', cat: 'Lazer', icon: 'film-strip', amt: -64, m: 'Crédito', acc: 'Itaú ••0937', day: 'Dom, 1 nov', st: 'paga', date: DateTime(2026, 11, 1)),
];

const dayOrder = ['Agendadas', 'Hoje', 'Ontem, 3 nov', 'Seg, 2 nov', 'Dom, 1 nov'];

const seedCards = <CreditCard>[
  CreditCard(
    id: 'nu', bank: 'Nubank', nick: 'Dia a dia', last: '4821', lim: 8000, used: 3412.8, close: 3,
    closeStr: '03/11', dueStr: '10/11', bg: Color(0xFF201E1D), net: 'Mastercard', baseStatus: 'Fechada',
    items: [
      CardItem('iPhone 16 Pro', 'Compras', 649.9, inst: '3/10', n: 10, p: 3),
      CardItem('Sofá Tok&Stok', 'Moradia', 329, inst: '6/10', n: 10, p: 6),
      CardItem('Passagens LATAM', 'Lazer', 412.5, inst: '2/4', n: 4, p: 2),
      CardItem('Pão de Açúcar', 'Alimentação', 312.8, date: '28 out'),
      CardItem('Mocotó', 'Alimentação', 186, date: '25 out'),
      CardItem('Uber · 8 viagens', 'Transporte', 142.3, date: 'out'),
      CardItem('Amazon', 'Compras', 130.2, date: '19 out'),
      CardItem('Spotify', 'Lazer', 21.9, date: '15 out'),
    ],
    recent: [CardRecent('Pão de Açúcar', 'Alimentação', 186.4, 'hoje'), CardRecent('Uber', 'Transporte', 32.9, 'hoje')],
    recentNote: 'Entram na fatura de dezembro — a de novembro fechou em 03/11.',
    prev: [('Outubro', 2402.15), ('Setembro', 1980.3), ('Agosto', 2110)],
    next: [NextInv('Dezembro', 1586.2, 'Aberta'), NextInv('Janeiro', 1391.4, 'Prevista'), NextInv('Fevereiro', 978.9, 'Prevista')],
  ),
  CreditCard(
    id: 'it', bank: 'Itaú', nick: 'Personnalité', last: '0937', lim: 15000, used: 4920, close: 13,
    closeStr: '13/11', dueStr: '20/11', bg: Color(0xFF006786), net: 'Visa', baseStatus: 'Aberta',
    items: [
      CardItem('Notebook Dell', 'Compras', 327.7, inst: '5/8', n: 8, p: 5),
      CardItem('Zara', 'Compras', 389.9, date: '30 out'),
      CardItem('Restaurante Mani', 'Alimentação', 268, date: '24 out'),
      CardItem('Posto Shell', 'Transporte', 210, date: '20 out'),
      CardItem('Cinema', 'Lazer', 64, date: '1 nov'),
      CardItem('Netflix', 'Lazer', 55.9, date: '18 out'),
    ],
    recent: [CardRecent('Cinema', 'Lazer', 64, '1 nov'), CardRecent('Zara', 'Compras', 389.9, '30 out')],
    recentNote: 'Fatura de novembro aberta até 13/11.',
    prev: [('Outubro', 1480.2), ('Setembro', 1204.55), ('Agosto', 1390)],
    next: [NextInv('Dezembro', 655.4, 'Prevista'), NextInv('Janeiro', 655.4, 'Prevista'), NextInv('Fevereiro', 327.7, 'Prevista')],
  ),
  CreditCard(
    id: 'in', bank: 'Inter', nick: 'Viagens', last: '5520', lim: 5000, used: 640, close: 25,
    closeStr: '25/11', dueStr: '02/12', bg: Color(0xFFAA0B56), net: 'Mastercard', baseStatus: 'Aberta',
    items: [
      CardItem('Hotel · Booking', 'Lazer', 420, inst: '1/3', n: 3, p: 1),
      CardItem('Airbnb · taxa', 'Lazer', 98, date: '29 out'),
      CardItem('Uber aeroporto', 'Transporte', 122, date: '28 out'),
    ],
    recent: [CardRecent('Uber aeroporto', 'Transporte', 122, '28 out')],
    recentNote: 'Fatura de novembro aberta até 25/11.',
    prev: [('Outubro', 0), ('Setembro', 312), ('Agosto', 0)],
    next: [NextInv('Dezembro', 420, 'Prevista'), NextInv('Janeiro', 420, 'Prevista')],
  ),
];

const importFiles = [
  ImportFile('extrato_itau_outubro.ofx', 'OFX', '84 KB', 'file-text'),
  ImportFile('nubank_conta_2026-10.csv', 'CSV', '12 KB', 'file-csv'),
  ImportFile('planilha_gastos.xlsx', 'XLSX', '2,1 MB', 'file-xls', bad: true),
];

/// Category totals for the month and default limits.
const catData = <(String, double)>[
  ('Moradia', 2150), ('Alimentação', 1284.5), ('Compras', 918),
  ('Transporte', 612.4), ('Lazer', 498), ('Saúde', 380),
];
const defaultLimits = {'Moradia': 3000.0, 'Alimentação': 1500.0, 'Compras': 800.0, 'Transporte': 700.0, 'Lazer': 600.0, 'Saúde': 500.0};

const baseIncome = 12500.0;
const baseSpent = 5842.9;
const baseCommit = 2310.0;
const fixedExpenses = 3620.0;
