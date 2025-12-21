import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rin/models/coverMeta.dart';

class OpenLibraryCoverResolver {
  OpenLibraryCoverResolver({this.minW = 100, this.minH = 150});

  final int minW;
  final int minH;

  List<(CoverQuality, String)> _candidates(String id) => [
    (
      CoverQuality.l,
      'https://covers.openlibrary.org/b/id/$id-L.jpg?default=false',
    ),
    (
      CoverQuality.m,
      'https://covers.openlibrary.org/b/id/$id-M.jpg?default=false',
    ),
    (
      CoverQuality.s,
      'https://covers.openlibrary.org/b/id/$id-S.jpg?default=false',
    ),
  ];

  String isbnUrl(String isbn, CoverQuality q) {
    final size = switch (q) {
      CoverQuality.l => 'L',
      CoverQuality.m => 'M',
      CoverQuality.s => 'S',
      _ => 'M',
    };
    return 'https://covers.openlibrary.org/b/ISBN/$isbn-$size.jpg?default=false';
  }

  Future<CoverMeta> resolve(String? openLibraryCoverId) async {
    if (openLibraryCoverId == null || openLibraryCoverId.trim().isEmpty) {
      return CoverMeta.none();
    }

    for (final (q, url) in _candidates(openLibraryCoverId)) {
      final size = await _getSize(url);
      if (size == null) continue;

      final (w, h) = size;
      if (w < minW || h < minH) continue;

      return CoverMeta(
        source: CoverSource.openLibrary,
        quality: q,
        url: url,
        widthPx: w,
        heightPx: h,
      );
    }

    return CoverMeta.none();
  }

  Future<(int, int)?> getSize(String url) => _getSize(url);

  Future<(int, int)?> _getSize(String url) async {
    final provider = NetworkImage(url);
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info);
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!completer.isCompleted) completer.completeError('load_error');
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);

    try {
      final info = await completer.future.timeout(const Duration(seconds: 5));
      return (info.image.width, info.image.height);
    } catch (_) {
      return null;
    }
  }
}
