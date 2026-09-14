import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:freepiv/shared/widgets/data_refresh_view.dart';
import 'package:freepiv/shared/widgets/refresh_indicator.dart';
import 'package:freepiv/shared/widgets/floating_filter_sliver.dart';
import 'package:freepiv/shared/widgets/sliver_paged_data_list.dart';
import 'skeletons.dart';
import 'package:freepiv/shared/widgets/search_input.dart';
import 'navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'layout.dart';
import 'logic.dart';
import 'widgets.dart';
import 'cards.dart';

void openFanboxPost(BuildContext context, String id, {FanboxPost? summary}) => context.push('/fanbox/post/${Uri.encodeComponent(id)}', extra: summary);
void openFanboxCreator(BuildContext context, String id, {FanboxCreator? summary}) => context.push('/fanbox/creator/${Uri.encodeComponent(id)}', extra: summary);
void openFanboxTag(BuildContext context, String tag, {String creatorId = ''}) =>
    context.push(Uri(path: '/fanbox/tag', queryParameters: {'section': 'tag', 'q': tag, if (creatorId.isNotEmpty) 'creator': creatorId}).toString());

GoRoute fanboxTagRoute() => GoRoute(
  path: '/fanbox/tag',
  builder: (context, state) =>
      FanboxPage(location: (section: FanboxSection.tag, creatorId: state.uri.queryParameters['creator'] ?? '', query: state.uri.queryParameters['q'] ?? '')),
);

final _fanboxBrowseStorage = PageStorageBucket();

class FanboxPage extends ConsumerStatefulWidget {
  const FanboxPage({required this.location, super.key});
  final FanboxLocation location;
  @override
  ConsumerState<FanboxPage> createState() => _FanboxPageState();
}

