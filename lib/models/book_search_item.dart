class BookSearchItem {
  BookSearchItem({
    required this.source,   // "local" o "openlibrary_work"
    required this.sourceId, // local: catalog id, openlibrary: OL...W
    required this.title,
    this.titleNorm,
    this.authors = const [],
    this.coverUrl,
    this.isbn13,
    this.isbn10,
    this.yearPublished,
    this.pages,
    this.catalogBookId, // opcional (hint si ya existe en tu catálogo)
  });

  final String source;
  final String sourceId;

  final String title;
  final String? titleNorm;
  final List<String> authors;

  final String? coverUrl;
  final String? isbn13;
  final String? isbn10;
  final int? yearPublished;
  final int? pages;

  /// Si el item viene de local, será igual a `sourceId`.
  /// Si viene de OpenLibrary, puede venir null (y lo obtienes con ensure al hacer Add).
  final String? catalogBookId;

  bool get hasCatalogId => (catalogBookId ?? '').trim().isNotEmpty;

  factory BookSearchItem.fromMap(Map<String, dynamic> m) {
    String s(dynamic v) => (v ?? '').toString().trim();
    String? sOpt(dynamic v) {
      final t = (v ?? '').toString().trim();
      return t.isEmpty ? null : t;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    List<String> toStrList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    // Del server (Camino 1):
    // source, source_id, catalog_book_id (opcional)
    // Del local viejo:
    // id (cuando source = local)
    final source = s(m['source']).isEmpty ? 'local' : s(m['source']);

    final sourceId = s(m['source_id']).isNotEmpty
        ? s(m['source_id'])
        : s(m['id']); // compat con resultados locales viejos

    final catalogId = sOpt(m['catalog_book_id']) ?? sOpt(m['id']); // si viene local, id es el catalog

    final title = s(m['title']);
    final titleNorm = sOpt(m['title_norm']);

    return BookSearchItem(
      source: source,
      sourceId: sourceId,
      catalogBookId: catalogId,
      title: title,
      titleNorm: titleNorm,
      authors: toStrList(m['authors']),
      coverUrl: sOpt(m['cover_url']),
      isbn13: sOpt(m['isbn13']),
      isbn10: sOpt(m['isbn10']),
      yearPublished: toInt(m['year_published']),
      pages: toInt(m['pages']),
    );
  }
}
