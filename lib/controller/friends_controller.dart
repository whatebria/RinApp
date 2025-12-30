import 'package:flutter/foundation.dart';
import '../models/friend_list_item.dart';
import '../services/friend/friends_query_service.dart';

enum FriendsSort { name, newest }

class FriendsController extends ChangeNotifier {
  FriendsController({required FriendsQueryService query}) : _query = query;

  final FriendsQueryService _query;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  final List<FriendListItem> _allFriends = [];
  List<FriendListItem> get allFriends => List.unmodifiable(_allFriends);

  List<FriendListItem> _visibleFriends = [];
  List<FriendListItem> get visibleFriends => List.unmodifiable(_visibleFriends);

  FriendsSort _sort = FriendsSort.name;
  FriendsSort get sort => _sort;

  String _search = '';
  String get search => _search;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final friends = await _query.fetchFriendsList();
      _allFriends
        ..clear()
        ..addAll(friends);
      _applyFiltersInternal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String v) {
    _search = v;
    _applyFiltersInternal();
    notifyListeners();
  }

  void clearSearch() {
    _search = '';
    _applyFiltersInternal();
    notifyListeners();
  }

  void setSort(FriendsSort value) {
    _sort = value;
    _applyFiltersInternal();
    notifyListeners();
  }

  void _applyFiltersInternal() {
    final q = _search.trim().toLowerCase();

    var list = _allFriends.where((f) {
      if (q.isEmpty) return true;
      return f.titleText.toLowerCase().contains(q) ||
          f.friendCode.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case FriendsSort.name:
        list.sort(
          (a, b) => a.titleText
              .toLowerCase()
              .compareTo(b.titleText.toLowerCase()),
        );
        break;
      case FriendsSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _visibleFriends = list;
  }
}
