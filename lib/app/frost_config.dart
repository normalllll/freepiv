import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// freepiv's choices for the shared Frost design language: the pink palettes,
/// the bundled Noto subsets, its icons and its localized texts.
final freepivFrostConfig = FrostConfig(
  palettes: FrostPalettes.pink,
  fonts: const FrostFonts(
    japanese: 'Noto Sans JP',
    simplifiedChinese: 'Noto Sans SC',
    // Pixiv content is predominantly Japanese, so its regional glyphs are
    // preferred when neither the locale nor the text identifies a variant.
    defaultScript: FrostContentScript.japanese,
  ),
  icons: const FrostIconSet(
    back: PivIcons.arrowLeft,
    close: FrostIconData.glyph(Icons.close_rounded),
    more: PivIcons.more,
    expand: FrostIconData.glyph(Icons.expand_more),
    collapse: FrostIconData.glyph(Icons.expand_less),
    chevronLeft: FrostIconData.glyph(Icons.chevron_left_rounded),
    chevronRight: FrostIconData.glyph(Icons.chevron_right_rounded),
    chevronDown: FrostIconData.glyph(Icons.keyboard_arrow_down_rounded),
    refresh: FrostIconData.glyph(Icons.refresh),
    copy: FrostIconData.glyph(Icons.content_copy_outlined),
    search: FrostIconData.glyph(Icons.search),
    check: FrostIconData.glyph(Icons.check_rounded),
    success: FrostIconData.glyph(Icons.check_circle_outline),
    info: FrostIconData.glyph(Icons.info_outline_rounded),
    warning: FrostIconData.glyph(Icons.warning_amber_rounded),
    error: FrostIconData.glyph(Icons.error_outline),
    empty: FrostIconData.glyph(Icons.inbox_outlined),
    sidebarExpand: FrostIconData.glyph(Icons.keyboard_double_arrow_right_rounded),
    sidebarCollapse: FrostIconData.glyph(Icons.keyboard_double_arrow_left_rounded),
  ),
  labels: _labels,
  errors: FrostErrorPresenter(message: (context, error) => formatPixivError(error), details: pixivErrorDetails),
);

FrostLabels _labels(BuildContext context) {
  // Follows the TranslationProvider when present so a locale switch rebuilds
  // the labels; widgets built outside it use the global locale.
  final t =
      context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<AppLocale, Translations>>()?.translations ?? LocaleSettings.instance.currentTranslations;
  final material = MaterialLocalizations.of(context);
  return FrostLabels(
    retry: t.common.retry,
    error: t.common.error,
    errorDetails: t.common.errorDetails,
    copyDetails: t.common.copyDetails,
    detailsCopied: t.common.detailsCopied,
    loading: t.refresh.loading,
    loadFailed: t.refresh.loadFailed,
    noMoreItems: t.refresh.noMoreItems,
    pullToRefresh: t.refresh.pullToRefresh,
    releaseToRefresh: t.refresh.releaseToRefresh,
    refreshing: t.refresh.refreshing,
    refreshComplete: t.refresh.refreshComplete,
    refreshFailed: t.refresh.refreshFailed,
    previous: t.illust.tooltip.previousImage,
    next: t.illust.tooltip.nextImage,
    back: material.backButtonTooltip,
    more: t.navigation.more,
    expandNavigation: t.navigation.expand,
    collapseNavigation: t.navigation.collapse,
    clearText: material.deleteButtonTooltip,
    search: material.searchFieldLabel,
    dismiss: material.closeButtonTooltip,
  );
}

/// The bundled Lucide icons (assets/icons, ISC).
abstract final class PivIcons {
  static const home = FrostIconData.svg('assets/icons/house.svg');
  static const compass = FrostIconData.svg('assets/icons/compass.svg');
  static const activity = FrostIconData.svg('assets/icons/activity.svg');
  static const user = FrostIconData.svg('assets/icons/user-round.svg');
  static const more = FrostIconData.svg('assets/icons/ellipsis.svg');
  static const heart = FrostIconData.svg('assets/icons/heart.svg');
  static const heartFilled = FrostIconData.svg('assets/icons/heart-filled.svg');
  static const newspaper = FrostIconData.svg('assets/icons/newspaper.svg');
  static const download = FrostIconData.svg('assets/icons/download.svg');
  static const settings = FrostIconData.svg('assets/icons/settings.svg');
  static const info = FrostIconData.svg('assets/icons/info.svg');
  static const code = FrostIconData.svg('assets/icons/code.svg');
  static const send = FrostIconData.svg('assets/icons/send.svg');
  static const messageCircle = FrostIconData.svg('assets/icons/message-circle.svg');
  static const externalLink = FrostIconData.svg('assets/icons/external-link.svg');
  static const refreshCw = FrostIconData.svg('assets/icons/refresh-cw.svg');
  static const arrowLeft = FrostIconData.svg('assets/icons/arrow-left.svg', mirrorInRtl: true);
  static const close = FrostIconData.svg('assets/icons/x.svg');
  static const copy = FrostIconData.svg('assets/icons/copy.svg');
}

/// freepiv's own sizes, outside the shared design values.
abstract final class PivMetrics {
  static const novelCoverWidth = 82.0;
  static const novelCoverHeight = 116.0;
  static const contentTypeSegmentWidth = 120.0;
  static const artworkFooterPadding = EdgeInsets.fromLTRB(10, 8, 8, 8);
}

/// An error toast naming the action that failed and its one-line, localized
/// cause. Technical detail stays out of toasts; it lives in the collapsed
/// error details.
void toastErrorWithCause(String message, Object error) => FrostToast.error(t.common.errorWithCause(message: message, cause: formatPixivError(error)));

/// freepiv's theme: the Frost theme built from [freepivFrostConfig].
abstract final class AppTheme {
  static ThemeData light({required TargetPlatform platform, required Locale locale, FrostTone tone = FrostTone.neutral, Color? accent}) =>
      FrostTheme.build(config: freepivFrostConfig, brightness: Brightness.light, platform: platform, locale: locale, tone: tone, accent: accent);

  static ThemeData dark({required TargetPlatform platform, required Locale locale, FrostTone tone = FrostTone.neutral, Color? accent}) =>
      FrostTheme.build(config: freepivFrostConfig, brightness: Brightness.dark, platform: platform, locale: locale, tone: tone, accent: accent);
}
