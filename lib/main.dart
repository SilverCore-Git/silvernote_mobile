import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:webview_cookie_manager_flutter/webview_cookie_manager.dart';

const appUrl = 'https://test-clerk.dev.silvernote.fr/';
const String clerkPublishableKey = 'KEY_HERE';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SilverNoteApp());
}

class SilverNoteApp extends StatelessWidget {
  const SilverNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: clerkPublishableKey),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, _) {
              final inset = MediaQuery.of(context).viewInsets.bottom;
              final maxShift = 105.0;
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
                  child: ClerkErrorListener(
                    child: ClerkAuthBuilder(
                      signedInBuilder: (context, auth) {
                        final s = auth.session;
                        final id = s?.id;
                        final tokObj = s?.lastActiveToken;
                        String? extractJwtFromSessionToken(
                                Object? tokObj,
                              ) {
                                if (tokObj == null) return null;
                                final s = tokObj.toString();
                                final key = 'jwt: ';
                                final i = s.indexOf(key);
                                if (i == -1) return null;
                                final start = i + key.length;
                                var end = s.indexOf('}', start);
                                if (end == -1) end = s.length;
                                return s.substring(start, end).trim();
                              }
                              final jwt = extractJwtFromSessionToken(tokObj);
                              debugPrint('JWT len=${jwt?.length} head=${jwt?.substring(0, 20)}');
                        return AddClerkCookie(sessionId: id, sessionToken: jwt);
                      },
                      signedOutBuilder: (context, authState) {
                        return const ClerkAuthentication();
                      }
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AddClerkCookie extends StatefulWidget {
  final String? sessionId;
  final String? sessionToken;
  const AddClerkCookie({super.key, this.sessionId, this.sessionToken});
  @override
  State<AddClerkCookie> createState() => _AddClerkCookieState();
}

class _AddClerkCookieState extends State<AddClerkCookie> {
  @override
  Widget build(BuildContext context) {
    return MainPage(sessionId: widget.sessionId, sessionToken: widget.sessionToken);
    }
 
}

class MainPage extends StatefulWidget {
  final String? sessionId;
  final String? sessionToken;
  const MainPage({super.key, this.sessionId, this.sessionToken});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? sessionId;
  String? sessionToken;
  late WebViewController controller;
  bool _online = true;
  bool _initialized = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    sessionId = widget.sessionId;
    sessionToken = widget.sessionToken;
    _setup();
  }

  Stream<List<ConnectivityResult>>? _connStream;
  void _initConnectivityListener() {
    _connStream = Connectivity().onConnectivityChanged;
    _connStream!.listen((results) async {
      final hasNet = !results.contains(ConnectivityResult.none);
      final reachable = hasNet ? await _hasInternet() : false;
      if (mounted) setState(() => _online = reachable);
      if (reachable && _initialized) {
        try {
          await controller.reload();
        } catch (_) {}
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http
          .head(Uri.parse('https://www.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      return resp.statusCode == 204 ||
          (resp.statusCode >= 200 && resp.statusCode < 400);
    } catch (_) {
      return false;
    }
  }

  Future<void> _setup() async {
    final initialConn = await Connectivity().checkConnectivity();
    final hasNet = initialConn.any((result) => result != ConnectivityResult.none);
    final reachable = hasNet ? await _hasInternet() : false;
    setState(() => _online = reachable);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            final can = await controller.canGoBack();
            if (mounted) setState(() => _canGoBack = can);
          },
          onNavigationRequest: (req) => NavigationDecision.navigate,
        ),
      );
      

      if (widget.sessionId != null && widget.sessionToken != null) {
      final cookieManager = WebviewCookieManager();
        print("currentToken  " + sessionToken!);
      final cookieMgr = WebViewCookieManager();
      final now = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      print("now  " + now);
      await cookieMgr.setCookie(WebViewCookie(name: '__client_uat', value: now, domain: '.silvernote.fr', path: '/',));
      await cookieMgr.setCookie(WebViewCookie(name: '__session', value: sessionToken!, domain: 'test-clerk.dev.silvernote.fr', path: '/'));
      final gotCookies = await cookieManager.getCookies('https://test-clerk.dev.silvernote.fr');
      print("cookies are :");
      for (var item in gotCookies) {
            print(item);
        }
      await controller.loadRequest(Uri.parse(appUrl));
      print("cookies are : (current) ");
      for (var item in gotCookies) {
            print(item);
        }
        Future.delayed(const Duration(seconds: 10), () {
              if (!mounted) return;
              for (var item in gotCookies) {
            print(item);
        }
        });
    }else {
      debugPrint('missing session: id=${widget.sessionId}, tok=${widget.sessionToken}');
    }
      


    if (Platform.isAndroid) {
      final androidCtrl = controller.platform as AndroidWebViewController;
      await androidCtrl.setOnShowFileSelector((params) async {
        return <String>[];
      });
    }

    setState(() => _initialized = true);
  }

  Future<void> _retry() async {
    final reachable = await _hasInternet();
    if (mounted) setState(() => _online = reachable);
    if (reachable) {
      if (_initialized) {
        try {
          await controller.reload();
        } catch (_) {}
      } else {
        await _setup();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top - 7.5;
    final header = Container(
      height: topPadding,
      color: const Color(0xFFF28C28),
    );

    if (!_online) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 120,
                  color: cs.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Pas de connexion internet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifier la connexion réseau et réessayer.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await controller.canGoBack()) {
          await controller.goBack();
          final can = await controller.canGoBack();
          if (mounted) setState(() => _canGoBack = can);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            header,
            Expanded(
              child: _initialized
                  ? WebViewWidget(controller: controller)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
