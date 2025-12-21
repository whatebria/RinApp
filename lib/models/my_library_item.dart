class MyLibraryItem {
  MyLibraryItem({
    required this.catalogBookId,
    required this.title,
    this.coverUrl,
    this.pages,
    this.yearPublished,
    this.myRating,
    this.exclusiveShelf,
    this.dateAdded,
    this.dateRead,
  });

  final String catalogBookId;
  final String title;
  final String? coverUrl;
  final int? pages;
  final int? yearPublished;

  final int? myRating;
  final String? exclusiveShelf;
  final DateTime? dateAdded;
  final DateTime? dateRead;

  factory MyLibraryItem.fromRow(Map<String, dynamic> row) {
    final book = (row['catalog_books'] as Map?) ?? {};

    String? s(dynamic v) {
      final t = v?.toString().trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    int? i(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime? dt(dynamic v) {
      final t = s(v);
      if (t == null) return null;
      // date (yyyy-mm-dd) o timestamp
      return DateTime.tryParse(t);
    }

    final title = s(book['title']) ?? 'Sin título';

    return MyLibraryItem(
      catalogBookId: s(row['catalog_book_id']) ?? '',
      title: title,
      coverUrl: s(book['cover_url']),
      pages: i(book['pages']),
      yearPublished: i(book['year_published']),
      myRating: i(row['my_rating']),
      exclusiveShelf: s(row['exclusive_shelf']),
      dateAdded: dt(row['date_added']),
      dateRead: dt(row['date_read']),
    );
  }
}
