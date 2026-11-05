/// One movement read from a bank file, before categorisation/dedupe.
class ParsedTx {
  ParsedTx({required this.date, required this.amount, required this.description, this.extId, this.category, this.hint = ''});
  final DateTime date;
  final double amount; // negative = money out
  final String description;
  final String? extId; // FITID / identificador, when the bank gives one
  final String? category; // category column, when the file has one
  final String hint; // extra text (OFX TRNTYPE etc.) used to guess the method
}

class ParsedStatement {
  ParsedStatement({required this.format, required this.txs, this.bankName, this.accountLast, this.isCreditCard = false, this.inverted = false});
  final String format; // OFX | CSV
  final List<ParsedTx> txs;
  final String? bankName, accountLast;
  final bool isCreditCard;
  final bool inverted; // CSV whose positive values are expenses (e.g. card exports)
}

class ImportException implements Exception {
  ImportException(this.title, this.message);
  final String title, message;
  @override
  String toString() => '$title $message';
}
