import 'package:rin/data/repositories/profile_repository.dart';
import 'package:rin/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

ProfileService makeProfileService() {
  final sb = Supabase.instance.client;
  return ProfileService(repo: ProfileRepository(sb));
}
