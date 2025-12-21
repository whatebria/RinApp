class FriendListItem {
  FriendListItem({
    required this.friendId,
    required this.displayName,
    required this.friendCode,
    required this.createdAt,
  });

  final String friendId;
  final String displayName;
  final String friendCode;
  final DateTime createdAt;

  String get titleText {
    if (displayName.trim().isNotEmpty) return displayName.trim();
    if (friendCode.trim().isNotEmpty) return friendCode.trim();
    return "Amigo";
  }

  String get subtitleText {
    if (friendCode.trim().isNotEmpty) return "Código: ${friendCode.trim()}";
    return "ID: ${friendId.substring(0, 8)}...";
  }
}
