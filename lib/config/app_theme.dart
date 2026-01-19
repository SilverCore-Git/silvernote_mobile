import 'package:flutter/material.dart';

@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.bottomBarColor,
  });

  final Color? bottomBarColor;

  @override
  AppCustomColors copyWith({Color? bottomBarColor}) {
    return AppCustomColors(
      bottomBarColor: bottomBarColor ?? this.bottomBarColor,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) {
      return this;
    }
    return AppCustomColors(
      bottomBarColor: Color.lerp(bottomBarColor, other.bottomBarColor, t),
    );
  }
}

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFF28C28),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFFFF8F0),
  extensions: const <ThemeExtension<dynamic>>[
    AppCustomColors(
      bottomBarColor: Color(0xFFFFF3E0),
    ),
  ],
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFF28C28),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  extensions: const <ThemeExtension<dynamic>>[
    AppCustomColors(
      bottomBarColor: Color(0xFF1E1E1E),
    ),
  ],
);
