import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room 5 Share',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Emerald green
          secondary: Color(0xFFD97706), // Amber
          background: Color(0xFF0F172A), // Slate 900
          surface: Color(0xFF1E293B), // Slate 800
          error: Colors.redAccent,
        ),
        fontFamily: 'Roboto', // Modern standard system font
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
