import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/fanbox/creator_page.dart';
import 'package:freepiv/features/fanbox/fanbox_actions.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

Future<void> _mount(
  WidgetTester tester, {
  bool plans = false,
  Future<FanboxCreator> Function(String id)? load,
  Future<List<FanboxTag>> Function(String id)? tags,
  Map<String, FanboxCollecting> collecting = const {},
  Size size = desktopSize,
  double textScale = 1,
}) => mountPilotPage(
  tester,
  FanboxCreatorDetailPage(creatorId: 'sample_creator', showPlans: plans),
  size: size,
  textScale: textScale,
  overrides: {
    if (load != null) fanboxCreatorProvider: fanboxCreatorProvider.overrideWith((ref, id) => load(id)),
    if (tags != null) fanboxTagsProvider: fanboxTagsProvider.overrideWith((ref, id) => tags(id)),
    if (collecting.isNotEmpty) fanboxDownloadsProvider: fanboxDownloadsProvider.overrideWithValue(collecting),
  },
);

Future<void> _showTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(FrostTabBar), matching: find.text(label)));
  await settlePilot(tester);
}

void main() {
  testWidgets('the identity with Follow and More heads Posts, Plans and Profile', (tester) async {
    await _mount(tester);
    final creator = sampleFanboxCreator('sample_creator');
    final header = tester.widget<AppIdentityHeader>(find.byType(AppIdentityHeader));
    expect(header.name, creator.user.name);
    expect(header.subtitle, '@sample_creator');
    expect(header.more.whereType<FrostMenuAction>().map((action) => action.label), [t.fanbox.downloadCreator, t.fanbox.openOriginal, t.fanbox.fanCard]);
    expect(find.byKey(const ValueKey('fanbox-follow')), findsOneWidget);
    expect(find.byType(AppFanboxPostCard), findsWidgets, reason: 'Posts is the first tab');

    await _showTab(tester, t.fanbox.creatorPlans);
    expect(find.text(t.fanbox.monthlyFee(fee: 500)), findsWidgets);

    await _showTab(tester, t.user.tabs.profile);
    expect(find.text('example.test'), findsNWidgets(2));
    expect(find.text('#illustration'), findsOneWidget);
    await tester.tap(find.text('#illustration'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.fanboxTag('illustration', creatorId: 'sample_creator', section: FanboxSection.tag.name));
  });

  testWidgets('a plan says what it includes and opens with the way to support it, not the creator again', (tester) async {
    await _mount(tester, plans: true);
    final plan = sampleFanboxPlans('sample_creator').first;
    final row = tester.widget<FrostListRow>(find.ancestor(of: find.text(plan.title), matching: find.byType(FrostListRow)));
    expect(row.subtitle!.text, plan.description.split('\n').first);
    await tester.tap(find.text(plan.title));
    await settlePilot(tester);
    expect(openedLocations, isEmpty, reason: 'no second creator page');
    expect(tester.widget<FrostDialog>(find.byType(FrostDialog)).actions.single.label, t.fanbox.supportOnWebsite);
    expect(find.text(plan.description), findsOneWidget);
  });

  testWidgets('a profile picture opens in the image viewer at that picture', (tester) async {
    await _mount(tester);
    await _showTab(tester, t.user.tabs.profile);
    final creator = sampleFanboxCreator('sample_creator');
    final picture = find.byWidgetPredicate((widget) => widget is AppFanboxImage && widget.url == creator.profileImages[1]);
    await tester.scrollUntilVisible(picture, 300, scrollable: find.byType(Scrollable).at(1));
    await tester.ensureVisible(picture);
    await settlePilot(tester);
    await tester.tap(picture);
    await settlePilot(tester);
    expect(openedLocations.last, AppRoute.originalImageViewer.path);
    final args = openedExtras.last! as OriginalImageViewerArgs;
    expect(args.pages.map((page) => page.url), creator.profileImages);
    expect(args.initialIndex, 1);
    expect(args.pages.every((page) => page.accountKey != null), isTrue);
    expect(args.openOriginal!.label, t.fanbox.openOriginal);
  });

  testWidgets('opens on Plans when asked; the header names the creator once the identity has gone', (tester) async {
    await _mount(tester, plans: true);
    expect(tester.widget<FrostTabBar>(find.byType(FrostTabBar)).controller!.index, 1);
    final page = find.byType(FrostPageHeader);
    expect(find.descendant(of: page, matching: find.text('Studio Kite')), findsNothing);
    await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -600));
    await settlePilot(tester);
    expect(find.descendant(of: page, matching: find.text('Studio Kite')), findsOneWidget);
  });

  testWidgets('while every post is being collected, Download all is off and says so', (tester) async {
    await _mount(tester, collecting: {'sample_creator': (source: fanboxCreatorDownloadSource(sampleFanboxCreator('sample_creator')), posts: 3)});
    final header = tester.widget<AppIdentityHeader>(find.byType(AppIdentityHeader));
    final download = header.more.whereType<FrostMenuAction>().first;
    expect(download.label, t.fanboxPage.collecting);
    expect(download.enabled, isFalse);
  });

  testWidgets('tags that fail retry on their own; the rest of Profile stays', (tester) async {
    var attempts = 0;
    await _mount(
      tester,
      tags: (_) async {
        if (attempts++ == 0) throw StateError('offline');
        return const [FanboxTag(name: 'later')];
      },
    );
    await _showTab(tester, t.user.tabs.profile);
    expect(find.byType(FrostCompactMessage), findsOneWidget);
    expect(find.text('example.test'), findsNWidgets(2));
    await tester.tap(find.text(t.fanbox.retry));
    await settlePilot(tester);
    expect(find.text('#later'), findsOneWidget);
  });

  testWidgets('loading shows the identity in placeholders; a failure retries the page', (tester) async {
    final never = Completer<FanboxCreator>();
    await _mount(tester, load: (_) => never.future);
    expect(find.byType(AppIdentityHeader), findsOneWidget);

    var attempts = 0;
    await _mount(
      tester,
      load: (id) async {
        if (attempts++ == 0) throw StateError('offline');
        return sampleFanboxCreator(id);
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.text('@sample_creator'), findsOneWidget);
  });

  testWidgets('a long name fits a phone at double text size', (tester) async {
    await _mount(
      tester,
      size: phoneSize,
      textScale: 2,
      load: (id) async {
        final sample = sampleFanboxCreator(id);
        return FanboxCreator(
          creatorId: id,
          user: const FanboxUser(id: '600', name: longText),
          description: longText,
          isFollowed: false,
          isSupported: false,
          hasAdultContent: false,
          profileLinks: sample.profileLinks,
          profileImages: const [],
        );
      },
    );
    expectNoLayoutErrors(tester);
  });
}
