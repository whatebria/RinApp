import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/my_library_controller.dart';
import 'package:rin/data/repositories/library_repository.dart';
import 'package:rin/services/library_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyLibraryProvider extends StatelessWidget {
  const MyLibraryProvider({
    super.key,
    required this.child,
    this.autoLoad = true,
  }) : controller = null;

  const MyLibraryProvider.value({
    super.key,
    required this.child,
    required this.controller,
  }) : autoLoad = false;

  final Widget child;
  final bool autoLoad;
  final MyLibraryController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ChangeNotifierProvider.value(
        value: controller!,
        child: child,
      );
    }

    final sb = Supabase.instance.client;
    final service = LibraryService(repo: LibraryRepository(sb));

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
