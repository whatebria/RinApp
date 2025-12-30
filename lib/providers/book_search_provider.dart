import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/book_search_controller.dart';
import '../services/book_service.dart';
import '../data/datasources/book_remote_datasource.dart';
import '../data/repositories/library_repository.dart';

class BookSearchProvider extends StatelessWidget {
  const BookSearchProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    final service = BookService(
      remote: BookRemoteDatasource(sb),
      library: LibraryRepository(sb),
    );

    return ChangeNotifierProvider<BookSearchController>(
      create: (_) => BookSearchController(service: service),
      child: child,
    );
  }
}
