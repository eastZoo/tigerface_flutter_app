class EnvConfig {
  static const String webviewUrl = String.fromEnvironment(
    'API_WEBVIEW_URL',
    defaultValue: 'http://172.30.1.53:3003',
    // defaultValue: 'https://dongryun-driver-webview.insystem.kr',
  );
}
