import 'package:flutter/material.dart';
import 'home/home.dart';
import 'notify/notify.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF218C55),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5FAF6),
      ),
      home: const HomeScreen(),
    );
  }
}