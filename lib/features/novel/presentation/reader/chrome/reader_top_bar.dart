import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/novel/logic/novel_marker_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_chrome.dart';
import 'package:frost_ui/frost_ui.dart';

/// The bar over the top of the text: Back, the novel's title with its series
/// and author under it, the Pixiv bookmark and a menu of the rest.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({required this.title, required this.subtitle, required this.onBack, required this.menuEntries, this.marker, super.key});

  final String title;

  /// The series and the author, or the author alone; null when neither is known.
  final String? subtitle;
  final VoidCallback onBack;

  /// The reading bookmark, when the viewer can set one.
  final Widget? marker;
  final List<FrostMenuEntry> menuEntries;

  @override
  Widget build(BuildContext context) {
    final t = context.t.novel.reader;
    return FrostSurface(
      role: FrostSurfaceRole.chrome,
      child: SafeArea(
        bottom: false,
        child: FrostContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostGap.related),
            child: Row(
              spacing: FrostGap.inline,
              children: [
                FrostButton.icon(icon: PivIcons.arrowLeft, label: FrostScope.labelsOf(context).back, onPressed: onBack),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FrostText(title, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        FrostText(
                          subtitle!,
                          content: true,
                          role: FrostTextRole.footnote,
                          tone: FrostTextTone.secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                ?marker,
                FrostMenuAnchor(
                  entries: menuEntries,
                  builder: (context, focusNode, toggle) => Focus(
                    focusNode: focusNode,
                    child: FrostButton.icon(key: const ValueKey('reader-more'), icon: PivIcons.more, label: t.more, onPressed: toggle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top bar in the title row of a page that has the whole window: the same
/// controls on one line, shown while [chrome] wants the top bar and otherwise
/// kept in place, invisible and inert, so the pointer reaching it brings it
/// back. Only the row's own width takes the pointer; the rest of the title row
/// drags the window.
class ReaderTitleRow extends StatefulWidget {
  const ReaderTitleRow({
    required this.chrome,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.menuEntries,
    this.marker,
    super.key,
  });

  /// The most the row takes of the title row, so the rest still drags.
  static const maxWidth = 520.0;

  final ReaderChromeController chrome;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? marker;
  final List<FrostMenuEntry> menuEntries;

  @override
  State<ReaderTitleRow> createState() => _ReaderTitleRowState();
}

class _ReaderTitleRowState extends State<ReaderTitleRow> {
  ReaderChromeController get chrome => widget.chrome;

  // Where the page cannot have the title row (a phone, a bottom bar) the
  // shell lays the row out inside the reader's own area; the top bar there
  // stays with the text and this one stays empty.
  bool _hosted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !ReaderPageScope.contains(context)) {
        _hosted = true;
        chrome.topBarHosted = true;
      }
    });
  }

  @override
  void dispose() {
    if (_hosted) WidgetsBinding.instance.addPostFrameCallback((_) => chrome.topBarHosted = false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ReaderPageScope.contains(context)) return const SizedBox.shrink();
    final widget = this.widget;
    final t = context.t.novel.reader;
    final duration = FrostMotion.duration(context, FrostMotion.reveal);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: ReaderTitleRow.maxWidth),
      child: MouseRegion(
        onEnter: (_) => chrome.topBarEntered(),
        onExit: (_) => chrome.barHovered(false),
        child: ListenableBuilder(
          listenable: chrome,
          builder: (context, _) {
            final visible = chrome.topVisible;
            return IgnorePointer(
              ignoring: !visible,
              child: ExcludeFocus(
                excluding: !visible,
                child: ExcludeSemantics(
                  excluding: !visible,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: duration,
                    child: Row(
                      spacing: FrostGap.inline,
                      children: [
                        FrostButton.icon(icon: PivIcons.arrowLeft, label: FrostScope.labelsOf(context).back, onPressed: widget.onBack),
                        Expanded(
                          child: Row(
                            spacing: FrostGap.related,
                            children: [
                              Flexible(
                                child: FrostText(widget.title, content: true, role: FrostTextRole.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (widget.subtitle != null)
                                Flexible(
                                  child: FrostText(
                                    widget.subtitle!,
                                    content: true,
                                    role: FrostTextRole.footnote,
                                    tone: FrostTextTone.secondary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ?widget.marker,
                        FrostMenuAnchor(
                          entries: widget.menuEntries,
                          builder: (context, focusNode, toggle) => Focus(
                            focusNode: focusNode,
                            child: FrostButton.icon(key: const ValueKey('reader-more'), icon: PivIcons.more, label: t.more, onPressed: toggle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The reading bookmark on Pixiv: one press sets it at the section being
/// read; once set, a menu moves to it, moves it here or removes it.
class ReaderMarkerButton extends ConsumerWidget {
  const ReaderMarkerButton({
    required this.provider,
    required this.enabled,
    required this.currentSection,
    required this.onGoToSection,
    required this.onFailed,
    super.key,
  });

  final NovelMarkerProvider provider;
  final bool enabled;

  /// The 1-based section the reader is in now.
  final int Function() currentSection;
  final ValueChanged<int> onGoToSection;
  final void Function(Object error) onFailed;

  Future<void> _change(WidgetRef ref, Future<void> Function(NovelMarker marker) change) async {
    try {
      await change(ref.read(provider.notifier));
    } catch (error) {
      onFailed(error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.novel.reader;
    final marker = ref.watch(provider);
    final usable = enabled && !marker.updating;
    final page = marker.page;
    if (page == null) {
      return FrostButton.icon(
        key: const ValueKey('reader-marker'),
        icon: PivIcons.bookOpen,
        label: t.markerSet,
        onPressed: usable ? () => unawaited(_change(ref, (marker) => marker.set(currentSection()))) : null,
      );
    }
    return FrostMenuAnchor(
      entries: [
        FrostMenuAction(t.markerJump(page: page), onSelected: usable ? () => onGoToSection(page) : null),
        FrostMenuAction(t.markerUpdate, onSelected: usable ? () => unawaited(_change(ref, (marker) => marker.set(currentSection()))) : null),
        FrostMenuAction(t.markerRemove, destructive: true, onSelected: usable ? () => unawaited(_change(ref, (marker) => marker.remove())) : null),
      ],
      builder: (context, focusNode, toggle) => FrostButton.icon(
        key: const ValueKey('reader-marker'),
        icon: PivIcons.bookOpen,
        label: t.markerMenu,
        selected: true,
        onPressed: enabled ? toggle : null,
      ),
    );
  }
}
