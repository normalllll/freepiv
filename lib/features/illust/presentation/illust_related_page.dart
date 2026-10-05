import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/illust/logic/illust_detail_logic.dart';
import 'package:freepiv/features/illust/presentation/widgets/illust_related_waterfall.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/artwork_hero.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:go_router/go_router.dart';

class IllustRelatedPage extends ConsumerStatefulWidget {
  const IllustRelatedPage({required this.illustId, this.sourceIllust, super.key});

  final int illustId;
  final Illust? sourceIllust;

  @override
  ConsumerState<IllustRelatedPage> createState() => _IllustRelatedPageState();
}

class _IllustRelatedPageState extends ConsumerState<IllustRelatedPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final source = ref.read(illustRelatedWorksProvider(widget.illustId));
      if (!source.initialized && !source.refreshing) source.refresh(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(illustRelatedWorksProvider(widget.illustId));
    final desktop = FrostAutoScaffold.usesHorizontalLayoutOf(context);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: IllustRelatedWaterfallView(
          source: source,
          sourceIllust: widget.sourceIllust,
          currentIllustId: widget.illustId,
          topPadding: 16,
          onIllustTap: _openIllust,
          headerSliver: desktop
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverAppBar(
                  // Collapses while the list scrolls on and returns on the way back.
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: const FrostPinnedChromeGlass(opacity: 1),
                  automaticallyImplyLeading: false,
                  leading: FrostPageHeader.leadingFor(context, onBack: _goBack),
                  leadingWidth: FrostPageHeader.leadingWidth,
                  titleSpacing: FrostPageHeader.titleSpacingOf(context, onBack: _goBack),
                  title: Text(context.t.illust.section.relatedWorks),
                ),
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.illustDetail.name, pathParameters: {'id': '${widget.illustId}'});
    }
  }

  void _openIllust(Illust illust, ArtworkHeroTag heroTag) => openIllustDetail(context, illust, heroTag);
}
