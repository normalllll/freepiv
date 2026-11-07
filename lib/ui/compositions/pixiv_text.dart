import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/features/pixivision/navigation.dart' show openPixivisionLink;
import 'package:frost_ui/frost_ui.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;

/// Text people wrote on pixiv (a work's caption, a profile), from its HTML:
/// shown exactly as written, with only its links tappable. pixiv links open
/// in the app, others in the browser.
class AppPixivText extends StatelessWidget {
  const AppPixivText(this.html, {this.maxLines = 3, super.key});

  final String html;
  final int maxLines;

  @override
  Widget build(BuildContext context) => FrostExpandableText.linked(
    runs: pixivTextRuns(html),
    maxLines: maxLines,
    onLink: (uri) => unawaited(openPixivisionLink(context, uri.toString())),
  );
}

/// pixiv's HTML as runs of text in source order: line breaks kept, tags
/// dropped, every character as written; each `<a>` that points at a web
/// address is a run with that link. Leading and trailing space is trimmed.
List<FrostTextRun> pixivTextRuns(String value) {
  final runs = <FrostTextRun>[];
  final plain = StringBuffer();
  void flush() {
    if (plain.isEmpty) return;
    runs.add(FrostTextRun(plain.toString()));
    plain.clear();
  }

  void visit(html.Node node) {
    if (node is html.Text) {
      plain.write(node.text);
      return;
    }
    if (node is! html.Element) return;
    switch (node.localName) {
      case 'br':
        plain.write('\n');
      case 'a':
        final href = node.attributes['href'] ?? '';
        final target = pixivLinkTarget(href);
        final label = node.text.trim();
        if (target == null) {
          plain.write(node.text);
        } else {
          flush();
          runs.add(FrostTextRun(label.isEmpty ? target.toString() : label, link: target));
        }
      case 'p':
        node.nodes.forEach(visit);
        plain.write('\n');
      default:
        node.nodes.forEach(visit);
    }
  }

  html_parser.parseFragment(value).nodes.forEach(visit);
  flush();
  return _trimmed(runs);
}

List<FrostTextRun> _trimmed(List<FrostTextRun> runs) {
  final result = [...runs];
  while (result.isNotEmpty && result.first.link == null && result.first.text.trim().isEmpty) {
    result.removeAt(0);
  }
  while (result.isNotEmpty && result.last.link == null && result.last.text.trim().isEmpty) {
    result.removeLast();
  }
  if (result.isEmpty) return result;
  if (result.first.link == null) result[0] = FrostTextRun(result.first.text.trimLeft());
  if (result.last.link == null) result[result.length - 1] = FrostTextRun(result.last.text.trimRight());
  return result;
}

/// The web address a pixiv `href` points at, or null when it is not a web
/// link: `pixiv://` app links become their web pages, and `/jump.php?`
/// redirects (bare or `?url=`) become the address they lead to.
Uri? pixivLinkTarget(String href) {
  final value = href.trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value.startsWith('/') && !value.startsWith('//') ? 'https://www.pixiv.net$value' : value);
  if (uri == null) return null;
  if (uri.scheme == 'pixiv') {
    final id = uri.pathSegments.firstOrNull;
    if (id == null || int.tryParse(id) == null) return null;
    return switch (uri.host) {
      'illusts' => Uri.https('www.pixiv.net', '/artworks/$id'),
      'users' => Uri.https('www.pixiv.net', '/users/$id'),
      'novels' => Uri.https('www.pixiv.net', '/novel/show.php', {'id': id}),
      _ => null,
    };
  }
  if (uri.scheme != 'https' && uri.scheme != 'http' || uri.host.isEmpty) return null;
  if (uri.host.endsWith('pixiv.net') && uri.path == '/jump.php') {
    final query = uri.query;
    final wrapped = query.startsWith('url=') ? _decoded(query.substring('url='.length)) : _decoded(query);
    final target = pixivLinkTarget(wrapped);
    return target != null && target.path != '/jump.php' ? target : null;
  }
  return uri;
}

/// [value] percent-decoded, or as it is when it is not valid encoding.
String _decoded(String value) {
  try {
    return Uri.decodeComponent(value);
  } on ArgumentError {
    return value;
  }
}
