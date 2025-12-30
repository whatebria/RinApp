import 'package:flutter/foundation.dart';
import 'package:rin/models/user_profile.dart';
import '../services/friend/friend_service.dart';
import '../services/profile_service.dart';

class RequestsController extends ChangeNotifier {
  RequestsController({
    required FriendService friendService,
    required ProfileService profileService,
  })  : _friendService = friendService,
        _profileService = profileService;

  final FriendService _friendService;
  final ProfileService _profileService;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<FriendRequestItem> _requests = const [];
  List<FriendRequestItem> get requests => _requests;

  // Cache simple para mostrar algo amigable del from_user
  final Map<String, UserProfile> _profileCache = {};
  Map<String, UserProfile> get profileCache => _profileCache;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final reqs = await _friendService.listIncomingPending();
      _requests = reqs;

      // Cargar perfiles faltantes (secuencial para simpleza).
      // Si quieres optimizar: Future.wait + limitar concurrencia.
      for (final r in reqs) {
        if (!_profileCache.containsKey(r.fromUserId)) {
          final p = await _profileService.getByUserId(r.fromUserId);
          if (p != null) _profileCache[r.fromUserId] = p;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> accept(FriendRequestItem r) async {
    await _friendService.acceptRequest(
      requestId: r.id,
      fromUserId: r.fromUserId,
    );
    await load();
  }

  Future<void> reject(FriendRequestItem r) async {
    await _friendService.rejectRequest(requestId: r.id);
    await load();
  }

  UserProfile? profileFor(String userId) => _profileCache[userId];
}
