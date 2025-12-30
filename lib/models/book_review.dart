class BookReview {
  final String id;
  final String bookId; // catalog_book_id
  final String userId;
  final int rating;
  final String? body;
  final bool containsSpoilers;
  final DateTime createdAt;

  // Perfil (join)
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  BookReview({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.containsSpoilers,
    required this.createdAt,
    this.body,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  factory BookReview.fromMap(Map<String, dynamic> m) {
    final profile = (m['profiles'] as Map?)?.cast<String, dynamic>();

    return BookReview(
      id: m['id'] as String,
      bookId: m['catalog_book_id'] as String,
      userId: m['user_id'] as String,
      rating: (m['rating'] as num).toInt(),
      body: m['body'] as String?,
      containsSpoilers: (m['contains_spoilers'] as bool?) ?? false,
      createdAt: DateTime.parse(m['created_at'] as String),
      displayName: profile?['display_name'] as String?,
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
