import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/profile_controller.dart';
import 'package:rin/models/profile_draft.dart';
import 'package:rin/screens/widgets/auth_gate.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _pronouns; // opcional
  DateTime? _birthday; // opcional

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
    // precarga si ya existe
    final p = context.read<ProfileController>().profile;
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

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
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
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _save() async {
    final c = context.read<ProfileController>();
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      setState(
        () => _error = "El nombre no puede estar vacío si quieres guardar.",
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final draft = ProfileDraft(
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
      );

      await c.save(draft);

      if (!mounted) return;
      _goHome();
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

    String birthdayLabel() {
      if (_birthday == null) return 'Seleccionar fecha';
      final d = _birthday!;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configura tu perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _goHome,
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Básico ---
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Cómo quieres que te vean',
              ),
            ),
            const SizedBox(height: 12),

            // --- Opcional ---
            DropdownButtonFormField<String?>(
              initialValue: _pronouns,
              items: pronounOptions
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p ?? 'Pronombres (opcional)'),
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
              label: Text('Cumpleaños (opcional): ${birthdayLabel()}'),
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
                hintText: 'Un mini bio…',
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
              decoration: const InputDecoration(
                labelText: 'Goodreads (usuario)',
              ),
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes omitir esto y editarlo después.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
