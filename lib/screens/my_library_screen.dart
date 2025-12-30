import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/models/my_library_item.dart';
import 'package:rin/screens/book_detail_screen.dart';

import '../controller/my_library_controller.dart';
import '../providers/my_library_provider.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyLibraryProvider(
      child: _MyLibraryView(),
    );
  }
}

class _MyLibraryView extends StatelessWidget {
  const _MyLibraryView();

  String _subtitle(MyLibraryItem x) {
    final parts = <String>[];
    if (x.exclusiveShelf != null && x.exclusiveShelf!.isNotEmpty) {
      parts.add(x.exclusiveShelf!);
    }
    if (x.myRating != null && x.myRating! > 0) parts.add('⭐ ${x.myRating}');
    if (x.pages != null && x.pages! > 0) parts.add('${x.pages} págs');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MyLibraryController>();
    final items = c.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis libros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.loading ? null : c.load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: c.loading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: ${c.error}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton(
                          onPressed: c.load,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  )
                : items.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aún no tienes libros agregados.'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final x = items[i];
                          final meta = x.cover;
                          final url = (meta != null &&
                                  meta.isUsable &&
                                  meta.widthPx >= 100 &&
                                  meta.heightPx >= 150)
                              ? meta.url
                              : null;

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 42,
                                height: 60,
                                child: (url != null)
                                    ? Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _coverPlaceholder(),
                                      )
                                    : _coverPlaceholder(),
                              ),
                            ),
                            title: Text(
                              x.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_subtitle(x)),
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => BookDetailScreen(
                                    catalogBookId: x.catalogBookId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Icon(Icons.book_outlined, size: 22),
    );
  }
}
