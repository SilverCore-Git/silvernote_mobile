import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

const appUrl = 'https://app.silvernote.fr/';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF28C28),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF28C28),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  InAppWebViewController? webViewController;
  bool _online = true;
  bool _initialized = false;
  // ignore: unused_field
  bool _canGoBack = false;

  Stream<List<ConnectivityResult>>? _connStream;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _setup();
  }

  void _initConnectivityListener() {
    _connStream = Connectivity().onConnectivityChanged;
    _connStream!.listen((results) async {
      final hasNet = !results.contains(ConnectivityResult.none);
      final reachable = hasNet ? await _hasInternet() : false;
      if (mounted) setState(() => _online = reachable);
      if (reachable && _initialized) {
        try {
          await webViewController?.reload();
        } catch (_) {}
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http
          .get(Uri.parse('https://app.silvernote.fr/'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode >= 200 && resp.statusCode < 400;
    } catch (_) {
      return true;
    }
  }

  Future<void> _setup() async {
    final initialConn = await Connectivity().checkConnectivity();
    final hasNet = initialConn.any(
      (result) => result != ConnectivityResult.none,
    );
    final reachable = hasNet ? await _hasInternet() : false;
    setState(() => _online = reachable);

    setState(() => _initialized = true);
  }

  Future<void> _retry() async {
    final reachable = await _hasInternet();
    if (mounted) setState(() => _online = reachable);
    if (reachable) {
      if (_initialized) {
        try {
          await webViewController?.reload();
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
                Icon(Icons.wifi_off_rounded, size: 120, color: cs.secondary),
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

    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null) {
          final canGoBack = await webViewController!.canGoBack();
          if (canGoBack) {
            await webViewController!.goBack();
            final can = await webViewController!.canGoBack();
            if (mounted) setState(() => _canGoBack = can);
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        body: Column(
          children: [
            header,
            Expanded(
              child: _initialized
                  ? InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(appUrl),
                        headers: {'X-Custom-Header': 'flutter-app'},
                      ),
                      onLoadStart: (controller, url) async {
                        if (url.toString().contains("/auth/sso-callback")) {
                          print("OAuth finished inside WebView");
                        }
                      },
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        useHybridComposition: true,
                        userAgent:
                            "Mozilla/5.0 (Linux; Android 10; Mobile) WebViewApp",
                        thirdPartyCookiesEnabled: true,
                        useShouldOverrideUrlLoading: true,
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStop: (controller, url) async {
                        final can = await controller.canGoBack();
                        if (mounted) setState(() => _canGoBack = can);
                      },
                      shouldOverrideUrlLoading: (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri == null) {
                          return NavigationActionPolicy.CANCEL;
                        }
                        final urlString = uri.toString();
                        final isIntent = urlString.startsWith('intent://');
                        final isCustomScheme =
                            uri.scheme != 'http' &&
                            uri.scheme != 'https' &&
                            uri.scheme != 'about' &&
                            uri.scheme != 'data';

                        if (isIntent || isCustomScheme) {
                          try {
                            final launchUri = Uri.parse(urlString);
                            await launchUrl(
                              launchUri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                        final headers = {'X-Custom-Header': 'flutter-app'};
                        debugPrint(
                          '[WEBVIEW] Navigation vers $uri avec headers: $headers',
                        );
                        await controller.loadUrl(
                          urlRequest: URLRequest(url: uri, headers: headers),
                        );
                        return NavigationActionPolicy.CANCEL;
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
