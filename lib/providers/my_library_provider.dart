import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/my_library_controller.dart';
import '../services/library_service.dart';
import '../data/repositories/library_repository.dart';

class MyLibraryProvider extends StatelessWidget {
  const MyLibraryProvider({
    super.key,
    required this.child,
    this.autoLoad = true,
  });

  final Widget child;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    final service = LibraryService(
      repo: LibraryRepository(sb),
    );

    return ChangeNotifierProvider<MyLibraryController>(
      create: (_) {
        final c = MyLibraryController(service: service);
        if (autoLoad) c.load();
        return c;
      },
      child: child,
    );
  }
}
