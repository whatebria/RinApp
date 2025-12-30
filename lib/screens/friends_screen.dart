import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/screens/add_friend_screen.dart';
import 'package:rin/screens/my_code_screen.dart';
import 'package:rin/screens/requests_screen.dart';

import '../controller/friends_controller.dart';
import '../providers/friends_provider.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FriendsProvider(
      child: _FriendsView(),
    );
  }
}

class _FriendsView extends StatefulWidget {
  const _FriendsView();

  @override
  State<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<_FriendsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _syncTextIfNeeded(FriendsController c) {
    // Mantener el TextField consistente si el controller cambia (ej: clearSearch)
    if (_searchCtrl.text != c.search) {
      _searchCtrl.value = _searchCtrl.value.copyWith(
        text: c.search,
        selection: TextSelection.collapsed(offset: c.search.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FriendsController>();
    _syncTextIfNeeded(c);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Amigos"),
        actions: [
          IconButton(
            onPressed: c.loading ? null : c.load,
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
            initialValue: c.sort,
            onSelected: c.setSort,
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
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
                ? _errorState(context, c.error!, c.load)
                : Column(
                    children: [
                      _searchBar(c),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _friendsList(
                          visible: c.visibleFriends,
                          allCount: c.allFriends.length,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _searchBar(FriendsController c) {
    return TextField(
      controller: _searchCtrl,
      onChanged: c.setSearch,
      decoration: InputDecoration(
        labelText: "Buscar amigo",
        hintText: "Nombre o código",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: c.search.trim().isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  c.clearSearch();
                  FocusScope.of(context).unfocus();
                },
              ),
      ),
    );
  }

  Widget _friendsList({
    required List visible,
    required int allCount,
  }) {
    if (visible.isEmpty) {
      if (allCount == 0) {
        return const Center(child: Text("Aún no tienes amigos."));
      }
      return const Center(child: Text("No hay resultados para tu búsqueda."));
    }

    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final f = visible[i];

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

  Widget _errorState(
    BuildContext context,
    String error,
    VoidCallback retry,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Error: $error"),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: retry,
          child: const Text("Reintentar"),
        ),
      ],
    );
  }
}
