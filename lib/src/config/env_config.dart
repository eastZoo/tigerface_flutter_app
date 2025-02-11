class EnvConfig {
  static const String webviewUrl = String.fromEnvironment(
    'API_WEBVIEW_URL',
    // defaultValue: 'http://192.168.0.127:3003',
    defaultValue: 'https://dongryun-driver-webview.insystem.kr',
  );
}
