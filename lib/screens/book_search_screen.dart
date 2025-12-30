import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/models/book_search_item.dart';
import 'package:rin/screens/book_detail_screen.dart';

import '../controller/book_search_controller.dart';
import '../providers/book_search_provider.dart';

class BookSearchScreen extends StatelessWidget {
  const BookSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookSearchProvider(
      child: _BookSearchView(),
    );
  }
}

class _BookSearchView extends StatefulWidget {
  const _BookSearchView();

  @override
  State<_BookSearchView> createState() => _BookSearchViewState();
}

class _BookSearchViewState extends State<_BookSearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear(BookSearchController c) {
    _controller.clear();
    c.clearResults();
    FocusScope.of(context).unfocus();
  }

  Future<void> _openDetail(
    BuildContext context,
    BookSearchController c,
    BookSearchItem b,
  ) async {
    try {
      final catalogId = await c.ensureCatalogId(b);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(catalogBookId: catalogId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<BookSearchController>();

    // Mantener el texto del SearchBar consistente si el controller limpió resultados
    // (no forzamos sync agresivo para evitar loops).
    final showClear = _controller.text.isNotEmpty;

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
                if (showClear)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _clear(c),
                  ),
              ],
              onChanged: c.setQuery,
              onSubmitted: (v) => c.search(v),
            ),
          ),
          if (c.loading) const LinearProgressIndicator(minHeight: 2),
          if (c.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                c.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: c.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      c.loading ? 'Buscando...' : 'Escribe algo para buscar libros.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    itemCount: c.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final b = c.items[i];

                      final subtitleParts = <String>[];
                      if (b.yearPublished != null) subtitleParts.add('${b.yearPublished}');
                      if (b.isbn13 != null) subtitleParts.add('ISBN13: ${b.isbn13}');
                      final subtitle = subtitleParts.join(' • ');

                      return ListTile(
                        onTap: () => _openDetail(context, c, b),
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
