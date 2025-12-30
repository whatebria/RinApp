import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/profile_draft.dart';
import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService service;
  ProfileController({required this.service});

  bool loading = false;
  String? error;

  UserProfile? profile;

  Future<void> ensureAndLoad() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await service.ensureMyProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(ProfileDraft draft) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await service.saveMyProfile(draft);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
