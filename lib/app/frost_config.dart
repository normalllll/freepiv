import 'package:flutter/widgets.dart';
import 'package:freepiv/app/icons.g.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

/// The icons Frost's own components draw, from the app's Lucide icon font.
const freepivFrostIcons = FrostIconSet(
  back: PivIcons.arrowLeft,
  forward: FrostIconData.glyph(FreepivIcons.arrowRight),
  close: PivIcons.close,
  more: PivIcons.more,
  chevronLeft: FrostIconData.glyph(FreepivIcons.chevronLeft),
  chevronRight: FrostIconData.glyph(FreepivIcons.chevronRight),
  chevronUp: FrostIconData.glyph(FreepivIcons.chevronUp),
  chevronDown: FrostIconData.glyph(FreepivIcons.chevronDown),
  arrowDown: FrostIconData.glyph(FreepivIcons.arrowDown),
  chevronUpDown: FrostIconData.glyph(FreepivIcons.chevronsUpDown),
  expand: FrostIconData.glyph(FreepivIcons.chevronDown),
  collapse: FrostIconData.glyph(FreepivIcons.chevronUp),
  sidebarExpand: FrostIconData.glyph(FreepivIcons.panelLeftOpen),
  sidebarCollapse: FrostIconData.glyph(FreepivIcons.panelLeftClose),
  externalLink: PivIcons.externalLink,
  link: FrostIconData.glyph(FreepivIcons.link),
  search: PivIcons.search,
  refresh: PivIcons.refreshCw,
  copy: PivIcons.copy,
  share: FrostIconData.glyph(FreepivIcons.share2),
  download: PivIcons.download,
  upload: FrostIconData.glyph(FreepivIcons.upload),
  delete: FrostIconData.glyph(FreepivIcons.trash),
  edit: FrostIconData.glyph(FreepivIcons.squarePen),
  add: FrostIconData.glyph(FreepivIcons.plus),
  remove: FrostIconData.glyph(FreepivIcons.minus),
  filter: FrostIconData.glyph(FreepivIcons.listFilter),
  sort: FrostIconData.glyph(FreepivIcons.arrowDownUp),
  check: FrostIconData.glyph(FreepivIcons.check),
  dragHandle: FrostIconData.glyph(FreepivIcons.gripVertical),
  success: FrostIconData.glyph(FreepivIcons.circleCheck),
  info: PivIcons.info,
  error: FrostIconData.glyph(FreepivIcons.circleAlert),
  empty: FrostIconData.glyph(FreepivIcons.inbox),
  play: FrostIconData.glyph(FreepivIcons.play),
  pause: FrostIconData.glyph(FreepivIcons.pause),
  repeat: FrostIconData.glyph(FreepivIcons.repeat),
  volumeOn: FrostIconData.glyph(FreepivIcons.volume2),
  volumeOff: FrostIconData.glyph(FreepivIcons.volumeX),
  fullscreen: FrostIconData.glyph(FreepivIcons.maximize),
  exitFullscreen: FrostIconData.glyph(FreepivIcons.minimize),
  zoomIn: FrostIconData.glyph(FreepivIcons.zoomIn),
  zoomOut: FrostIconData.glyph(FreepivIcons.zoomOut),
  image: FrostIconData.glyph(FreepivIcons.image),
  imageError: FrostIconData.glyph(FreepivIcons.imageOff),
  multiPage: FrostIconData.glyph(FreepivIcons.images),
  minimize: FrostIconData.glyph(FreepivIcons.minus),
  maximize: FrostIconData.glyph(FreepivIcons.square),
  restore: PivIcons.copy,
  calendar: FrostIconData.glyph(FreepivIcons.calendarDays),
  clock: FrostIconData.glyph(FreepivIcons.clock),
  folder: FrostIconData.glyph(FreepivIcons.folder),
  eye: FrostIconData.glyph(FreepivIcons.eye),
  eyeOff: FrostIconData.glyph(FreepivIcons.eyeOff),
  user: PivIcons.user,
  textFormat: FrostIconData.glyph(FreepivIcons.type),
);

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
  icons: freepivFrostIcons,
  labels: freepivFrostLabels,
  errors: FrostErrorPresenter(message: (context, error) => formatPixivError(error), details: pixivErrorDetails),
);

