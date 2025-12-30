import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rin/models/book_search_item.dart';
import 'package:rin/screens/book_detail_screen.dart';
import 'package:rin/services/book_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/book_remote_datasource.dart';
import '../../data/repositories/library_repository.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  late final BookService _bookService;

  bool _loading = false;
  String? _error;
  List<BookSearchItem> _items = const [];

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;

    _bookService = BookService(
      remote: BookRemoteDatasource(sb),
      library: LibraryRepository(sb),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final q = v.trim();
      if (q.isEmpty) {
        setState(() {
          _items = const [];
          _error = null;
          _loading = false;
        });
        return;
      }
      _search(q);
    });
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _bookService.search(query: q, limit: 20);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar libros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              controller: _controller,
              hintText: 'Busca por título o autor (ej: Dune)',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _items = const [];
                        _error = null;
                        _loading = false;
                      });
                    },
                  ),
              ],
              onChanged: _onChanged,
              onSubmitted: (v) => _search(v.trim()),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: _items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _loading
                          ? 'Buscando...'
                          : 'Escribe algo para buscar libros.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final b = _items[i];
                      final subtitleParts = <String>[];
                      if (b.yearPublished != null) {
                        subtitleParts.add('${b.yearPublished}');
                      }
                      if (b.isbn13 != null) {
                        subtitleParts.add('ISBN13: ${b.isbn13}');
                      }
                      final subtitle = subtitleParts.join(' • ');

                      return ListTile(
                        onTap: () async {
                          final catalogId = await _bookService.ensureCatalogId(
                            book: b,
                          );
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookDetailScreen(catalogBookId: catalogId),
                            ),
                          );
                        },

                        leading: (b.coverUrl != null && b.coverUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  b.coverUrl!,
                                  width: 42,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.book_outlined),
                                ),
                              )
                            : const Icon(Icons.book_outlined),
                        title: Text(
                          b.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
