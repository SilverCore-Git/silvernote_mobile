import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import 'app_theme.dart';
import 'home_page.dart';

const appUrl = 'https://test-clerk.dev.silvernote.fr/';
const String clerkPublishableKey =
    String.fromEnvironment('PUBLISHABLE_KEY', defaultValue: '');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ClerkAuth(
      config: ClerkAuthConfig(publishableKey: clerkPublishableKey),
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeController.theme,
            home: const SilverNoteApp(),
          );
        },
      ),
    ),
  );
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, _) {
          final inset = MediaQuery.of(context).viewInsets.bottom;
          final maxShift = 105.0;
          final shift = inset.clamp(0.0, maxShift);

          return Stack(
            children: [
              Container(
                height: topPadding,
                color: Theme.of(context).primaryColor,
              ),
              Center(
                child: AnimatedPadding(
                  padding: EdgeInsets.only(bottom: shift),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: ClerkErrorListener(
                    child: ClerkAuthBuilder(
                      signedInBuilder: (context, auth) {
                        final user = auth.user;
                        final userId = user?.id;
                        return HomePage(userId: userId);
                      },
                      signedOutBuilder: (context, authState) =>
                          const ClerkAuthentication(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
