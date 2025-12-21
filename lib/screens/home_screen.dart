import 'package:flutter/material.dart';
import 'package:rin/screens/book_search_screen.dart';
import 'package:rin/screens/friends_screen.dart';
import 'package:rin/screens/my_library_screen.dart';

import 'goodreads_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _pages = const [
    MyLibraryScreen(),
    BookSearchScreen(),
    FriendsScreen(), 
    GoodreadsImportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Mi libreria',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Buscar libros',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            label: 'Importar',
          ),
        ],
      ),
    );
  }
}
