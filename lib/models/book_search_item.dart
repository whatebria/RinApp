class BookSearchItem {
  BookSearchItem({
    required this.catalogBookId,
    required this.title,
    this.coverUrl,
    this.isbn13,
    this.isbn10,
    this.yearPublished,
    this.pages,
  });

  final String catalogBookId; // catalog_books.id
  final String title;
  final String? coverUrl;
  final String? isbn13;
  final String? isbn10;
  final int? yearPublished;
  final int? pages;

  factory BookSearchItem.fromMap(Map<String, dynamic> m) {
    final id = (m['id'] ?? m['catalog_book_id'] ?? '').toString().trim();
    final title = (m['title'] ?? '').toString().trim();

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    String? toStr(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return BookSearchItem(
      catalogBookId: id,
      title: title,
      coverUrl: toStr(m['cover_url']),
      isbn13: toStr(m['isbn13']),
      isbn10: toStr(m['isbn10']),
      yearPublished: toInt(m['year_published']),
      pages: toInt(m['pages']),
    );
  }
}
