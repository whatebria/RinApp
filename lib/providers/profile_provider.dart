import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controller/profile_controller.dart';
import '../services/profile_service.dart';
import '../data/repositories/profile_repository.dart';

class ProfileProvider extends StatelessWidget {
  const ProfileProvider({super.key, required this.child, this.autoEnsure = false});
  final Widget child;
  final bool autoEnsure;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    final repo = ProfileRepository(sb);
    final service = ProfileService(repo: repo);

    return ChangeNotifierProvider(
      create: (_) {
        final c = ProfileController(service: service);
        if (autoEnsure) c.ensureAndLoad();
        return c;
      },
      child: child,
    );
  }
}
