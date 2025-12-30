import 'package:flutter/material.dart';

class _ReviewsHeader extends StatelessWidget {
  final double avg;
  final int count;
  final int? myRating;
  final VoidCallback onTapWrite;

  const _ReviewsHeader({
    required this.avg,
    required this.count,
    required this.onTapWrite,
    this.myRating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text("⭐ ${avg.toStringAsFixed(2)} ($count)", style: const TextStyle(fontSize: 16)),
            const Spacer(),
            FilledButton(
              onPressed: onTapWrite,
              child: Text(myRating == null ? "Escribir review" : "Editar mi review (${myRating}⭐)"),
            ),
          ],
        ),
      ),
    );
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
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text("$rating⭐"),
              ],
            ),
            const SizedBox(height: 6),
            if (spoilers)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.orange.withOpacity(0.2),
                ),
                child: const Text("Spoiler", style: TextStyle(fontSize: 12)),
              ),
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
    rating = widget.initialRating; // ya viene con default 5 en el caller
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tu review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
              labelText: "Comentario (opcional)",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: spoilers,
            onChanged: (v) => setState(() => spoilers = v),
            title: const Text("Contiene spoilers"),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.canDelete)
                TextButton(
                  onPressed: () async => widget.onDelete(),
                  child: const Text("Eliminar"),
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
                child: const Text("Guardar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
