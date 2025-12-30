import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/profile_controller.dart';
import 'package:rin/models/profile_draft.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.controller});
  final ProfileController controller;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _pronouns;
  DateTime? _birthday;

  final _tiktokCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _goodreadsCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final p = widget.controller.profile;

    if (p != null) {
      _nameCtrl.text = p.displayName;
      _bioCtrl.text = p.bio ?? '';
      _pronouns = p.pronouns;
      _birthday = p.birthday;

      _tiktokCtrl.text = p.tiktokUsername ?? '';
      _instagramCtrl.text = p.instagramUsername ?? '';
      _goodreadsCtrl.text = p.goodreadsUsername ?? '';
      _youtubeCtrl.text = p.youtubeUrl ?? '';
      _twitterCtrl.text = p.twitterUsername ?? '';
      _linkedinCtrl.text = p.linkedinUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _tiktokCtrl.dispose();
    _instagramCtrl.dispose();
    _goodreadsCtrl.dispose();
    _youtubeCtrl.dispose();
    _twitterCtrl.dispose();
    _linkedinCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (picked != null) setState(() => _birthday = picked);
  }

  String _birthdayLabel() {
    if (_birthday == null) return 'Seleccionar fecha';
    final d = _birthday!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _save() async {
    final c = widget.controller;

    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = "El nombre no puede estar vacío.");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await c.save(
        ProfileDraft(
          displayName: name,
          pronouns: _pronouns,
          birthday: _birthday,
          bio: _bioCtrl.text,
          tiktokUsername: _tiktokCtrl.text,
          instagramUsername: _instagramCtrl.text,
          goodreadsUsername: _goodreadsCtrl.text,
          youtubeUrl: _youtubeCtrl.text,
          twitterUsername: _twitterCtrl.text,
          linkedinUrl: _linkedinCtrl.text,
        ),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pronounOptions = <String?>[
      null,
      'ella/she',
      'él/he',
      'elle/they',
      'prefiero no decir',
      'otro',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _pronouns,
            items: pronounOptions
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p ?? 'Sin pronombres'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _pronouns = v),
            decoration: const InputDecoration(
              labelText: 'Pronombres (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickBirthday,
            icon: const Icon(Icons.cake_outlined),
            label: Text('Cumpleaños (opcional): ${_birthdayLabel()}'),
          ),
          if (_birthday != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _birthday = null),
                child: const Text('Quitar cumpleaños'),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Redes (opcional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tiktokCtrl,
            decoration: const InputDecoration(
              labelText: 'TikTok (usuario, sin @)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instagramCtrl,
            decoration: const InputDecoration(
              labelText: 'Instagram (usuario, sin @)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goodreadsCtrl,
            decoration: const InputDecoration(labelText: 'Goodreads (usuario)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _youtubeCtrl,
            decoration: const InputDecoration(labelText: 'YouTube (URL)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _twitterCtrl,
            decoration: const InputDecoration(
              labelText: 'Twitter/X (usuario, sin @)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkedinCtrl,
            decoration: const InputDecoration(labelText: 'LinkedIn (URL)'),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
