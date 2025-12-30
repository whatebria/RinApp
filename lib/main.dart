import 'package:flutter/material.dart';
import 'package:rin/providers/profile_provider.dart';
import 'package:rin/screens/widgets/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ivqpjhhmqepuplaqkjkz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2cXBqaGhtcWVwdXBsYXFramt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyODAwODIsImV4cCI6MjA4MTg1NjA4Mn0.tfMRJdvedxJ8uONyZ3xqXRsfVHPq312sOSa8i_LiDdE',
    authOptions: FlutterAuthClientOptions(
    ),
  );


  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CSV DEMO',
      theme: ThemeData(
        useMaterial3: true
      ),
      home: ProfileProvider( // ✅ provider arriba del AuthGate
        child: const AuthGate(),
      ),
    );
  }
}


