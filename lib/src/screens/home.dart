import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tigerface_flutter_app/src/config/env_config.dart';
import 'package:tigerface_flutter_app/src/views/popup_window.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _webViewController;
  bool isLoading = true;
  bool canGoBack = false;
  final ImagePicker _picker = ImagePicker();
  String? _cameraPhotoPath;

  /// 권한 체크 (카메라, 저장소, 위치)
  Future<void> _checkPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.location,
    ].request();
  }

  /// 화면을 세로 모드로 고정
  Future<void> _setPortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void initState() {
    super.initState();

    // 권한 체크 및 화면 방향 설정
    _checkPermissions();
    _setPortraitMode();

    // 플랫폼에 따른 WebViewController 생성 파라미터 설정
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params);

    // 안드로이드의 경우 디버깅 비활성화 등 추가 설정
    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
    }

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // 페이지 로드 시작 시 로딩 인디케이터 표시
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          // 페이지 로드 완료 시 로딩 인디케이터 숨김 및 뒤로가기 가능 여부 업데이트
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
            });
            bool canGoBackFlag = await _webViewController.canGoBack();
            setState(() {
              canGoBack = canGoBackFlag;
            });
            // iOS의 경우 터치 시 회색 하이라이트 효과 제거를 위한 CSS 주입
            if (Platform.isIOS) {
              _webViewController.runJavaScript('''
                (function() {
                  var style = document.createElement('style');
                  style.innerHTML = '* { -webkit-tap-highlight-color: rgba(0, 0, 0, 0) !important; }';
                  document.head.appendChild(style);
                })();
              ''');
            }
          },
          // 웹뷰 로드 에러 발생 시 에러 메시지 출력 및 HTML 에러 페이지 표시
          onWebResourceError: (WebResourceError error) {
            print("❌ 웹뷰 로드 오류 발생!");
            print("🔴 오류 코드: ${error.errorCode}");
            print("🔴 오류 메시지: ${error.description}");
            _webViewController.loadHtmlString('''
              <html>
                <body>
                  <h3>페이지를 불러올 수 없습니다.</h3>
                  <p>오류 코드: ${error.errorCode}</p>
                  <p>오류 메시지: ${error.description}</p>
                </body>
              </html>
            ''');
          },
          // 필요 시 onNavigationRequest를 통해 팝업(새창) 처리 가능 (예시로 모두 허용)
          onNavigationRequest: (NavigationRequest request) {
            // 예: 새창 열기가 필요한 경우 PopupWindow를 띄워 처리할 수 있음.
            // 현재 예제에서는 모든 요청을 허용합니다.
            return NavigationDecision.navigate;
          },
        ),
      )
      // 웹뷰에 초기 URL 로드
      ..loadRequest(Uri.parse(EnvConfig.webviewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 뒤로가기 버튼 클릭 시 _onWillPop 실행
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // webview_flutter에서 제공하는 WebViewWidget 사용
              WebViewWidget(
                controller: _webViewController,
              ),
              // 로딩 중일 때 중앙에 로딩 인디케이터 표시
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

  /// 앱 종료 여부를 묻는 다이얼로그
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

  /// 뒤로가기 버튼 클릭 시 현재 URL에 따른 처리
  Future<bool> _onWillPop() async {
    final urlString = await _webViewController.currentUrl();
    if (urlString != null) {
      final uri = Uri.parse(urlString);
      // 매칭 목록, 홈, 더보기 페이지인 경우 앱 종료 다이얼로그 표시
      if (uri.path == '/matchlist' ||
          uri.path == '/home' ||
          uri.path == '/more') {
        return await _showExitDialog();
      }
      // task-chargeTransfer 경로인 경우 홈으로 이동
      if (urlString.contains('/task-chargeTransfer')) {
        _webViewController.loadRequest(Uri.parse('${EnvConfig.webviewUrl}/'));
        return false;
      }
    }
    // 이전 페이지로 돌아갈 수 있다면 뒤로가기 실행
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false;
    }
    // 그 외에는 앱 종료 다이얼로그 표시
    return await _showExitDialog();
  }
}
