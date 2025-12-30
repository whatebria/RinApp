import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/book_detail_controller.dart';
import '../services/library_service.dart';
import '../services/review_service.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/review_repository.dart';

class BookDetailProvider extends StatelessWidget {
  const BookDetailProvider({
    super.key,
    required this.catalogBookId,
    required this.child,
    this.autoLoad = true,
  });

  final String catalogBookId;
  final Widget child;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    final libraryService = LibraryService(repo: LibraryRepository(sb));
    final reviewService = ReviewService(repo: ReviewRepository(sb));

    return ChangeNotifierProvider<BookDetailController>(
      create: (_) {
        final c = BookDetailController(
          service: libraryService,
          reviewService: reviewService,
          catalogBookId: catalogBookId,
        );
        if (autoLoad) c.load();
        return c;
      },
      child: child,
    );
  }
}
