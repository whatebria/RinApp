import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/models/my_library_item.dart';

import '../controller/my_library_controller.dart';
import '../providers/my_library_provider.dart';
import 'shelf_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyLibraryScreen extends StatelessWidget {
  const MyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyLibraryProvider(child: _MyLibraryView());
  }
}

class _MyLibraryView extends StatelessWidget {
  const _MyLibraryView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MyLibraryController>();

    final loading = context.select<MyLibraryController, bool>((c) => c.loading);
    final error = context.select<MyLibraryController, String?>((c) => c.error);
    final hasLoaded = context.select<MyLibraryController, bool>(
      (c) => c.hasLoaded,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estanterías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : c.load,
          ),
        ],
      ),
      body: Builder(
        builder: (_) {
          if (!hasLoaded || loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = c.itemsByShelf.entries.toList(growable: false);


          // ✅ 2) Error
          if (error != null) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: c.load,
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            );
          }

          // ✅ 3) Vacío real (ya cargó y no hay shelves)
          if (entries.isEmpty) {
            return ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aún no tienes libros agregados.'),
                ),
              ],
            );
          }

          // ✅ 4) Contenido
          return RefreshIndicator(
            onRefresh: c.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final entry = entries[i];
                final shelfName = entry.key;
                final list = entry.value;

                return _ShelfSection(
                  shelfName: shelfName,
                  items: list,
                  onOpen: () {
                    final controller = context.read<MyLibraryController>();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: controller,
                          child: ShelfDetailScreen(shelfName: shelfName),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ShelfSection extends StatelessWidget {
  const _ShelfSection({
    required this.shelfName,
    required this.items,
    required this.onOpen,
  });

  final String shelfName;
  final List<MyLibraryItem> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = items.take(6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shelfName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CountChip(count: items.length),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onOpen,
                      child: const Text('Ver todo'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Preview horizontal
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: preview.length + 1, // +1 para chevron
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      if (i == preview.length) {
                        return _MoreCard(onTap: onOpen);
                      }
                      final x = preview[i];
                      return _CoverThumb(item: x);
                    },
                  ),
                ),

                // Mini hint (opcional)
                if (items.length > preview.length) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Mostrando ${preview.length} de ${items.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.item});

  final MyLibraryItem item;

  @override
  Widget build(BuildContext context) {
    final meta = item.cover;
    final url =
        (meta != null &&
            meta.isUsable &&
            meta.widthPx >= 100 &&
            meta.heightPx >= 150)
        ? meta.url
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 84,
        child: (url != null)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 112,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Icon(Icons.book_outlined, size: 22),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 56,
        height: 84,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
        ),
        child: const Icon(Icons.chevron_right),
      ),
    );
  }
}
