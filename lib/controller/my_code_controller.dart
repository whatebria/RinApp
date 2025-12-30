import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class MyCodeController extends ChangeNotifier {
  MyCodeController({required ProfileService profileService})
      : _profileService = profileService;

  final ProfileService _profileService;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.ensureMyProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
