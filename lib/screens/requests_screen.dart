import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/requests_controller.dart';
import 'package:rin/providers/requests_provider.dart';
import 'package:rin/services/friend/friend_service.dart';


class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestsProvider(
      child: _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  String _titleFor(RequestsController c, FriendRequestItem r) {
    final p = c.profileFor(r.fromUserId);

    if (p == null) {
      final short = r.fromUserId.length >= 8 ? r.fromUserId.substring(0, 8) : r.fromUserId;
      return "Solicitud de usuario $short...";
    }

    if (p.displayName.isEmpty) return "Solicitud de ${p.friendCode}";
    return "Solicitud de ${p.displayName} (${p.friendCode})";
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RequestsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitudes"),
        actions: [
          IconButton(
            onPressed: c.load,
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Error: ${c.error}"),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: c.load,
                        child: const Text("Reintentar"),
                      ),
                    ],
                  )
                : c.requests.isEmpty
                    ? const Center(child: Text("No tienes solicitudes pendientes."))
                    : ListView.separated(
                        itemCount: c.requests.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final r = c.requests[i];

                          return ListTile(
                            title: Text(_titleFor(c, r)),
                            subtitle: Text("Recibida: ${r.createdAt.toLocal()}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await context.read<RequestsController>().reject(r);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("✅ Solicitud rechazada")),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("❌ Error al rechazar: $e")),
                                      );
                                    }
                                  },
                                  child: const Text("Rechazar"),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    try {
                                      await context.read<RequestsController>().accept(r);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("✅ Solicitud aceptada")),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("❌ Error al aceptar: $e")),
                                      );
                                    }
                                  },
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
