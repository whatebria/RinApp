enum CoverSource { openLibrary, unknown, none }
enum CoverQuality { l, m, s, none }

class CoverMeta {
  const CoverMeta({
    required this.source,
    required this.quality,
    required this.url,
    required this.widthPx,
    required this.heightPx,
  });

  final CoverSource source;
  final CoverQuality quality;
  final String? url;
  final int widthPx;
  final int heightPx;

  bool get isUsable =>
    url != null &&
    url!.trim().isNotEmpty &&
    widthPx > 0 &&
    heightPx > 0;


  static CoverMeta none() => const CoverMeta(
        source: CoverSource.none,
        quality: CoverQuality.none,
        url: null,
        widthPx: 0,
        heightPx: 0,
      );

  Map<String, dynamic> toDb() => {
        'cover_source': source.name,
        'cover_quality': quality.name,
        'cover_url': url,
        'cover_w': widthPx,
        'cover_h': heightPx,
      };

  static CoverMeta fromDb(Map<String, dynamic> row) {
    final src = (row['cover_source'] as String?) ?? 'unknown';
    final q = (row['cover_quality'] as String?) ?? 'none';
    final url = (row['cover_url'] as String?)?.trim();

    return CoverMeta(
      source: CoverSource.values.firstWhere(
        (e) => e.name == src,
        orElse: () => CoverSource.unknown,
      ),
      quality: CoverQuality.values.firstWhere(
        (e) => e.name == q,
        orElse: () => CoverQuality.none,
      ),
      url: (url == null || url.isEmpty) ? null : url,
      widthPx: (row['cover_w'] as int?) ?? 0,
      heightPx: (row['cover_h'] as int?) ?? 0,
    );
  }
}
