class UserProfile {
  UserProfile({
    required this.id,
    required this.displayName,
    required this.friendCode,
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

  final String id;
  final String displayName;
  final String friendCode;

  final String? avatarUrl;
  final String? pronouns;
  final DateTime? birthday; // date en DB
  final String? bio;

  final String? tiktokUsername;
  final String? instagramUsername;
  final String? goodreadsUsername;
  final String? youtubeUrl;
  final String? twitterUsername;
  final String? linkedinUrl;

  bool get isComplete => displayName.trim().isNotEmpty;

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString()); // 'YYYY-MM-DD'
    }

    return UserProfile(
      id: m['id'] as String,
      displayName: (m['display_name'] as String?) ?? '',
      friendCode: (m['friend_code'] as String?) ?? '',
      avatarUrl: m['avatar_url'] as String?,
      pronouns: m['pronouns'] as String?,
      birthday: parseDate(m['birthday']),
      bio: m['bio'] as String?,
      tiktokUsername: m['tiktok_username'] as String?,
      instagramUsername: m['instagram_username'] as String?,
      goodreadsUsername: m['goodreads_username'] as String?,
      youtubeUrl: m['youtube_url'] as String?,
      twitterUsername: m['twitter_username'] as String?,
      linkedinUrl: m['linkedin_url'] as String?,
    );
  }
}
