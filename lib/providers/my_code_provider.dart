import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/utils/lib/di.dart';

import '../controller/my_code_controller.dart';
import '../services/profile_service.dart';

class MyCodeProvider extends StatelessWidget {
  const MyCodeProvider({
    super.key,
    required this.child,
    this.autoLoad = true,
  });

  final Widget child;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyCodeController>(
      create: (_) {
        final c = MyCodeController(
          profileService: makeProfileService(),
        );
        if (autoLoad) c.load();
        return c;
      },
      child: child,
    );
  }
}
