import 'package:flutter/material.dart';
import '../services/goodreads_repository.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _repo = GoodreadsRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchMine();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.fetchMine();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis libros"),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text("Aún no tienes libros importados."),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = items[i];

              // ✅ ahora viene de fetchMine() (join user_books -> catalog_books)
              final book = (row['catalog_books'] as Map?) ?? {};
              

              final titleRaw = (book['title'] as String?)?.trim();
              final title = (titleRaw == null || titleRaw.isEmpty)
                  ? 'Sin título'
                  : titleRaw;

              final shelf = (row['exclusive_shelf'] ?? '').toString();
              final rating = row['my_rating']?.toString() ?? '';

              return ListTile(
                leading: const Icon(Icons.book_outlined),
                title: Text(title),
                subtitle: Text(
                  [
                    if (shelf.isNotEmpty) shelf,
                    if (rating.isNotEmpty) "⭐ $rating",
                  ].join(' • '),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
