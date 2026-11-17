// app-owned: novel reader text
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:frost_ui/frost_ui.dart';

/// Everything the reader needs to set its text: sizes, gaps, fonts and
/// colours. Measurement and rendering read the same values, so a paragraph
/// is as tall on screen as the layout expects.
@immutable
class ReaderTypesetting {
  const ReaderTypesetting({
    required this.textSize,
    required this.lineHeight,
    this.textScaler = TextScaler.noScaling,
    required this.body,
    required this.chapterTitle,
    this.rubyScale = 0.5,
    this.indent = true,
    this.margins = ReaderMargins.regular,
    required this.palette,
    this.locale,
    this.joinsHangul = false,
  });

  /// The typesetting of [settings] in this context: the app's body font (or a
  /// system serif or kai list), the theme's palette and the platform text
  /// scale. [language] is the novel's language tag and picks the font list
  /// and the locale glyph shaping follows.
  factory ReaderTypesetting.of(BuildContext context, ReaderSettings settings, {String? language}) {
    final palette = ReaderPalette.of(context, settings.theme);
    final base = FrostTypography.of(context).style(FrostTextRole.body);
    final script = _scriptOf(language);
    final families = _fontFamilies(settings.font, script);
    final appFamilies = [?base.fontFamily, ...?base.fontFamilyFallback];
    final face = families == null ? base : base.copyWith(fontFamily: families.first, fontFamilyFallback: [...families.skip(1), ...appFamilies]);
    final body = face.copyWith(fontSize: settings.textSize, height: settings.lineSpacing.lineHeight, color: palette.text);
    return ReaderTypesetting(
      textSize: settings.textSize,
      lineHeight: settings.lineSpacing.lineHeight,
      textScaler: MediaQuery.textScalerOf(context),
      body: body,
      chapterTitle: body.copyWith(fontSize: settings.textSize * chapterScale, fontWeight: FontWeight.w600, height: chapterLineHeight),
      indent: settings.indent,
      margins: settings.margins,
      palette: palette,
      locale: switch (script) {
        _Script.zh => const Locale('zh'),
        _Script.ja => const Locale('ja'),
        _Script.ko => const Locale('ko'),
        _Script.other => null,
      },
      joinsHangul: script == _Script.ko,
    );
  }

  /// Chapter titles stand this much above the body size.
  static const chapterScale = 1.3;
  static const chapterLineHeight = 1.4;

  /// A text column never holds more than this many glyphs of the body size.
  static const maxColumnGlyphs = 36;

  final double textSize;

  /// Line height as a multiple of [textSize].
  final double lineHeight;

  /// Applied identically when measuring and rendering.
  final TextScaler textScaler;
  final TextStyle body;
  final TextStyle chapterTitle;

  /// Ruby readings are this share of the body size.
  final double rubyScale;

  /// Whether lines the author did not indent start with an ideographic space.
  final bool indent;
  final ReaderMargins margins;
  final ReaderPalette palette;
  final Locale? locale;

  /// Whether Korean lines break only at spaces: consecutive Hangul characters
  /// are joined, which no line break can split.
  final bool joinsHangul;

  double get _scaledSize => textScaler.scale(textSize);

  double get bodyLinePx => _scaledSize * lineHeight;
  double get paragraphGap => _scaledSize * 0.35;

  /// Space for each blank line the author left beyond the first; the layout counts at most three.
  double get blankLinePx => bodyLinePx;
  double get chapterTopGap => 2 * bodyLinePx;
  double get chapterBottomGap => bodyLinePx;

  /// The divider a page break shows in the scroll layout; the paged layout
  /// turns the page instead and gives it no extent.
  double get pageBreakExtent => 2 * bodyLinePx;

  /// The embedded work card is built to fit this height.
  double get embeddedWorkExtent => 112;

  double get horizontalPadding => switch (margins) {
    ReaderMargins.narrow => 16,
    ReaderMargins.regular => 28,
    ReaderMargins.wide => 48,
  };

  /// The text column for an available [width]: the width less the margins,
  /// at most [maxColumnGlyphs] glyphs of the body size.
  double columnWidth(double width) => math.max(0, math.min(width - 2 * horizontalPadding, _scaledSize * maxColumnGlyphs));
}

