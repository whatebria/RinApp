import '../../models/friend_list_item.dart';
import 'friend_service.dart';
import '../profile_service.dart';

class FriendsQueryService {
  FriendsQueryService({
    FriendService? friendService,
    ProfileService? profileService,
  })  : _friendService = friendService ?? FriendService(),
        _profileService = profileService ?? ProfileService();

  final FriendService _friendService;
  final ProfileService _profileService;

  Future<List<FriendListItem>> fetchFriendsList() async {
    // 1) Trae amistades (solo IDs + fecha)
    final friends = await _friendService.listFriends();

    // 2) Junta IDs para pedir perfiles en batch
    final ids = friends.map((f) => f.friendUserId).toList();
    final profilesById = await _profileService.getByUserIds(ids);

    // 3) Mezcla -> modelo listo para UI
    final result = friends.map((f) {
      final p = profilesById[f.friendUserId];

      final displayName = p?.displayName ?? '';
      final friendCode = p?.friendCode ?? '';

      return FriendListItem(
        friendId: f.friendUserId,
        displayName: displayName,
        friendCode: friendCode,
        createdAt: f.createdAt,
      );
    }).toList();

    // 4) Orden por defecto (por nombre o por fecha, tú eliges)
    result.sort((a, b) => a.titleText.toLowerCase().compareTo(b.titleText.toLowerCase()));
    return result;
  }
}
