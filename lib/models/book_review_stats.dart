class BookReviewStats {
  final int reviewCount;
  final double avgRating;

  BookReviewStats({required this.reviewCount, required this.avgRating});

  factory BookReviewStats.fromRpc(dynamic data) {
    // Supabase rpc puede devolver List<Map> o Map, depende
    final row = (data is List && data.isNotEmpty) ? data.first : data;
    final count = (row['review_count'] as num?)?.toInt() ?? 0;
    final avg = (row['avg_rating'] as num?)?.toDouble() ?? 0.0;
    return BookReviewStats(reviewCount: count, avgRating: avg);
  }
}
