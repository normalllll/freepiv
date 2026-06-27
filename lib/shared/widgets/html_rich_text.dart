import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class HtmlRichText extends StatefulWidget {
  const HtmlRichText(this.htmlString, {this.padding, this.overflow = TextOverflow.clip, this.maxLines, this.style, super.key});

  final String htmlString;
  final EdgeInsetsGeometry? padding;
  final TextOverflow overflow;
  final int? maxLines;
  final TextStyle? style;

  @override
  State<HtmlRichText> createState() => _HtmlRichTextState();
}

class _HtmlRichTextState extends State<HtmlRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tapRecognizer(GestureTapCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  TextSpan _buildNode(html.Node node, {bool isStrong = false}) {
    if (node.nodeType == html.Node.TEXT_NODE) {
      return TextSpan(text: node.text);
    }

    if (node is! html.Element) {
      return TextSpan(text: node.text);
    }

    switch (node.localName) {
      case 'br':
        return const TextSpan(text: '\n');
      case 'a':
        return _buildLinkNode(node, isStrong: isStrong);
      case 'strong':
      case 'b':
        return _buildStrongNode(node);
      case 'span':
      case 'i':
      case 'em':
        return _buildChildren(node, isStrong: isStrong);
      case 'p':
        return TextSpan(
          children: [
            ..._buildChildSpans(node, isStrong: isStrong),
            const TextSpan(text: '\n'),
          ],
        );
    }

    return _buildChildren(node, isStrong: isStrong);
  }

  TextSpan _buildLinkNode(html.Element node, {required bool isStrong}) {
    final href = node.attributes['href']?.trim();
    final text = node.text.trim();

    if (href == null || href.isEmpty) {
      return TextSpan(text: text);
    }

    final twitterUsername = _twitterUsernameFromUrl(href);
    if (twitterUsername != null) {
      return TextSpan(
        text: context.t.richText.twitterUser(username: twitterUsername),
        style: _knownLinkStyle(isStrong),
        recognizer: _tapRecognizer(() {
          _openTwitterUser(twitterUsername, fallbackUrl: href);
        }),
      );
    }

    final illustId = _illustIdFromUrl(href);
    if (illustId != null) {
      return TextSpan(
        text: context.t.richText.illustId(id: illustId),
        style: _knownLinkStyle(isStrong),
        recognizer: _tapRecognizer(() {
          context.pushNamed(AppRoute.illustDetail.name, pathParameters: {'id': illustId});
        }),
      );
    }

    final novelId = _novelIdFromUrl(href);
    if (novelId != null) {
      return TextSpan(
        text: 'Novel ID: $novelId',
        style: _knownLinkStyle(isStrong),
        recognizer: _tapRecognizer(() {
          context.pushNamed(AppRoute.novelDetail.name, pathParameters: {'id': novelId});
        }),
      );
    }

    final userId = _userIdFromUrl(href);
    if (userId != null) {
      return TextSpan(
        text: context.t.richText.userId(id: userId),
        style: _knownLinkStyle(isStrong),
        recognizer: _tapRecognizer(() {
          context.pushNamed(AppRoute.userDetail.name, pathParameters: {'id': userId});
        }),
      );
    }

    return TextSpan(
      text: text.isEmpty ? href : text,
      style: _genericLinkStyle(isStrong),
      recognizer: _tapRecognizer(() {
        _openExternalUrl(href);
      }),
    );
  }

  TextSpan _buildStrongNode(html.Element node) {
    final twitterUsername = _twitterUsernameFromText(node.text);
    if (twitterUsername != null) {
      return TextSpan(
        text: context.t.richText.twitterUser(username: twitterUsername),
        style: _knownLinkStyle(true),
        recognizer: _tapRecognizer(() {
          _openTwitterUser(twitterUsername);
        }),
      );
    }

    return _buildChildren(node, isStrong: true);
  }

  TextSpan _buildChildren(html.Element node, {required bool isStrong}) {
    final childSpans = _buildChildSpans(node, isStrong: isStrong);
    if (childSpans.isEmpty) {
      return TextSpan(text: node.text, style: isStrong ? _strongStyle : null);
    }

    return TextSpan(style: isStrong ? _strongStyle : null, children: childSpans);
  }

  List<TextSpan> _buildChildSpans(html.Element node, {required bool isStrong}) {
    return [for (final child in node.nodes) _buildNode(child, isStrong: isStrong)];
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final document = html_parser.parseFragment(widget.htmlString, generateSpans: true);
    final colorScheme = Theme.of(context).colorScheme;
    final text = TextSpan(
      style:
          widget.style ??
          Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface, height: 1.35) ??
          TextStyle(color: colorScheme.onSurface),
      children: [for (final node in document.nodes) _buildNode(node)],
    );
    final richText = RichText(overflow: widget.overflow, maxLines: widget.maxLines, text: text);
    final padding = widget.padding;

    if (padding == null) {
      return richText;
    }

    return Padding(padding: padding, child: richText);
  }
}

