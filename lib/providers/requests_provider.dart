import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/requests_controller.dart';
import '../services/friend/friend_service.dart';
import '../services/profile_service.dart';

class RequestsProvider extends StatelessWidget {
  const RequestsProvider({
    super.key,
    required this.child,
    this.autoLoad = true,
  });

  final Widget child;
  final bool autoLoad;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RequestsController>(
      create: (_) {
        final c = RequestsController(
          friendService: FriendService(),
          profileService: ProfileService(),
        );
        if (autoLoad) c.load();
        return c;
      },
      child: child,
    );
  }
}
