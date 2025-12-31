import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class OpenLibraryClient {
  Future<String?> fetchCoverIdByIsbn(String isbn) async {
    final clean = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (clean.isEmpty) return null;

    // Intento 1: /isbn/{isbn}.json (rápido si existe)
    final u1 = Uri.parse('https://openlibrary.org/isbn/$clean.json');
    final r1 = await http.get(u1);
    if (r1.statusCode == 200) {
      final j = jsonDecode(r1.body) as Map<String, dynamic>;
      final covers = j['covers'];
      if (covers is List && covers.isNotEmpty) {
        return covers.first.toString(); // <- cover id
      }
      // a veces viene "covers" vacío, entonces seguimos
    }

    // Intento 2: search.json?isbn=...
    final u2 = Uri.parse('https://openlibrary.org/search.json?isbn=$clean');
    final r2 = await http.get(u2);
    if (r2.statusCode != 200) return null;

    final j2 = jsonDecode(r2.body) as Map<String, dynamic>;
    final docs = j2['docs'];
    if (docs is List && docs.isNotEmpty) {
      final first = docs.first as Map<String, dynamic>;
      final coverI = first['cover_i'];
      if (coverI != null) return coverI.toString();
    }
    return null;
  }
}
