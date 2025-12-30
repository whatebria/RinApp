import 'package:rin/models/book_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LibraryRepository {
  LibraryRepository(this._sb);
  final SupabaseClient _sb;

  Future<void> addToLibrary({
    required String catalogBookId,
    String exclusiveShelf = 'to-read',
    DateTime? dateAdded,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No estás logueado');

    final id = catalogBookId.trim();
    if (id.isEmpty) throw Exception('catalogBookId vacío');

    final day = (dateAdded ?? DateTime.now()).toIso8601String().substring(
      0,
      10,
    );

    await _sb.from('user_books').upsert({
      'user_id': user.id,
      'catalog_book_id': id,
      'date_added': day,
      'exclusive_shelf': exclusiveShelf,
    });
  }

  Future<void> setShelves({
    required String catalogBookId,
    required List<String> shelves,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No estás logueado');

    final id = catalogBookId.trim();
    if (id.isEmpty) throw Exception('catalogBookId vacío');

    await _sb
        .from('user_book_shelves')
        .delete()
        .eq('user_id', user.id)
        .eq('catalog_book_id', id);

    final rows = shelves
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => {'user_id': user.id, 'catalog_book_id': id, 'shelf': s})
        .toList();

    if (rows.isEmpty) return;

    await _sb.from('user_book_shelves').insert(rows);
  }

  Future<List<Map<String, dynamic>>> fetchMyLibraryRaw({
    int limit = 1000,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No estás logueado');

    final data = await _sb
        .from('user_books')
        .select('''
    my_rating,
    date_read,
    date_added,
    exclusive_shelf,
    catalog_book_id,
    catalog_books!left(
  id,
  title,
  cover_url,
  isbn10,
  isbn13,
  openlibrary_cover_id,
  cover_source,
  cover_quality,
  cover_w,
  cover_h,
  pages,
  year_published
)

  ''')
        .eq('user_id', user.id)
        .order('date_added', ascending: false)
        .limit(limit);

    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateCatalogBookCover({
    required String catalogBookId,
    required Map<String, dynamic> patch,
  }) async {
    await _sb.from('catalog_books').update(patch).eq('id', catalogBookId);
  }

  Future<BookDetail> fetchBookDetail({required String catalogBookId}) async {
  final user = _sb.auth.currentUser;
  if (user == null) throw Exception('No estás logueado');

  final data = await _sb
      .from('catalog_books')
      .select('''
        id,
        title,
        cover_url,
        isbn10,
        isbn13,
        openlibrary_cover_id,
        cover_source,
        cover_quality,
        cover_w,
        cover_h,
        pages,
        year_published,
        description,

        user_book:user_books!left(
          user_id,
          exclusive_shelf,
          my_rating,
          date_read
        ),

        my_review:book_reviews!left(
          user_id,
          rating,
          body,
          contains_spoilers,
          updated_at
        )
      ''')
      .eq('id', catalogBookId)
      .eq('user_book.user_id', user.id)
      .eq('my_review.user_id', user.id)
      .maybeSingle();

  if (data == null) throw Exception('Libro no encontrado');

  return BookDetail.fromMap(data);
}

  Future<void> upsertMyBook({
    required String catalogBookId,
    String? exclusiveShelf,
    int? myRating,
    String? dateRead,
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No estás logueado');

    await _sb.from('user_books').upsert({
      'user_id': user.id,
      'catalog_book_id': catalogBookId,
      'exclusive_shelf': exclusiveShelf,
      'my_rating': myRating,
      'date_read': dateRead,
    }, onConflict: 'user_id,catalog_book_id');
  }

  

  Future<void> updateOpenLibraryCoverId({
    required String catalogBookId,
    required String openLibraryCoverId,
  }) async {
    await _sb
        .from('catalog_books')
        .update({'openlibrary_cover_id': openLibraryCoverId})
        .eq('id', catalogBookId);
  }

  Future<String> ensureCatalogBook({
    required String source,
    required String sourceId,
    required String title,
    required String titleNorm,
    String isbn10 = '',
    String isbn13 = '',
    String publisher = '',
    String binding = '',
    int? pages,
    int? yearPublished,
    String coverUrl = '',
  }) async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('No estás logueado');

    final res = await _sb.rpc(
      'ensure_catalog_book',
      params: {
        'p_source': source,
        'p_source_id': sourceId,
        'p_title': title,
        'p_title_norm': titleNorm,
        'p_isbn10': isbn10,
        'p_isbn13': isbn13,
        'p_publisher': publisher,
        'p_binding': binding,
        'p_pages': pages,
        'p_year_published': yearPublished,
        'p_cover_url': coverUrl,
      },
    );

    // Supabase devuelve el uuid como string
    final id = res?.toString().trim() ?? '';
    if (id.isEmpty) throw Exception('ensure_catalog_book devolvió vacío');
    return id;
  }
}
