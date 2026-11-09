import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/fanbox/browse_page.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const FanboxLocation _home = (section: FanboxSection.home, creatorId: '', query: '');

class _Browse extends FanboxBrowse {
  _Browse(this.load);

  final Future<FanboxCollection> Function(FanboxLocation location) load;

  @override
  Future<FanboxCollection> build(FanboxLocation location) => load(location);
}

class _Session extends FanboxSession {
  _Session(this.value);

  final String? value;

  @override
  Future<String?> build() async => value;
}

/// Fails on any request.
class _NoRequests implements FanboxApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('unexpected request: ${invocation.memberName}');
}

Future<void> _mount(
  WidgetTester tester, {
  FanboxLocation location = _home,
  Future<FanboxCollection> Function(FanboxLocation location)? load,
  Map<Object, Override> overrides = const {},
  Size size = desktopSize,
  double textScale = 1,
}) => mountPilotPage(
  tester,
  FanboxBrowsePage(location: location),
  size: size,
  textScale: textScale,
  overrides: {if (load != null) fanboxBrowseProvider: fanboxBrowseProvider.overrideWith2((_) => _Browse(load)), ...overrides},
);

FanboxPost _post(String id, {String title = 'Post'}) {
  final sample = sampleFanboxPosts(count: 1).single;
  return FanboxPost(
    id: id,
    creatorId: sample.creatorId,
    user: FanboxUser(id: '1', name: title),
    title: '$title $id',
    excerpt: title,
    coverUrl: sample.coverUrl,
    publishedDatetime: sample.publishedDatetime,
    updatedDatetime: sample.updatedDatetime,
    feeRequired: 500,
    isRestricted: true,
    isLiked: false,
    likeCount: 1,
    commentCount: 2,
    tags: const [],
    blocks: const [],
  );
}

