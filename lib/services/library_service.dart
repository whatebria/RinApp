import 'package:rin/models/book_detail.dart';

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
    return raw.map(MyLibraryItem.fromRow).toList();
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
}