const _strongStyle = TextStyle(fontWeight: FontWeight.bold);

TextStyle _genericLinkStyle(bool isStrong) {
  return TextStyle(color: Colors.blue, fontWeight: isStrong ? FontWeight.bold : null);
}

TextStyle _knownLinkStyle(bool isStrong) {
  return TextStyle(color: Colors.pinkAccent, fontWeight: isStrong ? FontWeight.bold : null);
}

Future<void> _openTwitterUser(String username, {String? fallbackUrl}) async {
  final appUri = Uri(scheme: 'twitter', host: 'user', queryParameters: {'screen_name': username});

  if (await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
    return;
  }

  await _openExternalUrl(fallbackUrl ?? 'https://mobile.twitter.com/$username');
}

Future<void> _openExternalUrl(String value) async {
  final uri = _uriFor(value);
  if (uri == null) {
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri? _uriFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed == null) {
    return null;
  }

  if (parsed.hasScheme) {
    return parsed;
  }

  return Uri.tryParse('https://$trimmed');
}

String? _twitterUsernameFromUrl(String value) {
  final uri = _uriFor(value);
  final host = uri?.host.toLowerCase();
  if (uri == null ||
      host == null ||
      (host != 'twitter.com' && host != 'www.twitter.com' && host != 'mobile.twitter.com' && host != 'x.com' && host != 'www.x.com')) {
    return null;
  }

  final username = uri.pathSegments.where((segment) => segment.trim().isNotEmpty).firstOrNull;
  if (username == null || _reservedTwitterPaths.contains(username)) {
    return null;
  }

  return _normalizeTwitterUsername(username);
}

String? _twitterUsernameFromText(String value) {
  final match = RegExp(r'^@([A-Za-z0-9_]{1,15})$').firstMatch(value.trim());
  return match?.group(1);
}

String? _normalizeTwitterUsername(String value) {
  final match = RegExp(r'^@?([A-Za-z0-9_]{1,15})$').firstMatch(value.trim());
  return match?.group(1);
}

String? _illustIdFromUrl(String value) {
  final uri = _pixivUriFor(value);
  if (uri == null) {
    return null;
  }

  final artworkIndex = uri.pathSegments.indexOf('artworks');
  if (artworkIndex >= 0 && artworkIndex + 1 < uri.pathSegments.length) {
    return _numericId(uri.pathSegments[artworkIndex + 1]);
  }

  return _numericId(uri.queryParameters['illust_id']);
}

String? _novelIdFromUrl(String value) {
  final uri = _pixivUriFor(value);
  if (uri == null) {
    return null;
  }

  final novelIndex = uri.pathSegments.indexOf('novel');
  if (novelIndex >= 0 && novelIndex + 1 < uri.pathSegments.length) {
    return _numericId(uri.pathSegments[novelIndex + 1]) ?? _numericId(uri.queryParameters['id']);
  }

  return _numericId(uri.queryParameters['novel_id']);
}

String? _userIdFromUrl(String value) {
  final uri = _pixivUriFor(value);
  if (uri == null) {
    return null;
  }

  final usersIndex = uri.pathSegments.indexOf('users');
  if (usersIndex >= 0 && usersIndex + 1 < uri.pathSegments.length) {
    return _numericId(uri.pathSegments[usersIndex + 1]);
  }

  return _numericId(uri.queryParameters['id']);
}

Uri? _pixivUriFor(String value) {
  final uri = _uriFor(value);
  final host = uri?.host.toLowerCase();
  if (uri == null || host == null || (host != 'pixiv.net' && !host.endsWith('.pixiv.net'))) {
    return null;
  }

  return uri;
}

String? _numericId(String? value) {
  if (value == null) {
    return null;
  }

  final match = RegExp(r'^\d+$').firstMatch(value.trim());
  return match?.group(0);
}

const _reservedTwitterPaths = {'home', 'i', 'intent', 'search', 'share', 'explore', 'hashtag', 'settings', 'messages', 'notifications'};
