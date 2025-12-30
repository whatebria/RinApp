import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/goodreads_import_controller.dart';
import '../services/auth_service.dart';
import '../services/csv_reader.dart';
import '../services/goodreads_repository.dart';
import '../services/goodreads_importer.dart';

class GoodreadsImportProvider extends StatelessWidget {
  const GoodreadsImportProvider({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GoodreadsImportController>(
      create: (_) => GoodreadsImportController(
        csvReader: CsvReaderService(),
        auth: AuthService(),
        repo: GoodreadsRepository(),
        importer: GoodreadsImporter(),
      ),
      child: child,
    );
  }
}