class _FanboxPageState extends ConsumerState<FanboxPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _search.text = widget.location.query;
  }

  @override
  void didUpdateWidget(covariant FanboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.query != widget.location.query) _search.text = widget.location.query;
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _select(FanboxSection section, {String query = ''}) {
    final location = (section: section, creatorId: '', query: query);
    ref.read(fanboxBrowseSelectionProvider.notifier).select(location);
    final path = GoRouterState.of(context).uri.path == '/fanbox' ? '/fanbox' : '/fanbox/browse';
    context.replace(Uri(path: path, queryParameters: {'section': section.name, if (query.isNotEmpty) 'q': query}).toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final session = ref.watch(fanboxSessionProvider);
    return FanboxScaffold(
      title: t.title,

      body: session.when(
        loading: () => const FanboxHomeSkeleton(),
        error: (error, _) => FanboxErrorView(error, retry: () => ref.invalidate(fanboxSessionProvider)),
        data: (session) => session == null
            ? const FanboxLoginPanel()
            : Column(
                children: [
                  SearchInputRegion(
                    child: SearchInput(
                      controller: _search,
                      focusNode: _searchFocus,
                      hintText: t.searchHint,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _select(
                            widget.location.section == FanboxSection.searchTags ? FanboxSection.searchTags : FanboxSection.searchCreators,
                            query: value.trim(),
                          );
                        }
                      },
                      actions: [
                        PopupMenuButton<FanboxSection>(
                          tooltip: context.t.common.type,
                          icon: const Icon(Icons.tune, size: 18),
                          onSelected: (value) {
                            final query = _search.text.trim();
                            if (value == FanboxSection.creatorPosts) {
                              if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(query)) openFanboxCreator(context, query);
                            } else {
                              _select(value, query: query);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: FanboxSection.creatorPosts, child: Text(t.creatorId)),
                            for (final section in [FanboxSection.searchCreators, FanboxSection.searchTags])
                              PopupMenuItem(value: section, child: Text(fanboxSectionLabel(context, section))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageStorage(
                      bucket: _fanboxBrowseStorage,
                      child: FanboxCollectionView(
                        key: ValueKey(widget.location),
                        location: widget.location,
                        filterSliver: FloatingFilterSliver(
                          height: compactFilterHeight(context),
                          child: Material(
                            color: Theme.of(context).colorScheme.surface,
                            child: FanboxContent(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                                child: FanboxSectionNavigation(section: widget.location.section, onSelected: _select),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FanboxLoginPanel extends ConsumerStatefulWidget {
  const FanboxLoginPanel({this.onSignedIn, super.key});
  final VoidCallback? onSignedIn;
  @override
  ConsumerState<FanboxLoginPanel> createState() => _FanboxLoginPanelState();
}

class _FanboxLoginPanelState extends ConsumerState<FanboxLoginPanel> {
  final _cookie = TextEditingController();
  @override
  void dispose() {
    _cookie.clear();
    _cookie.dispose();
    super.dispose();
  }

  Future<void> _login(String value) async {
    final result = await ref.read(fanboxOperationProvider('login').notifier).run(() => ref.read(fanboxSessionProvider.notifier).signIn(value));
    if (result && mounted) {
      _cookie.clear();
      widget.onSignedIn?.call();
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
    if (result.isEmpty || !mounted) return;
    final file = result.single;
    final success = await ref.read(fanboxOperationProvider('login').notifier).run(() async {
      if (await file.length() > 64 * 1024) throw const FormatException();
      final bytes = await file.readAsBytes();
      if (bytes.length > 64 * 1024) throw const FormatException();
      await ref.read(fanboxSessionProvider.notifier).signIn(utf8.decode(bytes));
    });
    if (success && mounted) widget.onSignedIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final operation = ref.watch(fanboxOperationProvider('login'));
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.article_outlined, size: 56),
              const SizedBox(height: 16),
              Text(t.login, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(t.loginHelp),
              const SizedBox(height: 24),
              TextField(
                controller: _cookie,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: 'FANBOXSESSID', hintText: t.cookieHint),
                onSubmitted: operation.isLoading ? null : _login,
              ),
              const SizedBox(height: 16),
              AppButton(label: t.login, loading: operation.isLoading, kind: AppButtonKind.primary, onPressed: () => _login(_cookie.text)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: operation.isLoading ? null : _import, child: Text(t.importSession)),
              TextButton(onPressed: () => openFanboxLink(context, 'https://www.fanbox.cc/'), child: Text(t.openWebsite)),
              SizedBox(
                height: 48,
                child: operation.hasError ? Text(t.loginFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FanboxCollectionView extends ConsumerWidget {
  const FanboxCollectionView({required this.location, this.header, this.filterSliver, super.key});
  final FanboxLocation location;
  final Widget? header;
  final Widget? filterSliver;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = fanboxBrowseProvider(location);
    final state = ref.watch(provider);
    return DataRefreshView(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
        return true;
      },
      builder: (context, physics, locators) => LayoutBuilder(
        builder: (context, constraints) {
          final data = state.value;
          final entries = data?.entries ?? const <FanboxEntry>[];
          return DataLoadingCustomScrollView(
            key: PageStorageKey(header == null ? location : ('fanbox-creator', location.creatorId)),
            physics: physics,
            slivers: [
              ?filterSliver,
              if (header != null)
                SliverPadding(
                  padding: fanboxScrollPadding(constraints.maxWidth).copyWith(bottom: 0),
                  sliver: SliverList.list(children: [_RetainedHeader(child: header!)]),
                ),
              ?locators.sliverHeader,
              if (data == null)
                SliverPadding(
                  padding: fanboxScrollPadding(constraints.maxWidth),
                  sliver: SliverToBoxAdapter(
                    child: state.hasError
                        ? FanboxErrorView(state.error!, retry: () => ref.invalidate(provider))
                        : FanboxCollectionSkeleton(section: location.section),
                  ),
                )
              else
                SliverPagedDataList<FanboxEntry>(
                  key: ValueKey(location),
                  items: entries,
                  hasMore: data.hasMore,
                  loading: data.loadingMore || state.isLoading,
                  hasError: data.error != null,
                  onLoadMore: () async {
                    final notifier = ref.read(provider.notifier);
                    await notifier.loadMore();
                    return context.mounted && ref.read(provider).value?.error == null;
                  },
                  padding: fanboxScrollPadding(constraints.maxWidth),
                  footer: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        if (data.entries.isEmpty) Text(context.t.fanbox.empty),
                        if (data.loadingMore) FanboxCollectionSkeleton(section: location.section),
                        if (data.error != null) ...[
                          Text(fanboxError(context, data.error!)),
                          OutlinedButton(onPressed: () => ref.read(provider.notifier).loadMore(), child: Text(context.t.fanbox.loadMore)),
                        ],
                      ],
                    ),
                  ),
                  itemBuilder: (context, entry, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: switch (entry) {
                      FanboxPostEntry(:final post) => FanboxPostCard(
                        post: post,
                        onTap: () => openFanboxPost(context, post.id, summary: post),
                        onCreator: () => openFanboxCreator(context, post.creatorId),
                      ),
                      FanboxCreatorEntry(:final creator) => FanboxCreatorCard(
                        creator,
                        onTap: () => openFanboxCreator(context, creator.creatorId, summary: creator),
                      ),
                      FanboxPlanEntry(:final plan) => FanboxPlanCard(plan),
                      FanboxTagEntry(:final tag) => FanboxTagCard(tag, onTap: () => openFanboxTag(context, tag.name)),
                      FanboxNoticeEntry(:final notice) => FanboxNoticeCard(
                        notice,
                        onPost: notice.postId == null ? null : () => openFanboxPost(context, notice.postId!),
                        onCreator: notice.creatorId == null ? null : () => openFanboxCreator(context, notice.creatorId!),
                      ),
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RetainedHeader extends StatefulWidget {
  const _RetainedHeader({required this.child});
  final Widget child;
  @override
  State<_RetainedHeader> createState() => _RetainedHeaderState();
}

class _RetainedHeaderState extends State<_RetainedHeader> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
