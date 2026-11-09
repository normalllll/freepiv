import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/series/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The row on a work's page leading to the series it belongs to.
class AppSeriesLink extends StatelessWidget {
  const AppSeriesLink({required this.kind, required this.seriesId, required this.title, super.key});

  final AppSeriesKind kind;
  final int seriesId;
  final String title;

  @override
  Widget build(BuildContext context) => FrostListRow(
    leading: const FrostGlyph.icon(PivIcons.bookOpen),
    title: context.t.series.link(title: title),
    contentTitle: true,
    accessory: FrostRowAccessory.chevron,
    onPressed: () => unawaited(GoRouter.of(context).push(AppLocations.series(kind, seriesId))),
  );
}

/// Follow up on a series: solid until followed, then "Following up".
class AppSeriesWatchButton extends ConsumerWidget {
  const AppSeriesWatchButton({required this.kind, required this.seriesId, required this.watched, super.key});

  final AppSeriesKind kind;
  final int seriesId;
  final bool watched;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder(
    valueListenable: pixivAccountNotifier,
    builder: (context, account, _) {
      final t = context.t.series;
      final accountId = account?.user.id;
      final provider = seriesWatchProvider(SeriesWatchArgs(accountId: accountId, kind: kind, seriesId: seriesId, watched: watched));
      final state = ref.watch(provider);
      Future<void> toggle() async {
        try {
          await ref.read(provider.notifier).toggle();
        } catch (error) {
          if (pixivAccountNotifier.value?.user.id == accountId) toastErrorWithCause(t.watchFailed, error);
        }
      }

      final onPressed = state.updating || accountId == null ? null : () => unawaited(toggle());
      return state.watched ? FrostButton.tinted(label: t.watching, onPressed: onPressed) : FrostButton.prominent(label: t.watch, onPressed: onPressed);
    },
  );
}
