import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../config/app_constants.dart';
import '../config/app_theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  InAppWebViewController? webViewController;
  bool _online = true;
  bool _initialized = false;
  bool _isRetrying = false;

  late final AppLinks _appLinks;
  StreamSubscription? _linkSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  String _initialUrl = appUrl;

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _initDeepLinks();
    _setup();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && initialUri.host == appUrl) {
        setState(() {
          _initialUrl = initialUri.toString();
        });
      }
    } catch (_) {}

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == appUrl) {
        final target = uri.toString();
        if (webViewController != null) {
          webViewController!.loadUrl(
            urlRequest: URLRequest(
              url: WebUri(target),
              headers: {'X-Custom-Header': 'flutter-app'},
            ),
          );
        } else {
          setState(() {
            _initialUrl = target;
          });
        }
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  void _initConnectivityListener() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNet = !results.contains(ConnectivityResult.none);
      final reachable = hasNet ? await _hasInternet() : false;
      if (!mounted) return;
      if (_online != reachable) {
        setState(() => _online = reachable);
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http
          .get(Uri.parse(appUrl))
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
    if (mounted) {
      setState(() {
        _online = reachable;
        _initialized = true;
      });
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    final randomMs = 3000 + Random().nextInt(4001);
    await Future.delayed(Duration(milliseconds: randomMs));
    setState(() => _isRetrying = false);
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;
    final isDarkMode = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    final header = Container(
      height: topPadding,
      color: theme.scaffoldBackgroundColor,
    );

    final bottomBar = Container(
      height: bottomPadding + -5,
      color: customColors.bottomBarColor,
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
                _isRetrying
                    ? const SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(),
                )
                    : FilledButton.icon(
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final controller = webViewController;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            header,
            Expanded(
              child: _initialized
                  ? InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(_initialUrl),
                  headers: {'X-Custom-Header': 'flutter-app'},
                ),
                onLoadStart: (controller, url) async {
                  if (url.toString().contains("/auth/sso-callback")) {
                    if (kDebugMode) {
                      // ignore: avoid_print
                      print("OAuth finished inside WebView");
                    }
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
                  await controller.loadUrl(
                    urlRequest: URLRequest(url: uri, headers: headers),
                  );
                  return NavigationActionPolicy.CANCEL;
                },
              )
                  : const Center(child: CircularProgressIndicator()),
            ),
            bottomBar,
          ],
        ),
      ),
    );
  }
}
