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
    this.myReviewRating,
    this.myReviewBody,
    this.myReviewContainsSpoiler,
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

  // My review (desde book_reviews)
  final int? myReviewRating;
  final String? myReviewBody;
  final bool? myReviewContainsSpoiler;

  String? get bestIsbn => (isbn13 != null && isbn13!.trim().isNotEmpty)
      ? isbn13!.trim()
      : (isbn10 != null && isbn10!.trim().isNotEmpty ? isbn10!.trim() : null);

  String? get bestCoverUrl => cover?.url ?? coverUrl;

  factory BookDetail.fromMap(Map<String, dynamic> m) {
  Map<String, dynamic>? asSingleMap(dynamic v) {
    if (v == null) return null;
    if (v is Map) return (v).cast<String, dynamic>();
    if (v is List && v.isNotEmpty && v.first is Map) {
      return (v.first as Map).cast<String, dynamic>();
    }
    return null;
  }

  final ubMap = asSingleMap(m['user_book']);
  final mrMap = asSingleMap(m['my_review']); // 👈 nuevo

  String? s(dynamic v) {
    final t = v?.toString().trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  int? i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  bool? b(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final t = v.toString().toLowerCase().trim();
    if (t == 'true') return true;
    if (t == 'false') return false;
    return null;
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

    pages: i(m['pages']),
    yearPublished: i(m['year_published']),
    description: m['description']?.toString(),

    exclusiveShelf: s(ubMap?['exclusive_shelf']),
    myRating: i(ubMap?['my_rating']),
    dateRead: ubMap?['date_read']?.toString(),

    // 👇 NUEVO: mi review desde book_reviews
    myReviewRating: i(mrMap?['rating']),
    myReviewBody: s(mrMap?['body']),
    myReviewContainsSpoiler: b(mrMap?['contains_spoiler']),
  );
}

}