/// The colours of a reading theme.
@immutable
class ReaderPalette {
  const ReaderPalette({required this.background, required this.text, required this.secondary, required this.link, required this.ruby, required this.selection});

  final Color background, text, secondary, link, ruby, selection;

  /// [ReaderTheme.app] follows the Frost theme; the other themes are fixed
  /// reading colours, each link colour at least 4.5:1 on its background.
  static ReaderPalette of(BuildContext context, ReaderTheme theme) {
    if (theme == ReaderTheme.app) {
      final tokens = FrostThemeTokens.of(context);
      final link = tokens.accentInk;
      return ReaderPalette(
        background: tokens.surface,
        text: tokens.textPrimary,
        secondary: tokens.textSecondary,
        link: link,
        ruby: tokens.textPrimary.withValues(alpha: .75),
        selection: link.withValues(alpha: .3),
      );
    }
    final (:background, :text, :link) = switch (theme) {
      ReaderTheme.white => ReaderThemeColors.white,
      ReaderTheme.paper => ReaderThemeColors.paper,
      ReaderTheme.green => ReaderThemeColors.green,
      ReaderTheme.night => ReaderThemeColors.night,
      ReaderTheme.black || ReaderTheme.app => ReaderThemeColors.black,
    };
    return ReaderPalette(
      background: background,
      text: text,
      secondary: text.withValues(alpha: .6),
      link: link,
      ruby: text.withValues(alpha: .75),
      selection: link.withValues(alpha: .3),
    );
  }
}

/// The colours of the fixed reading themes: background, body text and link.
///
/// They are the reading surface's own colours, chosen for long reading rather
/// than taken from the Frost theme, which only [ReaderTheme.app] follows. Each
/// link is at least 4.5:1 on its background: 6.7, 6.3, 5.8, 7.4 and 8.3 to 1
/// in the order below. Secondary text, ruby and selection derive from these.
abstract final class ReaderThemeColors {
  static const white = (background: Color.fromARGB(255, 255, 255, 255), text: Color.fromARGB(255, 31, 31, 31), link: Color.fromARGB(255, 11, 92, 173));
  static const paper = (background: Color.fromARGB(255, 244, 236, 216), text: Color.fromARGB(255, 59, 51, 38), link: Color.fromARGB(255, 122, 74, 18));
  static const green = (background: Color.fromARGB(255, 204, 230, 207), text: Color.fromARGB(255, 34, 48, 31), link: Color.fromARGB(255, 34, 87, 122));
  static const night = (background: Color.fromARGB(255, 28, 31, 36), text: Color.fromARGB(255, 185, 190, 198), link: Color.fromARGB(255, 127, 178, 229));
  static const black = (background: Color.fromARGB(255, 0, 0, 0), text: Color.fromARGB(255, 160, 164, 169), link: Color.fromARGB(255, 111, 168, 220));
}

enum _Script { zh, ja, ko, other }

_Script _scriptOf(String? language) {
  final tag = language?.toLowerCase() ?? '';
  if (tag.startsWith('zh')) return _Script.zh;
  if (tag.startsWith('ja')) return _Script.ja;
  if (tag.startsWith('ko')) return _Script.ko;
  return _Script.other;
}

const _serifZh = ['Noto Serif CJK SC', 'Source Han Serif SC', 'Songti SC', 'STSong', 'SimSun'];
const _serifJa = ['Noto Serif CJK JP', 'Source Han Serif JP', 'Hiragino Mincho ProN', 'Yu Mincho', 'MS Mincho'];
const _serifKo = ['Noto Serif CJK KR', 'Source Han Serif K', 'AppleMyungjo', 'Batang', 'Malgun Gothic'];
const _kai = ['Kaiti SC', 'STKaiti', 'KaiTi', 'BiauKai'];

/// System font families for [font], first choice first; null keeps the app's
/// body font. Nothing is bundled: a missing family falls through to the next
/// and finally to the app font.
List<String>? _fontFamilies(ReaderFont font, _Script script) {
  final serif = switch (script) {
    _Script.ja => _serifJa,
    _Script.ko => _serifKo,
    _ => _serifZh,
  };
  return switch (font) {
    ReaderFont.sans => null,
    ReaderFont.serif => serif,
    ReaderFont.kai => [..._kai, ...serif],
  };
}
