String cleanExcelWrapped(String v) {
  var s = v.trim();
  // Goodreads/Excel: ="978...."
  if (s.startsWith('="') && s.endsWith('"')) {
    s = s.substring(2, s.length - 1);
  }
  // Quitar comillas externas si quedaron
  if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
    s = s.substring(1, s.length - 1);
  }
  return s.trim();
}

String toPgDate(String goodreadsDate) {
  final t = goodreadsDate.trim();
  if (t.isEmpty) return '';
  final parts = t.split('/');
  if (parts.length == 3) {
    final y = parts[0].padLeft(4, '0');
    final m = parts[1].padLeft(2, '0');
    final d = parts[2].padLeft(2, '0');
    return '$y-$m-$d'; // Postgres date
  }
  return '';
}

List<String> splitCommaList(String s) =>
    s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
