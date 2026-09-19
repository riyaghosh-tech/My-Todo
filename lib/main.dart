
import 'package:flutter/material.dart';

import 'home/home.dart';
import 'notify/notify.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF218C55);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5FAF6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5FAF6),
          foregroundColor: Color(0xFF174D32),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}