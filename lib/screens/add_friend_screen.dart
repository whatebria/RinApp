import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/friend/friend_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _codeCtrl = TextEditingController();
  final _profileService = ProfileService();
  final _friendService = FriendService();

  bool _loading = false;
  String? _status;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _status = "Pega un código");
      return;
    }

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      // 1) Convertir friend_code -> user_id
      final profile = await _profileService.findByFriendCode(code);
      if (profile == null) {
        setState(() => _status = "No existe un usuario con ese código");
        return;
      }

      // 2) Crear friend_request
      await _friendService.sendRequest(toUserId: profile.id);

      setState(() => _status = "✅ Solicitud enviada a ${profile.displayName.isEmpty ? profile.friendCode : profile.displayName}");
    } catch (e) {
      setState(() => _status = "❌ Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _send,
              child: Text(_loading ? "Enviando..." : "Enviar solicitud"),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!),
            ]
          ],
        ),
      ),
    );
  }
}
