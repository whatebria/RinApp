import 'package:rin/models/user_profile.dart';

class ProfileDraft {
  String displayName;
  String? avatarUrl;
  String? pronouns;
  DateTime? birthday;
  String? bio;

  String? tiktokUsername;
  String? instagramUsername;
  String? goodreadsUsername;
  String? youtubeUrl;
  String? twitterUsername;
  String? linkedinUrl;

  ProfileDraft({
    this.displayName = '',
    this.avatarUrl,
    this.pronouns,
    this.birthday,
    this.bio,
    this.tiktokUsername,
    this.instagramUsername,
    this.goodreadsUsername,
    this.youtubeUrl,
    this.twitterUsername,
    this.linkedinUrl,
  });

  static String? _cleanHandle(String? s) {
    if (s == null) return null;
    final v = s.trim();
    if (v.isEmpty) return null;
    return v.startsWith('@') ? v.substring(1) : v;
  }

  Map<String, dynamic> toUpdateMap() {
    String? dateToPg(DateTime? d) {
      if (d == null) return null;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    return {
      'display_name': displayName.trim(),
      'avatar_url': avatarUrl,
      'pronouns': pronouns?.trim().isEmpty == true ? null : pronouns?.trim(),
      'birthday': dateToPg(birthday),
      'bio': bio?.trim().isEmpty == true ? null : bio?.trim(),

      'tiktok_username': _cleanHandle(tiktokUsername),
      'instagram_username': _cleanHandle(instagramUsername),
      'goodreads_username': _cleanHandle(goodreadsUsername),
      'youtube_url': youtubeUrl?.trim().isEmpty == true ? null : youtubeUrl?.trim(),
      'twitter_username': _cleanHandle(twitterUsername),
      'linkedin_url': linkedinUrl?.trim().isEmpty == true ? null : linkedinUrl?.trim(),

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory ProfileDraft.fromProfile(UserProfile p) {
    return ProfileDraft(
      displayName: p.displayName,
      avatarUrl: p.avatarUrl,
      pronouns: p.pronouns,
      birthday: p.birthday,
      bio: p.bio,
      tiktokUsername: p.tiktokUsername,
      instagramUsername: p.instagramUsername,
      goodreadsUsername: p.goodreadsUsername,
      youtubeUrl: p.youtubeUrl,
      twitterUsername: p.twitterUsername,
      linkedinUrl: p.linkedinUrl,
    );
  }
}