FrostLabels freepivFrostLabels(BuildContext context) {
  // Follows the TranslationProvider when present so a locale switch rebuilds
  // the labels; widgets built outside it use the global locale.
  final t =
      context.dependOnInheritedWidgetOfExactType<InheritedLocaleData<AppLocale, Translations>>()?.translations ?? LocaleSettings.instance.currentTranslations;
  final labels = t.frost;
  return FrostLabels(
    retry: labels.retry,
    retryAfter: (seconds) => labels.retryAfter(seconds: formatCount(seconds)),
    error: labels.error,
    errorDetails: labels.errorDetails,
    copyDetails: labels.copyDetails,
    copied: labels.copied,
    loading: labels.loading,
    actionSucceeded: labels.actionSucceeded,
    actionFailed: labels.actionFailed,
    loadFailed: labels.loadFailed,
    noMoreItems: labels.noMoreItems,
    noItems: labels.noItems,
    pullToRefresh: labels.pullToRefresh,
    releaseToRefresh: labels.releaseToRefresh,
    refreshing: labels.refreshing,
    refreshComplete: labels.refreshComplete,
    refreshFailed: labels.refreshFailed,
    previous: labels.previous,
    next: labels.next,
    back: labels.back,
    more: labels.more,
    expandNavigation: labels.expandNavigation,
    collapseNavigation: labels.collapseNavigation,
    navigationStatus: (count, progressPercent) => [
      if (count > 0) labels.navigationCount(count: formatCount(count)),
      if (progressPercent != null) labels.navigationProgress(progress: formatCount(progressPercent)),
    ].join(labels.listSeparator),
    clearText: labels.clearText,
    search: labels.search,
    noResults: (query) => labels.noResults(query: query),
    clearSearch: labels.clearSearch,
    dismiss: labels.dismiss,
    expandText: labels.expandText,
    collapseText: labels.collapseText,
    showAll: labels.showAll,
    copy: labels.copy,
    clearAll: labels.clearAll,
    showPassword: labels.showPassword,
    hidePassword: labels.hidePassword,
    chooseDate: labels.chooseDate,
    chooseTime: labels.chooseTime,
    increment: labels.increment,
    decrement: labels.decrement,
    reorderHandle: labels.reorderHandle,
    sortAscending: labels.sortAscending,
    sortDescending: labels.sortDescending,
    play: labels.play,
    pause: labels.pause,
    loop: labels.loop,
    mute: labels.mute,
    unmute: labels.unmute,
    fullscreen: labels.fullscreen,
    exitFullscreen: labels.exitFullscreen,
    minimize: labels.minimize,
    maximize: labels.maximize,
    restore: labels.restore,
    close: labels.close,
    cancel: labels.cancel,
    apply: labels.apply,
    clear: labels.clear,
    choose: labels.choose,
    showInFolder: labels.showInFolder,
    selectedCount: (count) => labels.selectedCount(count: formatCount(count)),
    pageOf: (page, total) => labels.pageOf(page: formatCount(page), total: formatCount(total)),
    selectAll: labels.selectAll,
    done: labels.done,
    itemPosition: (position, total) => labels.itemPosition(position: formatCount(position), total: formatCount(total)),
    tableDimensions: (rows, columns) => labels.tableDimensions(rows: formatCount(rows), columns: formatCount(columns)),
    taskQueued: labels.taskQueued,
    taskRunning: labels.taskRunning,
    taskPaused: labels.taskPaused,
    taskCompleted: labels.taskCompleted,
    taskFailed: labels.taskFailed,
    taskCancelled: labels.taskCancelled,
    remove: labels.remove,
    seek: labels.seek,
    showReplies: (count) => labels.showReplies(count: formatCount(count)),
    moreMedia: (count) => labels.moreMedia(count: formatCount(count)),
  );
}

/// The app's icons by meaning, from the bundled Lucide icon font (ISC).
abstract final class PivIcons {
  static const home = FrostIconData.glyph(FreepivIcons.house);
  static const compass = FrostIconData.glyph(FreepivIcons.compass);
  static const activity = FrostIconData.glyph(FreepivIcons.activity);
  static const user = FrostIconData.glyph(FreepivIcons.userRound);
  static const more = FrostIconData.glyph(FreepivIcons.ellipsis);
  static const heart = FrostIconData.glyph(FreepivIcons.heart);
  static const heartFilled = FrostIconData.glyph(FreepivIcons.heartFilled);
  static const newspaper = FrostIconData.glyph(FreepivIcons.newspaper);
  static const download = FrostIconData.glyph(FreepivIcons.download);
  static const settings = FrostIconData.glyph(FreepivIcons.settings);
  static const info = FrostIconData.glyph(FreepivIcons.info);
  static const code = FrostIconData.glyph(FreepivIcons.code);
  static const send = FrostIconData.glyph(FreepivIcons.send);
  static const messageCircle = FrostIconData.glyph(FreepivIcons.messageCircle);
  static const externalLink = FrostIconData.glyph(FreepivIcons.externalLink);
  static const refreshCw = FrostIconData.glyph(FreepivIcons.refreshCw);
  static const arrowLeft = FrostIconData.glyph(FreepivIcons.arrowLeft);
  static const close = FrostIconData.glyph(FreepivIcons.x);
  static const copy = FrostIconData.glyph(FreepivIcons.copy);
  static const search = FrostIconData.glyph(FreepivIcons.search);
  static const link = FrostIconData.glyph(FreepivIcons.link);
  static const tags = FrostIconData.glyph(FreepivIcons.tags);
  static const users = FrostIconData.glyph(FreepivIcons.userRound);
  static const trash = FrostIconData.glyph(FreepivIcons.trash);
  static const images = FrostIconData.glyph(FreepivIcons.images);
  static const folder = FrostIconData.glyph(FreepivIcons.folder);
  static const play = FrostIconData.glyph(FreepivIcons.play);
  static const pause = FrostIconData.glyph(FreepivIcons.pause);
  static const clock = FrostIconData.glyph(FreepivIcons.clock);
  static const eye = FrostIconData.glyph(FreepivIcons.eye);
  static const smile = FrostIconData.glyph(FreepivIcons.smile);
  static const bookOpen = FrostIconData.glyph(FreepivIcons.bookOpen);
  static const history = FrostIconData.glyph(FreepivIcons.history);
  static const chevronLeft = FrostIconData.glyph(FreepivIcons.chevronLeft);
  static const chevronRight = FrostIconData.glyph(FreepivIcons.chevronRight);
  static const image = FrostIconData.glyph(FreepivIcons.image);
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

