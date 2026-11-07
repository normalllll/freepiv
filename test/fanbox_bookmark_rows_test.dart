import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/features/fanbox/browse_page.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:frost_ui/frost_ui.dart';

FanboxPost _post(String id) => FanboxPost(
  id: id,
  creatorId: 'author',
  user: const FanboxUser(id: 'author', name: 'Author'),
  title: 'Post $id',
  excerpt: '',
  publishedDatetime: '2026-09-27T00:00:00Z',
  updatedDatetime: '2026-09-27T00:00:00Z',
  feeRequired: 0,
  isRestricted: false,
  isLiked: false,
  likeCount: 0,
  commentCount: 0,
  tags: const [],
  blocks: const [],
);

void main() {
  testWidgets('each bookmark loads on its own; one failure fails only its row and retries alone', (tester) async {
    final slow = Completer<FanboxPost>();
    var brokenAttempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          fanboxPostProvider('a').overrideWith((ref) async => _post('a')),
          fanboxPostProvider('b').overrideWith((ref) {
            brokenAttempts++;
            return Future<FanboxPost>.error(StateError('gone'));
          }),
          fanboxPostProvider('c').overrideWith((ref) => slow.future),
        ],
        child: TranslationProvider(
          child: FrostScope(
            config: freepivFrostConfig,
            child: MaterialApp(
              theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      FanboxEntryView(entry: FanboxBookmarkEntry('a')),
                      FanboxEntryView(entry: FanboxBookmarkEntry('b')),
                      FanboxEntryView(entry: FanboxBookmarkEntry('c')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Post a'), findsOneWidget, reason: 'a loaded bookmark shows while another is still loading');
    expect(find.byType(FrostCompactMessage), findsOneWidget, reason: 'only the failed bookmark shows a failure');
    expect(find.text('Post c'), findsNothing);

    slow.complete(_post('c'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Post c'), findsOneWidget);
    expect(find.byType(AppFanboxPostCard), findsNWidgets(2));

    await tester.tap(find.text(t.fanbox.retry));
    await tester.pump();
    await tester.pump();
    expect(brokenAttempts, 2);
    expect(find.text('Post a'), findsOneWidget);
  });

  testWidgets('a loaded row stays loaded when scrolled away and back, and keeps its card while it reloads', (tester) async {
    final api = _Api();
    final container = ProviderContainer(retry: (_, _) => null, overrides: [fanboxApiProvider.overrideWith((ref) async => api)]);
    addTearDown(container.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: FrostScope(
            config: freepivFrostConfig,
            child: MaterialApp(
              theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: Scaffold(
                body: ListView.builder(
                  controller: scroll,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                  itemCount: 40,
                  itemBuilder: (context, index) => FanboxEntryView(entry: FanboxBookmarkEntry('$index')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Post 0'), findsOneWidget);
    expect(api.requests['0'], 1);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    expect(find.text('Post 0'), findsNothing, reason: 'the first row is off screen');
    scroll.jumpTo(0);
    await tester.pump();
    expect(find.text('Post 0'), findsOneWidget, reason: 'shown at once, without a skeleton');
    expect(api.requests['0'], 1, reason: 'not fetched again');

    final reload = Completer<FanboxPost>();
    api.pending['0'] = reload;
    container.invalidate(fanboxPostProvider('0'));
    await tester.pump();
    expect(api.requests['0'], 2);
    expect(find.text('Post 0'), findsOneWidget, reason: 'the loaded card stays while it reloads');
    reload.complete(_post('0'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Post 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });

  test('the bookmarks collection lists every saved post at once, without loading any', () async {
    final container = ProviderContainer(overrides: [fanboxBookmarksProvider.overrideWith(_Bookmarks.new)]);
    addTearDown(container.dispose);
    final collection = await container.read(fanboxBrowseProvider((section: FanboxSection.bookmarks, creatorId: '', query: '')).future);
    expect(collection.entries.map((entry) => (entry as FanboxBookmarkEntry).postId), ['a', 'b']);
  });
}

class _Bookmarks extends FanboxBookmarks {
  @override
  Future<List<String>> build() async => const ['a', 'b'];
}

class _Api implements FanboxApi {
  final requests = <String, int>{};
  final pending = <String, Completer<FanboxPost>>{};

  @override
  Future<FanboxPost> getPost({required String postId}) {
    requests.update(postId, (count) => count + 1, ifAbsent: () => 1);
    return pending.remove(postId)?.future ?? Future.value(_post(postId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
