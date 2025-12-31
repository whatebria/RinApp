import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/my_library_controller.dart';
import '../models/my_library_item.dart';
import 'book_detail_screen.dart';

class ShelfDetailScreen extends StatelessWidget {
  const ShelfDetailScreen({
    super.key,
    required this.shelfName,
  });

  final String shelfName;

  String _subtitle(MyLibraryItem x) {
    final parts = <String>[];
    if (x.myRating != null && x.myRating! > 0) parts.add('⭐ ${x.myRating}');
    if (x.pages != null && x.pages! > 0) parts.add('${x.pages} págs');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MyLibraryController>();

    final all = c.items;
    final list = all.where((x) {
      final s = (x.exclusiveShelf != null && x.exclusiveShelf!.trim().isNotEmpty)
          ? x.exclusiveShelf!.trim()
          : MyLibraryController.kNoShelfLabel;
      return s == shelfName;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(shelfName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.loading ? null : c.load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: list.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay libros en esta estantería.'),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final x = list[i];
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
                                errorBuilder: (_, __, ___) => _coverPlaceholder(),
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
