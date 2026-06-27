import 'app_link_config.dart';

enum AppLinkRoute { pixivAuthCallback, unknown }

final class AppLinkRequest {
  const AppLinkRequest(this.uri);

  final Uri uri;

  AppLinkRoute get route {
    if (uri.scheme == pixivAppLinkScheme && uri.host == pixivAuthCallbackHost && uri.path == pixivAuthCallbackPath) {
      return AppLinkRoute.pixivAuthCallback;
    }

    return AppLinkRoute.unknown;
  }

  String? get pixivAuthCode {
    if (route != AppLinkRoute.pixivAuthCallback) {
      return null;
    }

    final code = uri.queryParameters['code'];
    return code == null || code.isEmpty ? null : code;
  }
}
