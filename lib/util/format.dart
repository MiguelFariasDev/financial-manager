const monthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String _num(double v) {
  final s = v.abs().toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
    buf.write(intPart[i]);
  }
  return '$buf,${parts[1]}';
}

/// "R$ 1.234,56"; with [sign] prefixes "− " / "+ ".
String money(double v, {bool sign = false, bool symbol = true}) {
  final prefix = sign ? (v < 0 ? '− ' : '+ ') : '';
  return '$prefix${symbol ? 'R\$ ' : ''}${_num(v)}';
}

/// Short month label, e.g. index 10 -> "nov/26" (index may exceed 11).
String mshort(int m) => '${monthNames[m % 12].substring(0, 3).toLowerCase()}/${26 + m ~/ 12}';

/// "Novembro 2026" for an absolute month index (0 = janeiro/2026; negative = earlier years).
String monthTitle(int m) => '${monthNames[m % 12]} ${2026 + (m / 12).floor()}';

String mAbbr(int m) => monthNames[m % 12].substring(0, 3);

String oneDecimalPt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
