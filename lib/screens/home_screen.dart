import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rin/controller/profile_controller.dart';
import 'package:rin/screens/book_search_screen.dart';
import 'package:rin/screens/friends_screen.dart';
import 'package:rin/screens/my_library_screen.dart';
import 'package:rin/screens/profile/edit_profile_screen.dart';
import 'package:rin/screens/settings/settings_screen.dart';
import 'goodreads_import_screen.dart';
import 'profile/profile_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = [
    MyLibraryScreen(),
    BookSearchScreen(),
    FriendsScreen(),
    GoodreadsImportScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.list_alt), label: 'Mi libreria'),
    NavigationDestination(icon: Icon(Icons.search), label: 'Buscar libros'),
    NavigationDestination(icon: Icon(Icons.people), label: 'Social'),
    NavigationDestination(icon: Icon(Icons.upload_file), label: 'Importar'),
    NavigationDestination(icon: Icon(Icons.person), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileController>();
    final showBanner = (c.profile != null && !c.profile!.isComplete);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (showBanner) _CompleteProfileBanner(
              onComplete: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileSetupScreen())
                );
              },
              onDismiss: () {
                // simple: solo lo ocultas esta sesión
                // si quieres persistir, luego lo guardas con SharedPreferences
                // aquí basta con setState local + bool, pero lo mantengo simple:
                // (alternativa: hacer un flag local en HomeState)
              },
            ),
            Expanded(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}

class _CompleteProfileBanner extends StatelessWidget {
  const _CompleteProfileBanner({
    required this.onComplete,
    required this.onDismiss,
  });

  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.person_outline),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Completa tu perfil (opcional) para que tus amigos te reconozcan.',
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onComplete,
                child: const Text('Completar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
