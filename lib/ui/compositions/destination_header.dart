import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

/// The header of a destination's root page (Home, Newest): the page title
/// while the title row holds the search; otherwise the way to Me and to
/// search, as on Home.
class AppDestinationHeader extends ConsumerWidget {
  const AppDestinationHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    if (FrostShell.titleContentInCaptionOf(context)) return FrostPageHeader(title: FrostText(title));
    final account = pixivAccountNotifier.value?.user;
    final avatarUrl = account?.profileImageUrls.px170X170 ?? '';
    return FrostPageHeader(
      title: FrostText(title),
      leading: [
        if (account != null)
          Semantics(
            button: true,
            label: t.navigation.me,
            excludeSemantics: true,
            child: FrostClickSurface(
              shape: const FrostClickShape.circle(),
              onTap: () => GoRouter.of(context).go(AppRoute.me.path),
              child: FrostAvatar.person(
                name: account.name,
                colorKey: account.id,
                size: FrostAvatarSize.small,
                image: avatarUrl.isEmpty ? null : pixivImageProvider(ref, avatarUrl),
              ),
            ),
          ),
      ],
      middle: FrostSearchEntry(
        key: const ValueKey('home-search-entry'),
        placeholder: t.appSearch.placeholder,
        onPressed: () => openAppSearch(ref, GoRouter.of(context)),
      ),
    );
  }
}
