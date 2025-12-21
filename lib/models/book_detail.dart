import 'package:rin/models/coverMeta.dart';

class BookDetail {
  BookDetail({
    required this.catalogBookId,
    required this.title,
    this.coverUrl,
    this.cover,
    this.isbn10,
    this.isbn13,
    this.openLibraryCoverId,
    this.pages,
    this.yearPublished,
    this.description,
    this.exclusiveShelf,
    this.myRating,
    this.dateRead,
  });

  final String catalogBookId;
  final String title;

  final String? coverUrl; // legacy
  final CoverMeta? cover;

  final String? isbn10;
  final String? isbn13;
  final String? openLibraryCoverId;

  final int? pages;
  final int? yearPublished;
  final String? description;

  // User-specific
  final String? exclusiveShelf;
  final int? myRating;
  final String? dateRead;

  String? get bestIsbn => (isbn13 != null && isbn13!.trim().isNotEmpty)
      ? isbn13!.trim()
      : (isbn10 != null && isbn10!.trim().isNotEmpty ? isbn10!.trim() : null);

  String? get bestCoverUrl => cover?.url ?? coverUrl;

  factory BookDetail.fromMap(Map<String, dynamic> m) {
    final ub = m['user_book'];

    Map<String, dynamic>? ubMap;
    if (ub is List && ub.isNotEmpty && ub.first is Map) {
      ubMap = (ub.first as Map).cast<String, dynamic>();
    } else if (ub is Map) {
      ubMap = (ub).cast<String, dynamic>();
    }

    String? s(dynamic v) {
      final t = v?.toString().trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final coverMetaParsed = CoverMeta.fromDb(m);
    final coverMeta = coverMetaParsed.isUsable ? coverMetaParsed : null;

    return BookDetail(
      catalogBookId: m['id']?.toString() ?? '',
      title: (m['title'] ?? '').toString(),

      coverUrl: s(m['cover_url']),
      cover: coverMeta,

      isbn10: s(m['isbn10']),
      isbn13: s(m['isbn13']),
      openLibraryCoverId: s(m['openlibrary_cover_id']),

      pages: m['pages'] is int
          ? m['pages'] as int
          : int.tryParse('${m['pages']}'),
      yearPublished: m['year_published'] is int
          ? m['year_published'] as int
          : int.tryParse('${m['year_published']}'),
      description: m['description']?.toString(),

      exclusiveShelf: ubMap?['exclusive_shelf']?.toString(),
      myRating: ubMap?['my_rating'] is int
          ? ubMap!['my_rating'] as int
          : int.tryParse('${ubMap?['my_rating']}'),
      dateRead: ubMap?['date_read']?.toString(),
    );
  }
}
