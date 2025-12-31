import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rin/controller/book_detail_controller.dart';
import 'package:rin/models/book_detail.dart';

import '../providers/book_detail_provider.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.catalogBookId});

  final String catalogBookId;

  @override
  Widget build(BuildContext context) {
    return BookDetailProvider(
      catalogBookId: catalogBookId,
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: c.refresh),
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
                      children: const [Text('No se encontró el libro.')],
                    )
                  : RefreshIndicator(
                      onRefresh: () async => c.refresh(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _Header(detail: d),
                          const SizedBox(height: 18),
                          if ((d.description ?? '').trim().isNotEmpty) ...[
                            Text(
                              'Descripción',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(d.description!),
                            const SizedBox(height: 18),
                          ],
                          Text(
                            'Acciones',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 18),
                          const _ReviewsSection(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _pickShelf(context),
                                icon: const Icon(Icons.bookmark_outline),
                                label: const Text('Agregar a una lista'),
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
                trailing:
                    (d.exclusiveShelf == s) ? const Icon(Icons.check) : null,
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

// ---- el resto de tus widgets quedan IGUAL ----

class _Header extends StatelessWidget {
  const _Header({required this.detail});
  final BookDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = detail.bestCoverUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 110,
            height: 160,
            child: (url != null && url.trim().isNotEmpty)
                ? Image.network(
                    url,
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (detail.yearPublished != null)
                    _chip('Año', '${detail.yearPublished}'),
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

    final shelf =
        (detail.exclusiveShelf == null || detail.exclusiveShelf!.isEmpty)
        ? '—'
        : detail.exclusiveShelf!;
    final rating = (detail.myRating == null || detail.myRating == 0)
        ? '—'
        : '⭐ ${detail.myRating}';
    final dateRead = detail.dateRead ?? '—';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi estado',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
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
        Text(
          k,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(v),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BookDetailController>();

    final stats = c.reviewStats;
    final avg = stats?.avgRating ?? 0.0;
    final count = stats?.reviewCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('⭐ ${avg.toStringAsFixed(2)} ($count)'),
                const Spacer(),
                FilledButton(
                  onPressed: () => _openWriteReview(context),
                  child: Text(
                    c.myPublicReview == null
                        ? 'Escribir review'
                        : 'Editar mi review (${c.myPublicReview!.rating}⭐)',
                  ),
                ),
              ],
            ),
          ),
        ),

        if (c.loadingReviews)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (c.reviewsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Error: ${c.reviewsError}',
                style: const TextStyle(color: Colors.red)),
          ),

        const SizedBox(height: 8),

        if (!c.loadingReviews && c.reviews.isEmpty)
          const Text('Aún no hay reviews. Sé el primero 👀'),

        ...c.reviews.map((r) => _ReviewTile(
              displayName: r.displayName ?? r.username ?? 'Usuario',
              rating: r.rating,
              body: r.body,
              spoilers: r.containsSpoilers,
              createdAt: r.createdAt,
            )),
      ],
    );
  }

  Future<void> _openWriteReview(BuildContext context) async {
    final c = context.read<BookDetailController>();
    final mine = c.myPublicReview;

    final draft = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WriteReviewSheet(
        initialRating: mine?.rating ?? 5,
        initialBody: mine?.body ?? '',
        initialSpoilers: mine?.containsSpoilers ?? false,
        canDelete: mine != null,
        onDelete: () async {
          Navigator.pop(context);
          await c.deletePublicReview();
        },
      ),
    );

    if (draft == null) return;

    try {
      await c.savePublicReview(
        rating: draft.rating,
        body: draft.body,
        spoilers: draft.spoilers,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _ReviewTile extends StatelessWidget {
  final String displayName;
  final int rating;
  final String? body;
  final bool spoilers;
  final DateTime createdAt;

  const _ReviewTile({
    required this.displayName,
    required this.rating,
    required this.createdAt,
    this.body,
    this.spoilers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('$rating⭐'),
              ],
            ),
            if (spoilers) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: const Text('Spoiler', style: TextStyle(fontSize: 12)),
              ),
            ],
            if (body != null && body!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body!),
            ],
            const SizedBox(height: 8),
            Text(
              createdAt.toLocal().toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDraft {
  final int rating;
  final String? body;
  final bool spoilers;
  _ReviewDraft({required this.rating, required this.body, required this.spoilers});
}

class _WriteReviewSheet extends StatefulWidget {
  final int initialRating;
  final String initialBody;
  final bool initialSpoilers;
  final bool canDelete;
  final Future<void> Function() onDelete;

  const _WriteReviewSheet({
    required this.initialRating,
    required this.initialBody,
    required this.initialSpoilers,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late int rating;
  late bool spoilers;
  late TextEditingController bodyCtrl;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
    spoilers = widget.initialSpoilers;
    bodyCtrl = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tu review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          Row(
            children: List.generate(5, (i) {
              final v = i + 1;
              return IconButton(
                onPressed: () => setState(() => rating = v),
                icon: Icon(v <= rating ? Icons.star : Icons.star_border),
              );
            }),
          ),

          TextField(
            controller: bodyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: spoilers,
            onChanged: (v) => setState(() => spoilers = v),
            title: const Text('Contiene spoilers'),
            
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.canDelete)
                TextButton(
                  onPressed: () async => widget.onDelete(),
                  child: const Text('Eliminar'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    _ReviewDraft(
                      rating: rating,
                      body: bodyCtrl.text,
                      spoilers: spoilers,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

