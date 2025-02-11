import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tigerface_flutter_app/src/config/env_config.dart';
import 'package:tigerface_flutter_app/src/views/popup_window.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  bool canGoBack = false;
  final ImagePicker _picker = ImagePicker();
  String? _cameraPhotoPath;

  Future<void> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.location,
    ].request();
  }

  Future<void> _setPortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setPortraitMode();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(EnvConfig.webviewUrl),
                ),
                androidOnGeolocationPermissionsShowPrompt:
                    (InAppWebViewController controller, String origin) async {
                  return GeolocationPermissionShowPromptResponse(
                      origin: origin, allow: true, retain: true);
                },
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                    javaScriptCanOpenWindowsAutomatically: true,
                    javaScriptEnabled: true,
                    useOnDownloadStart: true,
                    useOnLoadResource: true,
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    transparentBackground: false,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    userAgent:
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36',
                  ),
                  android: AndroidInAppWebViewOptions(
                      useWideViewPort: true,
                      geolocationEnabled: true,
                      useHybridComposition: true,
                      allowContentAccess: true,
                      builtInZoomControls: true,
                      thirdPartyCookiesEnabled: true,
                      allowFileAccess: true,
                      supportMultipleWindows: true,
                      overScrollMode: AndroidOverScrollMode.OVER_SCROLL_NEVER),
                  ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true,
                    allowsBackForwardNavigationGestures: true,
                    enableViewportScale: false,
                  ),
                ),
                onCreateWindow: (controller, createWindowAction) async {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return PopupWindow(
                        createWindowAction: createWindowAction,
                      );
                    },
                  );
                  return true;
                },
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    isLoading = false;
                  });
                  final canGoBackStatus = await controller.canGoBack();
                  setState(() {
                    canGoBack = canGoBackStatus;
                  });
                },
                onLoadError: (controller, url, code, message) {
                  print('웹뷰 에러: $message');
                },
                onConsoleMessage: (controller, consoleMessage) {
                  print("웹뷰 콘솔: ${consoleMessage.message}");
                },
                androidOnPermissionRequest: (InAppWebViewController controller,
                    String origin, List<String> resources) async {
                  return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT);
                },
              ),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 앱 종료 모달
  Future<bool> _showExitDialog() async {
    if (!mounted) return false;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: const Text(
              '앱 종료',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              '앱을 종료하시겠습니까?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFEFF6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        '종료',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _onWillPop() async {
    final currentUrl = await webViewController?.getUrl();

    // 매칭 목록, 홈, 더보기 페이지인 경우 앱 종료 모달
    if (currentUrl?.path == '/matchlist' ||
        currentUrl?.path == '/home' ||
        currentUrl?.path == '/more') {
      return await _showExitDialog();
    }

    // task-chargeTransfer 경로인 경우 홈으로
    if (currentUrl?.toString().contains('/task-chargeTransfer') ?? false) {
      await webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri('${EnvConfig.webviewUrl}/')),
      );
      return false;
    }

    // 이전 페이지로 돌아갈 수 있는 경우
    if (await webViewController?.canGoBack() ?? false) {
      webViewController?.goBack();
      return false;
    }

    return await _showExitDialog();
  }
}
