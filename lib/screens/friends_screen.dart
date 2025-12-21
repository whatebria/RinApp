import 'package:flutter/material.dart';
import 'package:rin/screens/add_friend_screen.dart';
import 'package:rin/screens/my_code_screen.dart';
import 'package:rin/screens/requests_screen.dart';
import '../models/friend_list_item.dart';
import '../services/friend/friends_query_service.dart';

enum FriendsSort {
  name,
  newest,
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _query = FriendsQueryService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<FriendListItem> _allFriends = [];
  List<FriendListItem> _visibleFriends = [];

  FriendsSort _sort = FriendsSort.name;

  @override
  void initState() {
    super.initState();
    _load();

    // Cada vez que cambia el texto de búsqueda, re-filtramos
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilters);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final friends = await _query.fetchFriendsList();

      if (!mounted) return;
      setState(() {
        _allFriends = friends;
      });

      _applyFilters(); // aplica search + orden al resultado recién cargado
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    // 1) filtrar
    var list = _allFriends.where((f) {
      if (q.isEmpty) return true;
      return f.titleText.toLowerCase().contains(q) ||
          f.friendCode.toLowerCase().contains(q);
    }).toList();

    // 2) ordenar
    switch (_sort) {
      case FriendsSort.name:
        list.sort((a, b) => a.titleText.toLowerCase().compareTo(b.titleText.toLowerCase()));
        break;
      case FriendsSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    // 3) actualizar lo visible
    setState(() {
      _visibleFriends = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Amigos"),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCodeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inbox),
            tooltip: "Solicitudes",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestsScreen()),
              );
            },
          ),
          PopupMenuButton<FriendsSort>(
            initialValue: _sort,
            onSelected: (value) {
              setState(() => _sort = value);
              _applyFilters();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FriendsSort.name,
                child: Text("Ordenar por nombre"),
              ),
              PopupMenuItem(
                value: FriendsSort.newest,
                child: Text("Ordenar por más recientes"),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorState()
                : Column(
                    children: [
                      _searchBar(),
                      const SizedBox(height: 12),
                      Expanded(child: _friendsList()),
                    ],
                  ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        labelText: "Buscar amigo",
        hintText: "Nombre o código",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  // listener llama _applyFilters()
                },
              ),
      ),
    );
  }

  Widget _friendsList() {
    if (_visibleFriends.isEmpty) {
      if (_allFriends.isEmpty) {
        return const Center(child: Text("Aún no tienes amigos."));
      }
      return const Center(child: Text("No hay resultados para tu búsqueda."));
    }

    return ListView.separated(
      itemCount: _visibleFriends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = _visibleFriends[i];

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(f.titleText),
          subtitle: Text(f.subtitleText),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Próximo paso: navegar a compare o ver eventos del amigo
          },
        );
      },
    );
  }

  Widget _errorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Error: $_error"),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _load,
          child: const Text("Reintentar"),
        ),
      ],
    );
  }
}
