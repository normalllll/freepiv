import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

class PixivCommentAsset {
  const PixivCommentAsset({required this.name, required this.path});

  final String name;
  final String path;
}

class PixivCommentAssets {
  const PixivCommentAssets({required this.emojis, required this.stamps});

  static const empty = PixivCommentAssets(emojis: [], stamps: []);

  static Future<PixivCommentAssets>? _cachedLoad;

  final List<PixivCommentAsset> emojis;
  final List<PixivCommentAsset> stamps;

  Map<String, PixivCommentAsset> get emojiByName => {for (final asset in emojis) asset.name: asset};

  static Future<PixivCommentAssets> load() {
    return _cachedLoad ??= _load();
  }

  static Future<PixivCommentAssets> _load() async {
    final manifest = await services.AssetManifest.loadFromAssetBundle(services.rootBundle);
    final assets = manifest.listAssets();

    return PixivCommentAssets(
      emojis: _collectAssets(assets, directory: 'assets/emojis/', numericSort: false),
      stamps: _collectAssets(assets, directory: 'assets/stamps/', numericSort: true),
    );
  }

  static List<PixivCommentAsset> _collectAssets(List<String> assets, {required String directory, required bool numericSort}) {
    final entries = <PixivCommentAsset>[
      for (final path in assets)
        if (path.startsWith(directory) && _isImageAsset(path)) PixivCommentAsset(name: _assetName(path), path: path),
    ];

    entries.sort((a, b) {
      if (!numericSort) {
        return a.name.compareTo(b.name);
      }

      final left = int.tryParse(a.name);
      final right = int.tryParse(b.name);
      if (left != null && right != null) {
        return left.compareTo(right);
      }

      return a.name.compareTo(b.name);
    });

    return entries;
  }

  static bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.webp') || lower.endsWith('.gif');
  }

  static String _assetName(String path) {
    final fileName = path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }
}

class PixivEmojiTextEditingController extends TextEditingController {
  PixivEmojiTextEditingController(this._assets, {super.text});

  PixivCommentAssets _assets;

  set assets(PixivCommentAssets value) {
    if (identical(_assets, value)) {
      return;
    }

    _assets = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final composing = value.composing;
    if (withComposing && composing.isValid && !composing.isCollapsed) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }

    return TextSpan(
      style: style,
      children: buildPixivEmojiInlineSpans(text, emojiByName: _assets.emojiByName, style: style ?? DefaultTextStyle.of(context).style, sizeMultiplier: 1.15),
    );
  }
}

List<InlineSpan> buildPixivEmojiInlineSpans(
  String text, {
  required Map<String, PixivCommentAsset> emojiByName,
  required TextStyle style,
  double sizeMultiplier = 1.25,
}) {
  if (text.isEmpty) {
    return const [];
  }

  final spans = <InlineSpan>[];
  var index = 0;

  for (final match in _emojiTokenPattern.allMatches(text)) {
    final name = match.group(1);
    final emoji = name == null ? null : emojiByName[name];
    if (emoji == null) {
      continue;
    }

    if (match.start > index) {
      spans.add(TextSpan(text: text.substring(index, match.start)));
    }

    final fontSize = style.fontSize ?? 14;
    final size = fontSize * sizeMultiplier;
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Image.asset(emoji.path, width: size, height: size, filterQuality: FilterQuality.medium),
        ),
      ),
    );
    index = match.end;
  }

  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index)));
  }

  if (spans.isEmpty) {
    return [TextSpan(text: text)];
  }

  return spans;
}

final _emojiTokenPattern = RegExp(r'\(([A-Za-z0-9_]+)\)');
