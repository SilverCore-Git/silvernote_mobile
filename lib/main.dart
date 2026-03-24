import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'config/app_theme.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId('group.silvernote');
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