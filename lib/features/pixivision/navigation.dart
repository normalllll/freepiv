import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

Future<void> openPixivisionLink(BuildContext context, String value, {ArticleSummary? summary}) async {
  final uri = Uri.tryParse(value);
  if (!_isWebLink(uri)) return;
  if (validPixivisionUrl(value) != null) {
    final segments = uri!.pathSegments;
    final article = segments.length >= 3 && segments[1] == 'a' && int.tryParse(segments[2]) != null;
    final listing = segments.length == 1 || segments.length == 2 && segments[1].isEmpty || segments.length >= 2 && ['c', 's', 't'].contains(segments[1]);
    if (article || listing) {
      await context.push(article ? AppLocations.pixivisionArticle(uri.toString()) : AppLocations.pixivisionBrowse(url: uri.toString()), extra: summary);
      return;
    }
  }
  if (pixivAppLocation(uri!) case final location?) {
    await context.push(location);
    return;
  }
  await openPixivisionExternalLink(context, value);
}

const _pixivHosts = {'pixiv.net', 'www.pixiv.net', 'touch.pixiv.net', 'm.pixiv.net'};

/// The app location of a pixiv website address for a work, a user or a
/// novel, current or legacy (`member.php?id=`, `member_illust.php?illust_id=`,
/// `/i/<id>`, the touch and mobile hosts), or null for anything else.
String? pixivAppLocation(Uri uri) {
  if (!_pixivHosts.contains(uri.host.toLowerCase())) return null;
  String? numeric(String? value) => value != null && int.tryParse(value) != null ? value : null;
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
  // These are pixiv website paths, not app routes.
  for (final (segment, location) in [('artworks', AppLocations.illust), ('users', AppLocations.user), ('i', AppLocations.illust)]) {
    final index = segments.indexOf(segment);
    if (index >= 0 && index + 1 < segments.length) {
      if (numeric(segments[index + 1]) case final id?) return location(id);
    }
  }
  final page = segments.lastOrNull;
  final query = uri.queryParameters;
  return switch (page) {
    'show.php' when segments.contains('novel') => numeric(query['id']).map(AppLocations.novel),
    'member_illust.php' => numeric(query['illust_id']).map(AppLocations.illust) ?? numeric(query['id']).map(AppLocations.user),
    'member.php' => numeric(query['id']).map(AppLocations.user),
    _ => null,
  };
}

extension on String? {
  T? map<T>(T Function(String value) transform) => switch (this) {
    final value? => transform(value),
    null => null,
  };
}

bool _isWebLink(Uri? uri) => uri != null && ['https', 'http'].contains(uri.scheme) && uri.host.isNotEmpty && uri.userInfo.isEmpty;

Future<void> openPixivisionExternalLink(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (!_isWebLink(uri)) return;
  try {
    if (await launchUrl(uri!, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Surface the same actionable failure for unsupported handlers and errors.
  }
  if (context.mounted) FrostToast.error(context.t.pixivision.openFailed);
}

String? validPixivisionUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || uri.scheme != 'https' || uri.host != 'www.pixivision.net' || uri.userInfo.isNotEmpty || (uri.hasPort && uri.port != 443)) return null;
  if (!RegExp(r'^/(ja|en|zh|zh-tw|ko|th|ms)(/|$)').hasMatch(uri.path)) return null;
  return uri.toString();
}
