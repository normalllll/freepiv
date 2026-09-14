import 'package:flutter/material.dart';
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
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
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
                  final width = (constraints.maxWidth * .82).clamp(0.0, 280.0);
                  final height = PixivisionCard.previewHeight(context, width);
                  return SizedBox(
                    height: height,
                    child: switch ((articles, state.hasError)) {
                      (null, true) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(context.t.pixivision.requestFailed),
                            const SizedBox(height: 8),
                            TextButton(onPressed: () => ref.invalidate(provider), child: Text(context.t.common.retry)),
                          ],
                        ),
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
      ),
    );
  }
}
