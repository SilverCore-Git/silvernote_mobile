import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

const String clerkPublishableKey = '';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilverNoteApp());
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: clerkPublishableKey,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const AuthScaffold(),
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, _) {
          final inset = MediaQuery.of(context).viewInsets.bottom;
          const maxShift = 105.0;
          final shift = inset.clamp(0.0, maxShift);
          return Stack(
            children: [
              Container(height: topPadding, color: const Color(0xFFF28C28)),
              Center(
                child: AnimatedPadding(
                  padding: EdgeInsets.only(bottom: shift),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: ClerkErrorListener(
                    child: ClerkAuthBuilder(
                      signedInBuilder: (context, auth) {
                        return const SignedInHome();
                      },
                      signedOutBuilder: (context, authState) {
                        return const ClerkAuthentication();
                      },
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

class SignedInHome extends StatelessWidget {
  const SignedInHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user, size: 64),
        SizedBox(height: 16),
        Text('Connecté avec Clerk'),
      ],
    );
  }
}
