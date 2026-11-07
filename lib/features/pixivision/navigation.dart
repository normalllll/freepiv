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
  if (uri!.host == 'www.pixiv.net' || uri.host == 'pixiv.net') {
    final segments = uri.pathSegments;
    String Function(Object id)? location;
    String? id;
    for (final (segment, destination) in [('artworks', AppLocations.illust), ('users', AppLocations.user)]) {
      final index = segments.indexOf(segment);
      if (index >= 0 && segments.length > index + 1) {
        location = destination;
        id = segments[index + 1];
        break;
      }
    }
    // A pixiv website URL, not an app route.
    if (uri.path.contains('/novel/show.php')) {
      location = AppLocations.novel;
      id = uri.queryParameters['id'];
    }
    if (location != null && id != null && int.tryParse(id) != null) {
      await context.push(location(id));
      return;
    }
  }
  await openPixivisionExternalLink(context, value);
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
