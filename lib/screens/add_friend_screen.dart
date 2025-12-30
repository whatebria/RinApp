import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/add_friend_controller.dart';

import '../services/profile_service.dart';
import '../services/friend/friend_service.dart';

class AddFriendScreen extends StatelessWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddFriendController(
        profileService: ProfileService(),
        friendService: FriendService(),
      ),
      child: const _AddFriendView(),
    );
  }
}

class _AddFriendView extends StatefulWidget {
  const _AddFriendView();

  @override
  State<_AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<_AddFriendView> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final c = context.read<AddFriendController>();
    await c.send(friendCode: _codeCtrl.text);

    // opcional: ocultar teclado
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AddFriendController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Agregar amigo")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Pega el código del otro usuario (friend_code):"),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Ej: ABC-7K2Q",
              ),
              onSubmitted: (_) => c.loading ? null : _send(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: c.loading ? null : _send,
              child: Text(c.loading ? "Enviando..." : "Enviar solicitud"),
            ),
            if (c.status != null) ...[
              const SizedBox(height: 12),
              Text(c.status!),
            ],
          ],
        ),
      ),
    );
  }
}
