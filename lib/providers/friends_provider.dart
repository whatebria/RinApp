import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/friends_controller.dart';
import '../services/friend/friends_query_service.dart';

class FriendsProvider extends StatelessWidget {
  const FriendsProvider({
    super.key,
    required this.child,
    this.autoLoad = true,
  });

  final Widget child;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FriendsController>(
      create: (_) {
        final c = FriendsController(query: FriendsQueryService());
        if (autoLoad) c.load();
        return c;
      },
      child: child,
    );
  }
}
