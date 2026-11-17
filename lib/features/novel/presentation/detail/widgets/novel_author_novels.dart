import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/loading_section.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The author's other novels, with the way to their page.
class NovelAuthorNovels extends ConsumerWidget {
  const NovelAuthorNovels({required this.novel, super.key});

  final Novel novel;

  static const shown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final provider = novelUserWorksProvider(novel.user.id);
    return AppLoadingSection(
      title: t.novelDetail.authorNovels,
      value: ref.watch(provider),
      onRetry: () => unawaited(ref.read(provider.notifier).reload()),
      failed: t.illust.works.failed,
      skeleton: const AppNovelRowsSkeleton(count: shown, showAuthor: false, tall: true),
      action: FrostButton.quiet(label: t.home.seeMore, onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.user(novel.user.id)))),
      builder: (page) {
        final others = page.novels.where((other) => other.id != novel.id).take(shown).toList();
        if (others.isEmpty) return FrostText(t.illust.works.empty, role: FrostTextRole.footnote, tone: FrostTextTone.secondary);
        return Column(children: [for (final other in others) AppNovelRow(novel: other, showAuthor: false)]);
      },
    );
  }
}
