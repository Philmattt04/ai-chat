import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const AIChatApp());
}

class AIChatApp extends StatefulWidget {
  const AIChatApp({super.key});

  @override
  State<AIChatApp> createState() => _AIChatAppState();
}

class _AIChatAppState extends State<AIChatApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() => setState(() {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.interTextTheme();

    return MaterialApp(
      title: 'AI Chat — Philippe Mathieu',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: base,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: base.apply(
          bodyColor: const Color(0xFFe5e7eb),
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0f0f0f),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f0f0f),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: ChatScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}
