import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'pages/main_page_android.dart';
import 'pages/main_page_windows.dart';

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
      home: _buildHomePage(),
    );
  }

  Widget _buildHomePage() {
    if (kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('Web non supporté pour le moment'),
        ),
      );
    }

    if (Platform.isWindows) {
      return const MainPageWindows();
    } else if (Platform.isAndroid) {
      return const MainPage();
    } else {
      return Scaffold(
        body: Center(
          child: Text('Plateforme ${Platform.operatingSystem} non supportée'),
        ),
      );
    }
  }
}