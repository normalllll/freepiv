import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:freepiv/shared/widgets/compact_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/features/pixivision/logic.dart';
import 'package:freepiv/features/pixivision/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:go_router/go_router.dart';

class DiscoveryPixivisionPreview extends ConsumerWidget {
  const DiscoveryPixivisionPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = pixivisionLanguagePath(context.t.$meta.locale);
    final provider = pixivisionBrowseProvider('https://www.pixivision.net/$language/');
    final state = ref.watch(provider);
    final page = state.value?.page;
    final articles = switch (page) {
      null => null,
      final page when page.recommended.isNotEmpty => page.recommended.take(3).toList(),
      final page => page.articles.take(3).toList(),
    };
    return ContentColumn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(context.t.pixivision.title, style: Theme.of(context).textTheme.titleMedium)),
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final selection = ref.read(pixivisionBrowseSelectionProvider);
                    context.push(Uri(path: '/pixivision/browse', queryParameters: {if (selection.url != null) 'url': selection.url!}).toString());
                  },
                  child: Text(context.t.discover.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                // The three previews share the row when each can stay at
                // least 160 wide (including the narrower wide-window column);
                // otherwise the row scrolls and the next card peeks in.
                final fitted = (constraints.maxWidth - 24) / 3;
                final width = fitted >= 160 ? fitted : (constraints.maxWidth * .82).clamp(0.0, 280.0);
                final height = PixivisionCard.previewHeight(context, width);
                return SizedBox(
                  height: height,
                  child: switch ((articles, state.hasError)) {
                    (null, true) => SingleChildScrollView(
                      child: CompactMessage.error(error: state.error!, onAction: () => ref.invalidate(provider)),
                    ),
                    (final items?, _) when items.isEmpty => Center(child: Text(context.t.pixivision.empty)),
                    _ => ListView.separated(
                      key: const PageStorageKey('discover-pixivision'),
                      scrollDirection: Axis.horizontal,
                      itemCount: articles?.length ?? 3,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: width,
                        child: PixivisionCard.preview(article: articles?[index]),
                      ),
                    ),
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
