class BookDetail {
  BookDetail({
    required this.catalogBookId,
    required this.title,
    this.coverUrl,
    this.pages,
    this.yearPublished,
    this.description,
    this.exclusiveShelf,
    this.myRating,
    this.dateRead,
  });

  final String catalogBookId;
  final String title;
  final String? coverUrl;
  final int? pages;
  final int? yearPublished;
  final String? description;

  // User-specific
  final String? exclusiveShelf;
  final int? myRating;
  final String? dateRead; // o DateTime?, dependiendo cómo lo guardes

  factory BookDetail.fromMap(Map<String, dynamic> m) {
    // user_book puede venir como List<Map> o como Map o null
    final ub = m['user_book'];

    Map<String, dynamic>? ubMap;
    if (ub is List && ub.isNotEmpty && ub.first is Map) {
      ubMap = (ub.first as Map).cast<String, dynamic>();
    } else if (ub is Map) {
      ubMap = (ub).cast<String, dynamic>();
    }

    return BookDetail(
      catalogBookId: m['id']?.toString() ?? '',
      title: (m['title'] ?? '').toString(),
      coverUrl: m['cover_url']?.toString(),
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
