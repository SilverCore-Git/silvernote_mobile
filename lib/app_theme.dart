import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: const Color(0xFFF28C28),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF28C28)),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2A2420),
  primaryColor: const Color(0xFFF28C28),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF28C28)),
);

class CustomColors {
  final Color noteCardColor;
  final Color textColor;
  CustomColors({required this.noteCardColor, required this.textColor});
}

final customColorsLight = CustomColors(
  noteCardColor: const Color(0xFFFFF5E8),
  textColor: const Color(0xFF222222),
);

final customColorsDark = CustomColors(
  noteCardColor: const Color(0xFF3A322D),
  textColor: const Color(0xFFEAE0D7),
);

extension CustomThemeExtension on ThemeData {
  CustomColors get customColors =>
      brightness == Brightness.dark ? customColorsDark : customColorsLight;
}

class ThemeController extends ChangeNotifier {
  bool _isDark = false;

  ThemeData get theme => _isDark ? darkTheme : lightTheme;

  bool get isDark => _isDark;

  void toggleTheme(bool isDark) {
    _isDark = isDark;
    notifyListeners();
  }
}

final themeController = ThemeController();
const border = Color(0xFF2F2F2F);
const textDark = Color(0xFF2A2A2A);
const hint = Color(0xFF7F7F7F);