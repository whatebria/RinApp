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
        .where((b) => b.catalogBookId.isNotEmpty && b.title.isNotEmpty)
        .toList();

    return items;
  }

  Future<void> add({
    required BookSearchItem book,
    String exclusiveShelf = 'to-read',
  }) async {
    await _library.addToLibrary(
      catalogBookId: book.catalogBookId,
      exclusiveShelf: exclusiveShelf,
    );

  }
}
