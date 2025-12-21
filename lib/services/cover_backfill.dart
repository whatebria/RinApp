import 'package:rin/models/coverMeta.dart';
import 'package:rin/models/my_library_item.dart';
import 'package:rin/services/open_library_resolver.dart';
import 'package:rin/services/openlibrary_client.dart';
import 'package:rin/data/repositories/library_repository.dart';

class CoverBackfill {
  CoverBackfill({
    required this.repo,
    required this.resolver,
    required this.client,
    this.minW = 100,
    this.minH = 150,
  });

  final LibraryRepository repo;
  final OpenLibraryCoverResolver resolver;
  final OpenLibraryClient client;
  final int minW;
  final int minH;

  /// Decide si el libro necesita que le calculemos/guardemos cover meta.
  bool needsFix(MyLibraryItem it) {
    final meta = it.cover; // CoverMeta?
    if (meta == null) return true;
    if (!meta.isUsable) return true;
    if (meta.widthPx < minW || meta.heightPx < minH) return true;
    return false;
  }

  String? _extractIdFromUrl(String? url) {
    if (url == null) return null;
    final m = RegExp(
      r'covers\.openlibrary\.org\/b\/id\/(\d+)-',
    ).firstMatch(url);
    return m?.group(1);
  }

  CoverQuality _qualityFromUrl(String? url) {
    if (url == null) return CoverQuality.none;
    final m = RegExp(r'-(L|M|S)\.jpg', caseSensitive: false).firstMatch(url);
    final q = m?.group(1)?.toLowerCase();
    return switch (q) {
      'l' => CoverQuality.l,
      'm' => CoverQuality.m,
      's' => CoverQuality.s,
      _ => CoverQuality.none,
    };
  }

  bool _isOpenLibraryCoversUrl(String? url) =>
      url != null && url.contains('covers.openlibrary.org');

  /// Intenta poblar:
  /// - openlibrary_cover_id (si la URL ya es /b/id/...)
  /// - cover_w/cover_h/cover_quality/cover_source usando la URL actual
  /// - y si hay openlibrary_cover_id, también puede elegir mejor L/M/S (resolver)
  Future<MyLibraryItem> fixOne(MyLibraryItem it) async {
    if (!needsFix(it)) return it;

    final currentUrl = (it.coverUrl ?? '').trim();

    (it.coverUrl ?? '').trim();

// A) si URL es /b/id/..., extraemos id y lo guardamos
var olId = it.openLibraryCoverId;
if (olId == null || olId.isEmpty) {
  final extracted = _extractIdFromUrl(currentUrl);
  if (extracted != null && extracted.isNotEmpty) {
    olId = extracted;
    await repo.updateOpenLibraryCoverId(
      catalogBookId: it.catalogBookId,
      openLibraryCoverId: extracted,
    );
  }
}

// B) si ya hay URL de OpenLibrary, medimos tamaño y guardamos meta
if (_isOpenLibraryCoversUrl(currentUrl)) {
  final size = await resolver.getSize(currentUrl);
  if (size != null) {
    final (w, h) = size;
    final q = _qualityFromUrl(currentUrl);

    // Guardamos cover meta (aunque sea chica)
    await repo.updateCatalogBookCover(
      catalogBookId: it.catalogBookId,
      patch: {
        'cover_source': CoverSource.openLibrary.name,
        'cover_quality': q.name,
        'cover_url': currentUrl,
        'cover_w': w,
        'cover_h': h,
      },
    );

    // Si ya cumple mínimos => listo
    if (w >= minW && h >= minH) {
      return it.copyWith(
        openLibraryCoverId: olId,
        coverUrl: currentUrl,
        cover: CoverMeta(
          source: CoverSource.openLibrary,
          quality: q,
          url: currentUrl,
          widthPx: w,
          heightPx: h,
        ),
      );
    }

    // Si es chica => la tratamos como mala y buscamos algo mejor por ID
    // (no retornamos, seguimos)
  }
  }

  // 0) Si hay URL de OpenLibrary con /b/id/, extraer ID y guardarlo
  if (olId == null || olId.isEmpty) {
    final extracted = _extractIdFromUrl(currentUrl);
    if (extracted != null && extracted.isNotEmpty) {
      olId = extracted;
      await repo.updateOpenLibraryCoverId(
        catalogBookId: it.catalogBookId,
        openLibraryCoverId: extracted,
      );
    }
  }
    // 1) Si ya tenemos una URL OpenLibrary existente, al menos guardar meta (w/h/quality/source)
    if (_isOpenLibraryCoversUrl(currentUrl)) {
      final size = await resolver.getSize(currentUrl);
      if (size != null) {
        final (w, h) = size;
        final q = _qualityFromUrl(currentUrl);

        await repo.updateCatalogBookCover(
          catalogBookId: it.catalogBookId,
          patch: {
            'cover_source': CoverSource.openLibrary.name,
            'cover_quality': q.name,
            'cover_url': currentUrl,
            'cover_w': w,
            'cover_h': h,
          },
        );

        final meta = CoverMeta(
          source: CoverSource.openLibrary,
          quality: q,
          url: currentUrl,
          widthPx: w,
          heightPx: h,
        );

        // si ya es suficientemente grande, listo
        if (meta.isUsable && w >= minW && h >= minH) {
          return it.copyWith(
            openLibraryCoverId: olId,
            coverUrl: currentUrl,
            cover: meta,
          );
        }
      }
    }

    // 2) Si aún no tenemos ID, intentar obtenerlo por ISBN (si existe)
    if (olId == null || olId.isEmpty) {
      final isbn = it.bestIsbn;
      if (isbn != null && isbn.isNotEmpty) {
        final fetched = await client.fetchCoverIdByIsbn(isbn);
        if (fetched != null && fetched.isNotEmpty) {
          olId = fetched;
          await repo.updateOpenLibraryCoverId(
            catalogBookId: it.catalogBookId,
            openLibraryCoverId: fetched,
          );
        }
      }
    }

    if (olId == null || olId.isEmpty) {
      // No hay forma de mejorar más
      return it;
    }

    // 3) Con ID, resolver L/M/S + tamaño mínimo y persistir lo mejor
    final best = await resolver.resolve(olId);
    if (!best.isUsable) return it;

    await repo.updateCatalogBookCover(
      catalogBookId: it.catalogBookId,
      patch: best.toDb(),
    );

    return it.copyWith(
      openLibraryCoverId: olId,
      coverUrl: best.url,
      cover: best,
    );
  }

}
