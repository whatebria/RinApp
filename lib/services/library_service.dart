import 'package:rin/models/book_detail.dart';
import 'package:rin/services/cover_backfill.dart';
import 'package:rin/services/open_library_resolver.dart';
import 'package:rin/services/openlibrary_client.dart';

import '../../data/repositories/library_repository.dart';
import '../models/my_library_item.dart';

class LibraryService {
  LibraryService({required LibraryRepository repo}) : _repo = repo;

  final LibraryRepository _repo;

  /// Librería del usuario.
  /// Fuente principal: user_books (1 fila por user + catalog_book_id).
  /// No filtra por shelves (porque shelves puede faltar y no debería ocultar libros).
  ///
  Future<List<MyLibraryItem>> fetchMine({int limit = 1000}) async {
    final raw = await _repo.fetchMyLibraryRaw(limit: limit);
    final items = raw.map(MyLibraryItem.fromRow).toList();

    final backfill = CoverBackfill(
      repo: _repo,
      resolver: OpenLibraryCoverResolver(minW: 100, minH: 150),
      client: OpenLibraryClient(),
      minW: 100,
      minH: 150,
    );

    for (var i = 0; i < items.length; i++) {
      items[i] = await backfill.fixOne(items[i]);
    }

    return items;
  }

  Future<BookDetail> fetchBookDetail({required String catalogBookId}) {
    return _repo.fetchBookDetail(catalogBookId: catalogBookId);
  }

  Future<void> upsertMyBook({
    required String catalogBookId,
    String? exclusiveShelf,
    int? myRating,
    String? dateRead,
  }) {
    return _repo.upsertMyBook(
      catalogBookId: catalogBookId,
      exclusiveShelf: exclusiveShelf,
      myRating: myRating,
      dateRead: dateRead,
    );
  }

  Future<bool> ensureBookCover({required BookDetail detail}) async {
    final backfill = CoverBackfill(
      repo: _repo,
      resolver: OpenLibraryCoverResolver(minW: 100, minH: 150),
      client: OpenLibraryClient(),
      minW: 100,
      minH: 150,
    );

    // Adaptación mínima: necesitamos un MyLibraryItem-like
    final temp = MyLibraryItem(
      catalogBookId: detail.catalogBookId,
      title: detail.title,
      coverUrl: detail.coverUrl,
      isbn10: detail.isbn10,
      isbn13: detail.isbn13,
      openLibraryCoverId: detail.openLibraryCoverId,
      cover: detail.cover,
      pages: detail.pages,
      yearPublished: detail.yearPublished,
      myRating: detail.myRating,
      exclusiveShelf: detail.exclusiveShelf,
      dateAdded: null,
      dateRead: null,
    );

    final fixed = await backfill.fixOne(temp);

    // Si cambió algo realmente, devuelve true
    return fixed.coverUrl != detail.coverUrl ||
        fixed.openLibraryCoverId != detail.openLibraryCoverId ||
        (fixed.cover?.widthPx != detail.cover?.widthPx) ||
        (fixed.cover?.heightPx != detail.cover?.heightPx);
  }

  Future<void> addToLibrary({
  required String catalogBookId,
  String exclusiveShelf = 'to-read',
}) {
  return _repo.addToLibrary(
    catalogBookId: catalogBookId,
    exclusiveShelf: exclusiveShelf,
  );
}

}
