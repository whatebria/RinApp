class DateTimeParser {
  static const Map<String, int> _monthMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static DateTime parseFlexible(String input) {
    final text = input.trim();
    if (text.isEmpty) throw Exception("Fecha vacía");

    // 1) ISO
    try {
      return DateTime.parse(text);
    } catch (_) {}

    // 2) dd/MM/yyyy o dd-MM-yyyy (sin hora)
    final numeric = RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$');
    final m = numeric.firstMatch(text);
    if (m != null) {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final y = int.parse(m.group(3)!);
      return DateTime(y, mo, d);
    }

    // 3) 14 dec 2025, 16:11
    return _parseTextMonth(text);
  }

  static DateTime _parseTextMonth(String input) {
    final text = input.trim().toLowerCase();
    final regex = RegExp(r'^(\d{1,2})\s+([a-z]{3})\s+(\d{4}),\s*(\d{1,2}):(\d{2})$');
    final match = regex.firstMatch(text);
    if (match == null) throw Exception("Formato de fecha inválido: $input");

    final day = int.parse(match.group(1)!);
    final monthText = match.group(2)!;
    final year = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);

    final month = _monthMap[monthText];
    if (month == null) throw Exception("Mes inválido: $monthText");

    return DateTime(year, month, day, hour, minute);
  }
}
