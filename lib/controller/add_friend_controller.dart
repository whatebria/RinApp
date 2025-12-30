import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import '../services/friend/friend_service.dart';

class AddFriendController extends ChangeNotifier {
  AddFriendController({
    required ProfileService profileService,
    required FriendService friendService,
  })  : _profileService = profileService,
        _friendService = friendService;

  final ProfileService _profileService;
  final FriendService _friendService;

  bool _loading = false;
  String? _status;

  bool get loading => _loading;
  String? get status => _status;

  Future<void> send({required String friendCode}) async {
    final code = friendCode.trim();

    if (code.isEmpty) {
      _status = "Pega un código";
      notifyListeners();
      return;
    }

    _loading = true;
    _status = null;
    notifyListeners();

    try {
      // 1) Convertir friend_code -> user_id
      final profile = await _profileService.findByFriendCode(code);

      if (profile == null) {
        _status = "No existe un usuario con ese código";
        return;
      }

      // 2) Crear friend_request
      await _friendService.sendRequest(toUserId: profile.id);

      final display = (profile.displayName).trim().isEmpty
          ? profile.friendCode
          : profile.displayName;

      _status = "✅ Solicitud enviada a $display";
    } catch (e) {
      // Ideal: mapear errores a mensajes de dominio
      _status = "❌ Error al enviar solicitud";
      if (kDebugMode) {
        _status = "❌ Error: $e";
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _status = null;
    notifyListeners();
  }
}
