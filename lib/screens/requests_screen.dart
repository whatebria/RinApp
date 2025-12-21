import 'package:flutter/material.dart';
import '../services/friend/friend_service.dart';
import '../services/profile_service.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _friendService = FriendService();
  final _profileService = ProfileService();

  bool _loading = true;
  String? _error;

  List<FriendRequestItem> _requests = [];

  // Cache simple para mostrar algo amigable del "from_user"
  final Map<String, UserProfile> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reqs = await _friendService.listIncomingPending();

      // opcional: cargar perfiles de quienes enviaron solicitud
      for (final r in reqs) {
        if (!_profileCache.containsKey(r.fromUserId)) {
          final p = await _profileService.getByUserId(r.fromUserId);
          if (p != null) _profileCache[r.fromUserId] = p;
        }
      }

      if (!mounted) return;
      setState(() => _requests = reqs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(FriendRequestItem r) async {
    try {
      await _friendService.acceptRequest(
        requestId: r.id,
        fromUserId: r.fromUserId,
      );
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Solicitud aceptada")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al aceptar: $e")),
      );
    }
  }

  Future<void> _reject(FriendRequestItem r) async {
    try {
      await _friendService.rejectRequest(requestId: r.id);
      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Solicitud rechazada")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al rechazar: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Error: $_error"),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text("Reintentar"),
                      ),
                    ],
                  )
                : _requests.isEmpty
                    ? const Center(child: Text("No tienes solicitudes pendientes."))
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final r = _requests[i];
                          final p = _profileCache[r.fromUserId];

                          final title = p == null
                              ? "Solicitud de usuario ${r.fromUserId.substring(0, 8)}..."
                              : (p.displayName.isEmpty
                                  ? "Solicitud de ${p.friendCode}"
                                  : "Solicitud de ${p.displayName} (${p.friendCode})");

                          return ListTile(
                            title: Text(title),
                            subtitle: Text("Recibida: ${r.createdAt.toLocal()}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _reject(r),
                                  child: const Text("Rechazar"),
                                ),
                                FilledButton(
                                  onPressed: () => _accept(r),
                                  child: const Text("Aceptar"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
