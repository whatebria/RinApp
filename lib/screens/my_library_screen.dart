import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rin/models/my_library_item.dart';
import 'package:rin/screens/book_detail_screen.dart';
import '../services/library_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/library_repository.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  late final LibraryService _service;

  bool _loading = false;
  String? _error;
  List<MyLibraryItem> _items = const [];

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;
    _service = LibraryService(repo: LibraryRepository(sb));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchMine(limit: 1000);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis libros'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $_error'),
                  ),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aún no tienes libros agregados.'),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final x = _items[i];
                  final meta = x.cover;
                  final url =
                      (meta != null &&
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
                          builder: (_) =>
                              BookDetailScreen(catalogBookId: x.catalogBookId),
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