void main() {
  testWidgets('the feed is post cards under the title menu naming the collection', (tester) async {
    await _mount(tester);
    final first = sampleFanboxPosts().first;
    expect(tester.widget<AppFanboxPostCard>(find.byType(AppFanboxPostCard).first).post.id, first.id);
    expect(find.text(first.title), findsOneWidget);
    expect(find.text(first.user.name), findsWidgets);
    expect(find.byWidgetPredicate((widget) => widget is FrostTitleMenu && widget.title == '${t.fanbox.title} · ${t.fanbox.home}'), findsOneWidget);
  });

  testWidgets('the title menu offers only what opens without words, supported plans under Mine', (tester) async {
    await _mount(tester);
    final groups = tester.widget<FrostTitleMenu>(find.byType(FrostTitleMenu)).entries.cast<FrostMenuSection>();
    List<String> labels(FrostMenuSection group) => [for (final entry in group.entries.cast<FrostMenuAction>()) entry.label];
    final all = groups.expand(labels).toList();
    expect(all, isNot(contains(t.fanbox.searchCreators)));
    expect(all, isNot(contains(t.fanbox.searchTags)));
    expect(labels(groups.singleWhere((group) => group.header == t.fanboxPage.groupMine)), contains(t.fanbox.plans));
    expect(labels(groups.singleWhere((group) => group.header == t.fanboxPage.groupDiscover)), isNot(contains(t.fanbox.plans)));
  });

  for (final section in [FanboxSection.searchCreators, FanboxSection.searchTags]) {
    for (final query in ['', '  ']) {
      test('${section.name} without words ("$query") shows nothing and asks FANBOX nothing', () async {
        final container = ProviderContainer(overrides: [fanboxApiProvider.overrideWith((ref) async => _NoRequests())]);
        addTearDown(container.dispose);
        final collection = await container.read(fanboxBrowseProvider((section: section, creatorId: '', query: query)).future);
        expect(collection.entries, isEmpty);
        expect(collection.hasMore, isFalse);
      });
    }
  }

  testWidgets('the title menu follows the collection shown, a tag or a search included', (tester) async {
    await _mount(tester, location: (section: FanboxSection.bookmarks, creatorId: '', query: ''));
    final menu = tester.widget<FrostTitleMenu>(find.byType(FrostTitleMenu));
    expect(menu.title, '${t.fanbox.title} · ${t.fanbox.bookmarks}');
    final checked = [
      for (final section in menu.entries.whereType<FrostMenuSection>())
        for (final action in section.entries.whereType<FrostMenuAction>())
          if (action.checked == true) action.label,
    ];
    expect(checked, [t.fanbox.bookmarks], reason: 'only the collection shown is checked');
    expect(find.text(t.fanboxPage.localOnly), findsOneWidget);
    await _mount(tester, location: (section: FanboxSection.tag, creatorId: '', query: 'process'));
    expect(tester.widget<FrostTitleMenu>(find.byType(FrostTitleMenu)).title, '${t.fanbox.title} · #process');
  });

  testWidgets('the search offers the creator ID, creators and tags for what is typed; Enter follows the tags section', (tester) async {
    final opened = <FanboxLocation>[];
    await _mount(
      tester,
      load: (location) async {
        opened.add(location);
        return const FanboxCollection([]);
      },
    );
    final input = find.descendant(of: find.byType(FrostSearchInput), matching: find.byType(EditableText));
    await tester.tap(input);
    await tester.enterText(input, 'kite');
    await settlePilot(tester, frames: 4);
    expect(find.text(t.fanboxPage.openCreator(id: 'kite')), findsOneWidget);
    expect(find.text(t.fanboxPage.searchCreators(query: 'kite')), findsOneWidget);
    expect(find.text(t.fanboxPage.searchTags(query: 'kite')), findsOneWidget);

    await tester.enterText(input, '猫 cat');
    await settlePilot(tester, frames: 4);
    expect(find.text(t.fanboxPage.openCreator(id: '猫 cat')), findsNothing, reason: 'not a creator ID');
    expect(find.text(t.fanboxPage.searchTags(query: '猫 cat')), findsOneWidget);
    await tester.tap(find.text(t.fanboxPage.searchTags(query: '猫 cat')));
    await settlePilot(tester, frames: 4);
    expect(opened.last, (section: FanboxSection.searchTags, creatorId: '', query: '猫 cat'));

    // While tags are shown, Enter searches tags again.
    await tester.tap(input);
    await tester.enterText(input, 'sea');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settlePilot(tester, frames: 4);
    expect(opened.last, (section: FanboxSection.searchTags, creatorId: '', query: 'sea'));
  });

  testWidgets('Enter outside the tags section searches creators', (tester) async {
    final opened = <FanboxLocation>[];
    await _mount(
      tester,
      load: (location) async {
        opened.add(location);
        return const FanboxCollection([]);
      },
    );
    final input = find.descendant(of: find.byType(FrostSearchInput), matching: find.byType(EditableText));
    await tester.tap(input);
    await tester.enterText(input, 'sea');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settlePilot(tester, frames: 4);
    expect(opened.last, (section: FanboxSection.searchCreators, creatorId: '', query: 'sea'));
  });

  testWidgets('empty', (tester) async {
    await _mount(tester, load: (_) async => const FanboxCollection([]));
    expect(find.text(t.fanbox.empty), findsOneWidget);
  });

  testWidgets('loading', (tester) async {
    final never = Completer<FanboxCollection>();
    await _mount(tester, load: (_) => never.future);
    expect(find.byType(FanboxCollectionSkeleton), findsOneWidget);
    expect(find.text(sampleFanboxPosts().first.title), findsNothing);
  });

  testWidgets('error', (tester) async {
    await _mount(tester, load: (_) async => throw StateError('offline'));
    expect(find.byType(FrostErrorContent), findsOneWidget);
  });

  testWidgets('partial failure: saved posts load one by one and a failed one retries alone', (tester) async {
    await _mount(
      tester,
      location: (section: FanboxSection.bookmarks, creatorId: '', query: ''),
      load: (_) async => const FanboxCollection([FanboxBookmarkEntry('a'), FanboxBookmarkEntry('b')]),
      overrides: {fanboxPostProvider: fanboxPostProvider.overrideWith((ref, id) async => id == 'a' ? _post('a') : throw StateError('gone'))},
    );
    expect(find.byType(AppFanboxPostCard), findsOneWidget);
    expect(find.byType(FrostCompactMessage), findsOneWidget);
  });

  testWidgets('without a FANBOX session the page asks to sign in', (tester) async {
    await _mount(tester, overrides: {fanboxSessionProvider: fanboxSessionProvider.overrideWith(() => _Session(null))});
    expect(find.byType(AppFanboxPostCard), findsNothing);
    expect(find.byType(FrostSearchInput), findsNothing);
  });

  testWidgets('the header and long post titles fit 390 wide at double text size', (tester) async {
    await _mount(
      tester,
      size: const Size(390, 844),
      textScale: 2,
      load: (_) async => FanboxCollection([FanboxPostEntry(_post('1', title: longText))]),
    );
    expectNoLayoutErrors(tester);
    expect(find.byType(FrostTitleMenu), findsOneWidget);
  });

  test('the FANBOX strings exist in all four languages', () => expectLocalesComplete(['fanboxPage', 'fanbox']));
}
