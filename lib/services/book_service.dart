import '../../data/datasources/book_remote_datasource.dart';
import '../../data/repositories/library_repository.dart';
import '../models/book_search_item.dart';

class BookService {
  BookService({
    required BookRemoteDatasource remote,
    required LibraryRepository library,
  })  : _remote = remote,
        _library = library;

  final BookRemoteDatasource _remote;
  final LibraryRepository _library;

  Future<List<BookSearchItem>> search({
    required String query,
    int limit = 20,
  }) async {
    final raw = await _remote.searchBooksRaw(query: query, limit: limit);

    final items = raw
        .map(BookSearchItem.fromMap)
        // 👇 OJO: ya NO filtramos por catalogBookId porque OpenLibrary puede no traerlo
        .where((b) => b.title.trim().isNotEmpty && b.sourceId.trim().isNotEmpty)
        .toList();

    return items;
  }

  /// ✅ Solo asegura un catalog_book_id para poder abrir BookDetail
  /// NO agrega a user_books.
  Future<String> ensureCatalogId({required BookSearchItem book}) async {
    if (book.hasCatalogId) return book.catalogBookId!.trim();

    final titleNorm = (book.titleNorm ?? book.title).toLowerCase().trim();

    return await _library.ensureCatalogBook(
      source: book.source,
      sourceId: book.sourceId,
      title: book.title,
      titleNorm: titleNorm,
      isbn10: book.isbn10 ?? '',
      isbn13: book.isbn13 ?? '',
      pages: book.pages,
      yearPublished: book.yearPublished,
      coverUrl: book.coverUrl ?? '',
    );
  }

  
}
