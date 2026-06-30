import 'dart:io';

import 'package:freepiv/core/services/app_settings.dart';

HttpOverrides? _baseHttpOverrides;
bool _capturedBaseHttpOverrides = false;

void applyAppProxySettings(AppProxySettings settings) {
  if (!_capturedBaseHttpOverrides) {
    _baseHttpOverrides = HttpOverrides.current;
    _capturedBaseHttpOverrides = true;
  }

  final proxyUrl = settings.activeUrl;
  if (proxyUrl == null) {
    HttpOverrides.global = _baseHttpOverrides;
    return;
  }

  HttpOverrides.global = _AppProxyHttpOverrides(proxyRule: _proxyRuleForUrl(proxyUrl), fallback: _baseHttpOverrides);
}

class _AppProxyHttpOverrides extends HttpOverrides {
  _AppProxyHttpOverrides({required this.proxyRule, required this.fallback});

  final String proxyRule;
  final HttpOverrides? fallback;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = fallback?.createHttpClient(context) ?? super.createHttpClient(context);
    client.findProxy = (_) => proxyRule;
    return client;
  }

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return proxyRule;
  }
}

String _proxyRuleForUrl(String proxyUrl) {
  final uri = Uri.parse(proxyUrl);
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final port = uri.hasPort
      ? uri.port
      : switch (uri.scheme) {
          'socks' || 'socks4' || 'socks5' => 1080,
          _ => 80,
        };
  final rule = uri.scheme.toLowerCase().startsWith('socks') ? 'SOCKS' : 'PROXY';

  return '$rule $host:$port';
}
