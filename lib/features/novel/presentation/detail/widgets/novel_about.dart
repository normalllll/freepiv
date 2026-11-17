import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/ui/compositions/tag_menu.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The caption and the tags, which search novels; a novel with neither leaves
/// nothing.
class NovelAbout extends StatelessWidget {
  const NovelAbout({required this.novel, required this.caption, super.key});

  final Novel novel;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final source = caption?.trim().isNotEmpty ?? false ? caption! : novel.caption;
    final text = plainTextFromHtml(source).trim();
    if (text.isEmpty && novel.tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostGap.group,
      children: [
        if (text.isNotEmpty) AppPixivText(source),
        if (novel.tags.isNotEmpty)
          FrostWrap(
            children: [
              for (final tag in novel.tags)
                FrostTag(
                  label: '#${tag.name}',
                  detail: tag.translatedName,
                  style: FrostTagStyle.topic,
                  onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.tagSearch(tag.name, kind: AppSearchKind.novel))),
                  contextMenu: workTagMenu(context, tag.name),
                ),
            ],
          ),
      ],
    );
  }
}
