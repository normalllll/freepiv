import 'package:flutter/material.dart';

@immutable
class AppSystemFontConfig {
  const AppSystemFontConfig({required this.family, required this.fallbacks});

  final String family;
  final List<String> fallbacks;
}

abstract final class AppSystemFonts {
  static AppSystemFontConfig resolve({required TargetPlatform platform, required Locale locale}) {
    return switch (platform) {
      TargetPlatform.linux => AppSystemFontConfig(
        family: 'Noto Sans',
        fallbacks: [
          ..._cjkFallbacks(locale, jp: 'Noto Sans CJK JP', simplified: 'Noto Sans CJK SC', traditional: 'Noto Sans CJK TC'),
          'Noto Color Emoji',
          'Symbola',
        ],
      ),
      TargetPlatform.windows => AppSystemFontConfig(
        family: 'Segoe UI',
        fallbacks: [
          ..._cjkFallbacks(locale, jp: 'Yu Gothic UI', simplified: 'Microsoft YaHei UI', traditional: 'Microsoft JhengHei UI'),
          'Segoe UI Emoji',
          'Segoe UI Symbol',
        ],
      ),
      TargetPlatform.macOS => AppSystemFontConfig(
        family: '.AppleSystemUIFont',
        fallbacks: [
          ..._cjkFallbacks(locale, jp: 'Hiragino Sans', simplified: 'PingFang SC', traditional: 'PingFang TC'),
          'Apple Color Emoji',
        ],
      ),
      TargetPlatform.iOS => AppSystemFontConfig(
        family: 'CupertinoSystemText',
        fallbacks: [
          ..._cjkFallbacks(locale, jp: 'Hiragino Sans', simplified: 'PingFang SC', traditional: 'PingFang TC'),
          'Apple Color Emoji',
        ],
      ),
      TargetPlatform.android || TargetPlatform.fuchsia => AppSystemFontConfig(
        family: 'Roboto',
        fallbacks: [
          ..._cjkFallbacks(locale, jp: 'Noto Sans CJK JP', simplified: 'Noto Sans CJK SC', traditional: 'Noto Sans CJK TC'),
          'Noto Color Emoji',
        ],
      ),
    };
  }

  static List<String> _cjkFallbacks(Locale locale, {required String jp, required String simplified, required String traditional}) {
    if (locale.languageCode == 'ja') {
      return [jp, simplified, traditional];
    }

    if (locale.languageCode == 'zh') {
      final usesTraditional = locale.scriptCode == 'Hant' || const {'HK', 'MO', 'TW'}.contains(locale.countryCode);
      return usesTraditional ? [traditional, simplified, jp] : [simplified, traditional, jp];
    }

    // Pixiv content is predominantly Japanese, so prefer its regional glyphs
    // when the application locale itself does not identify a CJK variant.
    return [jp, simplified, traditional];
  }
}
