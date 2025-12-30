import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:rin/controller/profile_controller.dart';
import 'package:rin/screens/profile/edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileController>();
    final p = c.profile;
    final pc = context.read<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: ListView(
        children: [
          // --- header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (p?.displayName.trim().isNotEmpty ?? false) ? p!.displayName : 'Sin nombre',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p?.friendCode.isNotEmpty == true ? 'Código: ${p!.friendCode}' : 'Código: —',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar código',
                  onPressed: (p?.friendCode.isNotEmpty == true)
                      ? () async {
                          await Clipboard.setData(ClipboardData(text: p!.friendCode));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Código copiado')),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
          const Divider(),

          // --- opciones ---
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar perfil'),
            subtitle: const Text('Nombre, bio, redes, etc.'),
            onTap: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(controller: pc)),
              );

              // refresca si guardó (por si la pantalla anterior no se actualiza)
              if (saved == true && context.mounted) {
                await context.read<ProfileController>().ensureAndLoad();
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Ver mi perfil'),
            subtitle: const Text('Vista pública (opcional)'),
            onTap: () {
              // Más adelante: ProfileScreen público (solo lectura)
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              // OJO: tu app usa Supabase.initialize + AuthGate, esto funciona bien.
              // Si usas EmptyLocalStorage igual cerrará sesión actual.
              await context.read<ProfileController>().service.repo.sb.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
