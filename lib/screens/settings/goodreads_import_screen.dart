import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/goodreads_import_controller.dart';
import 'package:rin/providers/goodreads_import_provider.dart';
import 'package:rin/screens/widgets/update_catalog_button.dart';


class GoodreadsImportScreen extends StatelessWidget {
  const GoodreadsImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoodreadsImportProvider(
      child: _GoodreadsImportView(),
    );
  }
}

class _GoodreadsImportView extends StatelessWidget {
  const _GoodreadsImportView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GoodreadsImportController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar Goodreads CSV"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              try {
                await context.read<GoodreadsImportController>().signOut();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Error al cerrar sesión: $e")),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FilledButton.icon(
              onPressed: c.loading ? null : () => c.pickAndAutoLoad(),
              icon: const Icon(Icons.upload_file),
              label: Text(c.loading ? "Cargando..." : "Elegir CSV"),
            ),
            const SizedBox(height: 12),
            const UpdateCatalogButton(),
            const SizedBox(height: 12),

            if (c.error != null) ...[
              const SizedBox(height: 12),
              Text(
                c.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: c.requestManualDelimiter,
                child: const Text("Elegir separador manualmente"),
              ),
            ],

            if (c.showManualDelimiter && c.file != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Separador manual: "),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: c.delimiter,
                    items: const [
                      DropdownMenuItem(value: ",", child: Text(",")),
                      DropdownMenuItem(value: ";", child: Text(";")),
                      DropdownMenuItem(value: "\t", child: Text("TAB")),
                    ],
                    onChanged:
                        c.loading ? null : (v) => c.reparseWithManualDelimiter(v),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 6),

            if (c.hasPreview) ...[
              Text("Libros OK: ${c.payload.length}"),
              Text("Errores: ${c.importedErrors.length}"),
              if (c.importedErrors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text("Primeros errores:"),
                ...c.importedErrors
                    .take(5)
                    .map((e) => Text("Fila ${e.rowNumber}: ${e.message}")),
              ],
            ],

            const SizedBox(height: 16),

            if (c.hasImported) ...[
              const Text(
                "Preview (primeros libros)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _previewList(c),
            ],

            const SizedBox(height: 16),

            FilledButton(
              onPressed: (c.saving || c.payload.isEmpty)
                  ? null
                  : () async {
                      try {
                        final ok = await context
                            .read<GoodreadsImportController>()
                            .saveImported();
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Importado en Supabase"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("❌ Error al importar: $e")),
                        );
                      }
                    },
              child: Text(c.saving ? "Importando..." : "Importar libros"),
            ),

            const SizedBox(height: 24),

            if (c.file != null) ...[
              OutlinedButton(
                onPressed: c.loading ? null : c.resetAll,
                child: const Text("Limpiar"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewList(GoodreadsImportController c) {
    final first = c.payload.take(20).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: first.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = first[i];
        final title = (item['title'] ?? '').toString();
        final authors = (item['authors'] as List?)?.join(', ') ?? '';
        final shelf = (item['exclusive_shelf'] ?? '').toString();

        return ListTile(
          leading: const Icon(Icons.book_outlined),
          title: Text(title),
          subtitle: Text(authors.isEmpty ? shelf : "$authors • $shelf"),
        );
      },
    );
  }
}
