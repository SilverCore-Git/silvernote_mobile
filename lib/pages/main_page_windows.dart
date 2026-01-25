import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../config/app_constants.dart';
import '../config/app_theme.dart';

class MainPageWindows extends StatefulWidget {
  const MainPageWindows({super.key});

  @override
  State<MainPageWindows> createState() => _MainPageWindowsState();
}

class _MainPageWindowsState extends State<MainPageWindows> {
  InAppWebViewController? webViewController;

  bool _isWebViewAvailable = false;
  String? _errorMessage;

  bool _online = true;
  bool _initialized = false;
  bool _isRetrying = false;

  String _customUserAgent = "SilverNoteApp Windows";
  String _initialUrl = appUrl;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    _checkWebViewAvailability();
  }

  Future<void> _checkWebViewAvailability() async {
    try {
      final availableVersion = await WebViewEnvironment.getAvailableVersion();

      if (!mounted) return;

      if (availableVersion == null) {
        setState(() {
          _isWebViewAvailable = false;
          _errorMessage = "WebView2 Runtime non détecté.\nVeuillez installer Microsoft Edge WebView2.";
        });
        return;
      }

      setState(() => _isWebViewAvailable = true);

      _initConnectivityListener();
      _initDeepLinks();
      _setup();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWebViewAvailable = false;
        _errorMessage = "Erreur d'initialisation WebView2: $e";
      });
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if(mounted) setState(() => _initialUrl = initialUri.toString());
      }
    } catch (_) {}

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      final target = uri.toString();
      if (webViewController != null) {
        webViewController!.loadUrl(
          urlRequest: URLRequest(
            url: WebUri(target),
            headers: const {'X-Custom-Header': 'flutter-app'},
          ),
        );
      } else {
        setState(() => _initialUrl = target);
      }
    }, onError: (_) {});
  }

  void _initConnectivityListener() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNet = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      final reachable = hasNet ? await _hasInternet() : false;
      if (!mounted) return;
      if (_online != reachable) setState(() => _online = reachable);
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final resp = await http.get(Uri.parse(appUrl)).timeout(const Duration(seconds: 5));
      return resp.statusCode >= 200 && resp.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setup() async {
    final initialConn = await Connectivity().checkConnectivity();
    final hasNet = initialConn.isNotEmpty && !initialConn.contains(ConnectivityResult.none);
    final reachable = hasNet ? await _hasInternet() : false;
    final deviceInfo = DeviceInfoPlugin();
    final windowsInfo = await deviceInfo.windowsInfo;
    final String dynamicUA =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36 SilvernoteApp/${windowsInfo.computerName}";

    if (!mounted) return;
    setState(() {
      _online = reachable;
      _customUserAgent = dynamicUA;
      _initialized = true;
    });
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isRetrying = false);
    final ok = await _hasInternet();

    if (mounted) {
      setState(() => _online = ok);
      if (ok && webViewController != null) {
        webViewController!.reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;
    if (!_isWebViewAvailable && _errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => launchUrl(Uri.parse("https://go.microsoft.com/fwlink/p/?LinkId=2124703")),
                child: const Text("Télécharger WebView2 Runtime"),
              )
            ],
          ),
        ),
      );
    }
    if (!_online) {
      final cs = theme.colorScheme;
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
                Text('Pas de connexion internet', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Vérifier la connexion réseau et réessayer.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                _isRetrying
                    ? const SizedBox(height: 48, width: 48, child: CircularProgressIndicator())
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: _initialized
                ? InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(_initialUrl),
                headers: const {'X-Custom-Header': 'flutter-app'},
              ),
              initialSettings: InAppWebViewSettings(
                transparentBackground: false,
                javaScriptEnabled: true,
                userAgent: _customUserAgent,
                isInspectable: kDebugMode,
                useShouldOverrideUrlLoading: true,
                incognito: false,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) return NavigationActionPolicy.CANCEL;

                final scheme = uri.scheme;
                if (!['http', 'https', 'file', 'about', 'data'].contains(scheme)) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) {
                // ignore: avoid_print
                if (kDebugMode) print("Page chargée: $url");
              },
              onReceivedError: (controller, request, error) {
                // ignore: avoid_print
                if (kDebugMode) print("Erreur de chargement: ${error.description}");
              },
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            height: 5.0,
            color: customColors.bottomBarColor,
          ),
        ],
      ),
    );
  }
}
