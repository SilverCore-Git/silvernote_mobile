import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'pages/main_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilverNoteApp());
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const MainPage(),
    );
  }
}
