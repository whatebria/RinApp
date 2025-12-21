import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/book_detail_controller.dart';
import 'package:rin/models/book_detail.dart';
import 'package:rin/services/library_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/library_repository.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({
    super.key,
    required this.catalogBookId,
  });

  final String catalogBookId;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    final service = LibraryService(repo: LibraryRepository(sb));

    return ChangeNotifierProvider(
      create: (_) {
        final c = BookDetailController(
          service: service,
          catalogBookId: catalogBookId,
        );
        // importante: disparar load al crear el controller
        c.load();
        return c;
      },
      child: const _BookDetailView(),
    );
  }
}

class _BookDetailView extends StatelessWidget {
  const _BookDetailView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BookDetailController>();
    final d = c.detail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del libro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.refresh,
          ),
        ],
      ),
      body: c.loading && d == null
          ? const Center(child: CircularProgressIndicator())
          : c.error != null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Error: ${c.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: c.load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              : d == null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        Text('No se encontró el libro.'),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: () async => c.refresh(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _Header(detail: d),
                          const SizedBox(height: 18),
                          if ((d.description ?? '').trim().isNotEmpty) ...[
                            Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(d.description!),
                            const SizedBox(height: 18),
                          ],
                          Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _pickShelf(context),
                                icon: const Icon(Icons.bookmark_outline),
                                label: const Text('Cambiar estante'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickRating(context),
                                icon: const Icon(Icons.star_outline),
                                label: const Text('Cambiar rating'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Future<void> _pickShelf(BuildContext context) async {
    final c = context.read<BookDetailController>();
    final d = c.detail;
    if (d == null) return;

    const shelves = ['to-read', 'reading', 'read', 'dnf'];

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Cambiar estante'), dense: true),
            for (final s in shelves)
              ListTile(
                title: Text(s),
                trailing: (d.exclusiveShelf == s) ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );

    if (selected == null) return;

    try {
      await c.setShelf(selected);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickRating(BuildContext context) async {
    final c = context.read<BookDetailController>();
    final d = c.detail;
    if (d == null) return;

    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Tu rating')),
            for (final r in [0, 1, 2, 3, 4, 5])
              ListTile(
                title: Text(r == 0 ? 'Sin rating' : '⭐ $r'),
                trailing: (d.myRating == r) ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    );

    if (selected == null) return;

    try {
      await c.setRating(selected);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});
  final BookDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 110,
            height: 160,
            child: (detail.coverUrl != null && detail.coverUrl!.trim().isNotEmpty)
                ? Image.network(
                    detail.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (detail.yearPublished != null) _chip('Año', '${detail.yearPublished}'),
                  if (detail.pages != null) _chip('Páginas', '${detail.pages}'),
                ],
              ),
              const SizedBox(height: 12),
              _MyStatusCard(detail: detail),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }

  static Widget _coverPlaceholder() {
    return Container(
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Icon(Icons.book_outlined, size: 28),
    );
  }
}

class _MyStatusCard extends StatelessWidget {
  const _MyStatusCard({required this.detail});
  final BookDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final shelf = (detail.exclusiveShelf == null || detail.exclusiveShelf!.isEmpty) ? '—' : detail.exclusiveShelf!;
    final rating = (detail.myRating == null || detail.myRating == 0) ? '—' : '⭐ ${detail.myRating}';
    final dateRead = detail.dateRead ?? '—';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi estado', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _kv('Shelf', shelf)),
                Expanded(child: _kv('Rating', rating)),
              ],
            ),
            const SizedBox(height: 8),
            _kv('Fecha leído', dateRead),
          ],
        ),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(v),
      ],
    );
  }
}
