import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/sectioned_page.dart';
import 'package:frost_data/frost_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// The modes a ranking of [kind] offers, in menu order.
List<Enum> rankingModes(AppRankingKind kind) => switch (kind) {
  AppRankingKind.illust => IllustRankingMode.values,
  AppRankingKind.manga => MangaRankingMode.values,
  AppRankingKind.novel => NovelRankingMode.values,
};

/// Whether [mode] ranks R-18 works; those sit in their own menu section.
bool rankingModeIsR18(Enum mode) => mode.name.contains('R18');

String rankingModeLabel(Translations t, Enum mode) => switch (mode.name) {
  'dayR18' => t.ranking.modes.dayR18,
  'dayMale' => t.ranking.modes.dayMale,
  'dayMaleR18' => t.ranking.modes.dayMaleR18,
  'dayFemale' => t.ranking.modes.dayFemale,
  'dayFemaleR18' => t.ranking.modes.dayFemaleR18,
  'dayAi' => t.ranking.modes.dayAi,
  'dayR18Ai' => t.ranking.modes.dayR18Ai,
  'week' => t.ranking.modes.week,
  'weekR18' => t.ranking.modes.weekR18,
  'weekR18G' => t.ranking.modes.weekR18G,
  'weekOriginal' => t.ranking.modes.weekOriginal,
  'weekRookie' => t.ranking.modes.weekRookie,
  'month' => t.ranking.modes.month,
  _ => t.ranking.modes.day,
};

/// The ranking: illustrations, manga and novels as
/// sections, the mode in the title menu. Each kind keeps its mode for the
/// session ([rankingProvider]); a mode the route names wins for its kind.
/// Moving to another kind takes the mode along where that kind has it.
/// Every kind and mode loads, fails and empties on its own.
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({required this.kind, this.mode, super.key});

  final AppRankingKind kind;

  /// The route's mode, used when it names one of [kind]'s modes.
  final String? mode;

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: AppRankingKind.values.length,
    initialIndex: widget.kind.index,
    animationDuration: FrostMotion.navigation,
    vsync: this,
  )..addListener(_kindChanged);

  /// The kind shown last; the kind shown next takes its mode where it has it.
  late AppRankingKind _shown = widget.kind;

  /// Each kind's mode; the shown kind's is the page's mode.
  late final _modes = {for (final kind in AppRankingKind.values) kind: _named(kind, kind == widget.kind ? widget.mode : null) ?? _remembered(kind)};

  Enum get _mode => _modes[_kind]!;

  AppRankingKind get _kind => AppRankingKind.values[_tabs.index];

  /// [name] as one of [kind]'s modes, if it is one.
  static Enum? _named(AppRankingKind kind, String? name) => rankingModes(kind).where((mode) => mode.name == name).firstOrNull;

  /// The mode [kind] was last shown in this session.
  Enum _remembered(AppRankingKind kind) {
    final state = ref.read(rankingProvider);
    return switch (kind) {
      AppRankingKind.illust => state.illustMode,
      AppRankingKind.manga => state.mangaMode,
      AppRankingKind.novel => state.novelMode,
    };
  }

  /// Keeps [mode] as its kind's mode for the session.
  void _remember(Enum mode) {
    final notifier = ref.read(rankingProvider.notifier);
    switch (mode) {
      case final IllustRankingMode mode:
        notifier.setIllustMode(mode);
      case final MangaRankingMode mode:
        notifier.setMangaMode(mode);
      case final NovelRankingMode mode:
        notifier.setNovelMode(mode);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _kindChanged() {
    if (_tabs.indexIsChanging || _kind == _shown) return;
    final carried = _named(_kind, _modes[_shown]!.name) ?? _remembered(_kind);
    setState(() {
      _modes[_kind] = carried;
      _shown = _kind;
    });
    _remember(carried);
    _load();
  }

  void _select(Enum mode) {
    setState(() => _modes[_kind] = mode);
    _remember(mode);
    _load();
  }

  void _load() {
    final notifier = ref.read(rankingProvider.notifier);
    switch (_mode) {
      case final IllustRankingMode mode:
        notifier.loadIllustModeIfNeeded(mode);
      case final MangaRankingMode mode:
        notifier.loadMangaModeIfNeeded(mode);
      case final NovelRankingMode mode:
        notifier.loadNovelModeIfNeeded(mode);
    }
  }

  /// The ranking [kind]'s section shows.
  FrostListSource<Object?> _source(RankingState state, AppRankingKind kind) => switch (_modes[kind]!) {
    final IllustRankingMode mode => state.illustSourceFor(mode),
    final MangaRankingMode mode => state.mangaSourceFor(mode),
    final NovelRankingMode mode => state.novelSourceFor(mode),
    _ => throw StateError('not a ranking mode'),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = ref.watch(rankingProvider);
    final modes = rankingModes(_kind);
    FrostMenuAction action(Enum mode) => FrostMenuAction(rankingModeLabel(t, mode), checked: mode == _mode, onSelected: () => _select(mode));
    return AppSectionedPage(
      controller: _tabs,
      header: FrostPageHeader(
        leading: [
          FrostTitleMenu(
            key: const ValueKey('ranking-mode'),
            title: '${t.navigation.ranking} · ${rankingModeLabel(t, _mode)}',
            entries: [
              FrostMenuSection(entries: [for (final mode in modes.where((mode) => !rankingModeIsR18(mode))) action(mode)]),
              FrostMenuSection(header: t.ranking.r18Section, entries: [for (final mode in modes.where(rankingModeIsR18)) action(mode)]),
            ],
          ),
        ],
      ),
      tabs: [
        FrostTab(label: t.ranking.types.illustrations),
        FrostTab(label: t.ranking.types.manga),
        FrostTab(label: t.ranking.types.novels),
      ],
      onRefresh: (section) async => _source(state, AppRankingKind.values[section]).refresh(false),
      // Another mode starts the section afresh at its top.
      sectionKey: (section) => _modes[AppRankingKind.values[section]],
      slivers: (context, section) {
        final kind = AppRankingKind.values[section];
        final source = _source(state, kind);
        final empty = FrostEmptyState(icon: FrostIconSet.of(context).empty, title: t.ranking.emptyTitle, message: t.ranking.emptyMessage);
        if (kind == AppRankingKind.novel) {
          return [
            FrostSliverContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              sliver: FrostSliverDataList<Novel>(
                source: source as FrostListSource<Novel>,
                firstLoadSkeleton: const AppNovelRowsSkeleton(),
                empty: empty,
                itemBuilder: (context, novel, index) => AppNovelRow(novel: novel, rank: index + 1),
              ),
            ),
          ];
        }
        return [
          FrostSliverDataWaterfallGrid<Illust>(
            source: source as FrostListSource<Illust>,
            firstLoadSkeleton: const AppArtworkWaterfallSkeleton(),
            empty: empty,
            itemBuilder: (context, illust, index) => AppArtworkCard(illust: illust, rank: index + 1),
          ),
        ];
      },
    );
  }
}
