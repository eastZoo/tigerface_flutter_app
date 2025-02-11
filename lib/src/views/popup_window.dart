import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// PopupWindow는 새 창(팝업) 형태의 WebView를 보여줍니다.
/// [initialUrl]에 새 창에서 로드할 URL을 전달합니다.
class PopupWindow extends StatefulWidget {
  final String initialUrl;

  const PopupWindow({super.key, required this.initialUrl});

  @override
  State<PopupWindow> createState() => _PopupWindowState();
}

class _PopupWindowState extends State<PopupWindow> {
  late final WebViewController _popupController;
  String title = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // 플랫폼 별로 WebViewController 생성 시 필요한 파라미터 설정
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _popupController = WebViewController.fromPlatformCreationParams(params);

    // 안드로이드의 경우 디버깅 비활성화 등 추가 설정
    if (_popupController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
    }

    _popupController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              isLoading = false;
            });
            // 페이지 로드 후 JavaScript로 문서 제목(document.title)을 가져옵니다.
            final result = await _popupController
                .runJavaScriptReturningResult("document.title");
            String newTitle = result.toString();
            // 결과값이 큰따옴표(")로 감싸진 경우 이를 제거합니다.
            if (newTitle.startsWith('"') && newTitle.endsWith('"')) {
              newTitle = newTitle.substring(1, newTitle.length - 1);
            }
            setState(() {
              title = newTitle;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // 모든 네비게이션 요청을 허용합니다.
            return NavigationDecision.navigate;
          },
        ),
      )
      // 초기 URL 로드
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      // 모서리가 잘린 다이얼로그 형태가 아니라 전체 화면 팝업을 위해 BeveledRectangleBorder 사용
      shape: const BeveledRectangleBorder(borderRadius: BorderRadius.zero),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀 바: 제목과 닫기 버튼 포함
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : widget.initialUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // WebView 영역 및 로딩 인디케이터 오버레이
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _popupController),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
