import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/ReviewService.dart';
import 'package:home_widget/home_widget.dart';

import '../config/app_constants.dart';

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
  String _customUserAgent = "";

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

  Future<void> _updateHomeScreenWidget() async {
    await HomeWidget.saveWidgetData<String>('url', 'https://app.silvernote.fr/edit/new');

    await HomeWidget.updateWidget(
      name: 'SilverNoteWidgetProvider',
      androidName: 'widget_layout',
    );
  }

  Future<void> _checkReviewPopup() async {
    final service = ReviewService();
    var settings = await service.readSettings();

    if (settings['neverShowAgain'] == true) return;

    int currentCounter = settings['counter'];

    if (currentCounter <= 0) {
      Future.delayed(const Duration(seconds: 2), () => _showReviewDialog());
    } else {
      await service.saveSettings(currentCounter - 1, false);
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);

        Color dialogBgColor = Color(0xFF252525);
        if (theme.scaffoldBackgroundColor == const Color(0xFF121212)) {
          dialogBgColor = const Color(0xFF252525);
        } else if (theme.scaffoldBackgroundColor == const Color(0xFFFFF8F0)) {
          dialogBgColor = theme.scaffoldBackgroundColor;
        }

        return AlertDialog(
          backgroundColor: dialogBgColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),

          titlePadding: EdgeInsets.zero,
          title: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                    onPressed: () async {
                      await ReviewService().saveSettings(5, false);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
              const Icon(Icons.stars_rounded, size: 45, color: Color(0xFFF28C28)),
            ],
          ),

          contentPadding: const EdgeInsets.fromLTRB(40, 10, 40, 45),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vous aimez SilverNote ?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Votre avis nous aide énormément à améliorer l\'application !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        await ReviewService().saveSettings(0, true);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        'Ne plus me le rappeler',
                        style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF28C28),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final url = Uri.parse("https://play.google.com/store/apps/details?id=fr.silvercore.silvernote");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    await ReviewService().saveSettings(15, false);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text('Avec plaisir !', style :TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint("Lien au démarrage détecté : $initialUri");

        String urlToLoad = initialUri.toString();
        if (urlToLoad.contains("silvernote://")) {
          urlToLoad = "https://app.silvernote.fr/edit/new";
        }

        if (mounted) {
          setState(() {
            _initialUrl = urlToLoad;
            _initialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur initial link: $e");
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      debugPrint("Lien reçu en cours de route : $uri");
      String target = uri.toString();

      if (target.contains("silvernote://")) {
        target = "https://app.silvernote.fr/edit/new";
      }

      webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(target),
          headers: {'X-Custom-Header': 'flutter-app'},
        ),
      );
    });
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
    final hasNet = initialConn.any((result) => result != ConnectivityResult.none);
    final reachable = hasNet ? await _hasInternet() : false;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final release = androidInfo.version.release;
    final model = androidInfo.model;
    final buildId = androidInfo.id;
    final String dynamicUA =
        "Mozilla/5.0 (Appareil mobile $model; Android $release; $model Build/$buildId) "
        "SilvernoteApp "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.6099.210 "
        "Mobile Safari/537.36"
        ;
    if (kDebugMode) {
      print(dynamicUA);
    }
    if (mounted) {
      setState(() {
        _online = reachable;
        _customUserAgent = dynamicUA;
        _initialized = true;
      });

      _checkReviewPopup();
    }
    _updateHomeScreenWidget();
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

    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color topBarColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F2ED);
    final Color bottomBarColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFEFE9E0);

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
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            // --- LA BARRE DU HAUT ---
            Container(
              color: topBarColor,
              child: const SafeArea(
                top: true,
                bottom: false,
                child: SizedBox(width: double.infinity),
              ),
            ),
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
                  userAgent: _customUserAgent,
                  thirdPartyCookiesEnabled: true,
                  useShouldOverrideUrlLoading: true,
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri == null) return NavigationActionPolicy.CANCEL;
                  if (uri.scheme != 'http' && uri.scheme != 'https') {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Transform.translate(
              offset: const Offset(0, -1),
              child: Container(
                color: bottomBarColor,
                child: const SafeArea(
                  top: false,
                  bottom: true,
                  child: SizedBox(width: double.infinity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
