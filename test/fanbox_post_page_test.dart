import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/fanbox_plans.dart';
import 'package:freepiv/features/fanbox/post_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/composer_bar.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';

import 'support/pilot_harness.dart';

Future<void> _mount(WidgetTester tester, {String postId = '5000', Future<FanboxPost> Function(String id)? load, FanboxPost? summary, Size size = desktopSize, double textScale = 1}) =>
    mountPilotPage(
      tester,
      FanboxPostDetailPage(postId: postId, summary: summary),
      size: size,
      textScale: textScale,
      overrides: {
        if (load != null) fanboxPostProvider: fanboxPostProvider.overrideWith((ref, id) => load(id)),
      },
    );

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);

FanboxPost _withTitle(FanboxPost post, String title, String author) => FanboxPost(
  id: post.id,
  creatorId: post.creatorId,
  user: FanboxUser(id: post.user.id, name: author),
  title: title,
  excerpt: post.excerpt,
  coverUrl: post.coverUrl,
  publishedDatetime: post.publishedDatetime,
  updatedDatetime: post.updatedDatetime,
  feeRequired: post.feeRequired,
  isRestricted: post.isRestricted,
  isLiked: post.isLiked,
  likeCount: post.likeCount,
  commentCount: post.commentCount,
  tags: [longText, ...post.tags],
  blocks: post.blocks,
);

void main() {
  testWidgets('the head, every kind of block, the actions, previous and next, and the comments with their input bar', (tester) async {
    await _mount(tester);
    final post = sampleFanboxPost('5000');
    expect(find.text(post.title), findsOneWidget);
    expect(find.text(post.user.name), findsOneWidget);
    expect(find.byKey(const ValueKey('fanbox-follow')), findsOneWidget);
    final paragraph = tester.widget<FrostRichText>(find.byType(FrostRichText));
    expect(paragraph.text, contains('[blog](https://example.test/blog)'));
    expect(paragraph.text, startsWith('**Thank you for your support**'));
    await _scrollTo(tester, find.text('Rough sketches'));
    await _scrollTo(tester, find.text('brushes.zip'));
    await _scrollTo(tester, find.text('Last month’s sketches'));
    await _scrollTo(tester, find.text(t.fanbox.unknown));
    await _scrollTo(tester, find.byKey(const ValueKey('fanbox-like')));
    await _scrollTo(tester, find.text(t.fanbox.next));
    await _scrollTo(tester, find.text('The harbour at dusk is lovely.'));
    expect(find.byType(FrostThread), findsNWidgets(3), reason: 'two comments and a reply');
    expect(find.byType(AppComposerBar), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the header keeps the title once the list has dropped the head', (tester) async {
    await _mount(tester, size: const Size(1147, 420));
    final title = sampleFanboxPost('5000').title;
    final inHeader = find.descendant(of: find.byType(FrostPageHeader), matching: find.text(title));
    expect(inHeader, findsNothing, reason: 'the head still shows it');
    await _scrollTo(tester, find.text('The harbour at dusk is lovely.'));
    expect(find.text(title), findsOneWidget, reason: 'the head is gone from the tree');
    expect(inHeader, findsOneWidget);
  });

  testWidgets('only one\'s own comment can be deleted; Reply names who is answered', (tester) async {
    await _mount(tester);
    await _scrollTo(tester, find.text('Looking forward to the next one.'));
    final items = tester.widgetList<FrostThread>(find.byType(FrostThread)).map((thread) => thread.item).toList();
    final own = items.singleWhere((item) => item.body is FrostText && (item.body as FrostText).data == 'Looking forward to the next one.');
    expect(own.contextMenu, isNotEmpty);
    expect(items.where((item) => item != own).every((item) => item.contextMenu.isEmpty), isTrue);

    items.first.reply!.onPressed!();
    await settlePilot(tester);
    expect(tester.widget<AppComposerBar>(find.byType(AppComposerBar)).replyLabel, '${t.fanbox.reply} A supporter');
  });

  testWidgets('a restricted post shows what it needs and the plans, and no comments', (tester) async {
    final restricted = sampleFanboxPosts().firstWhere((post) => post.isRestricted);
    await _mount(tester, postId: restricted.id);
    expect(find.byType(FrostInlineBanner), findsOneWidget);
    await _scrollTo(tester, find.text('Full plan'));
    expect(find.byType(FrostRichText), findsNothing, reason: 'no invented body');
    expect(find.byType(AppComposerBar), findsNothing);
    expect(find.byKey(const ValueKey('fanbox-like')), findsNothing);
  });

  testWidgets('loading keeps the card\'s title over placeholders; a failure retries the page', (tester) async {
    final never = Completer<FanboxPost>();
    final summary = sampleFanboxPosts().first;
    await _mount(tester, load: (_) => never.future, summary: summary);
    expect(find.text(summary.title), findsOneWidget);
    expect(find.byType(FrostRichText), findsNothing);

    var attempts = 0;
    await _mount(
      tester,
      load: (id) async {
        if (attempts++ == 0) throw StateError('offline');
        return sampleFanboxPost(id);
      },
    );
    expect(find.byType(FrostErrorContent), findsOneWidget);
    await tester.tap(find.text(t.common.retry));
    await settlePilot(tester);
    expect(find.byType(FrostRichText), findsOneWidget);
  });

  testWidgets('a body image opens in the image viewer with the session, kept off the disk, and offers the original on the web', (tester) async {
    await _mount(tester);
    final post = sampleFanboxPost('5000');
    final image = find.byWidgetPredicate((widget) => widget is AppFanboxImage && widget.url == fanboxPostImageUrls(post).single);
    await _scrollTo(tester, image);
    await tester.ensureVisible(image);
    await settlePilot(tester);
    final top = tester.getTopLeft(image);
    expect(top.dy, inInclusiveRange(0, 400));
    await tester.tapAt(top + const Offset(100, 100));
    await settlePilot(tester);
    expect(openedLocations.last, AppRoute.originalImageViewer.path);
    final args = openedExtras.last! as OriginalImageViewerArgs;
    expect(args.title, post.title);
    expect(args.pages.map((page) => page.url), fanboxPostImageUrls(post));
    expect(args.initialIndex, 0);
    expect(args.pages.single.headers!['Referer'], 'https://www.fanbox.cc/');
    expect(args.pages.single.accountKey, isNotNull, reason: 'an image behind a sign-in is never cached on disk');
    expect(args.openOriginal!.label, t.fanbox.openOriginal);
  });

  testWidgets('a restricted post\'s plans say what they include and open with the way to support them', (tester) async {
    final restricted = sampleFanboxPosts().firstWhere((post) => post.isRestricted);
    await _mount(tester, postId: restricted.id);
    final plan = sampleFanboxPlans(restricted.creatorId).last;
    await _scrollTo(tester, find.text(plan.title));
    final row = tester.widget<FrostListRow>(find.ancestor(of: find.text(plan.title), matching: find.byType(FrostListRow)));
    expect(row.subtitle!.text, plan.description.split('\n').first, reason: 'what the plan includes, not the creator');
    await tester.tap(find.text(plan.title));
    await settlePilot(tester);
    final dialog = tester.widget<FrostDialog>(find.byType(FrostDialog));
    expect(dialog.title, plan.title);
    expect(find.text(plan.description), findsOneWidget, reason: 'the whole description');
    expect(dialog.actions.single.label, t.fanbox.supportOnWebsite);
    expect(fanboxPlanUrl(plan), Uri.parse('https://www.fanbox.cc/@${plan.creatorId}/plans/${plan.id}'));
  });

  testWidgets('a post link opens that post', (tester) async {
    await _mount(tester);
    await _scrollTo(tester, find.text('Last month’s sketches'));
    await tester.tap(find.text('Last month’s sketches'));
    await settlePilot(tester);
    expect(openedLocations.last, AppLocations.fanboxPost('5004'));
  });

  testWidgets('a long title, author and tag fit a phone at double text size', (tester) async {
    await _mount(tester, size: phoneSize, textScale: 2, load: (id) async => _withTitle(sampleFanboxPost(id), longText, longText));
    expectNoLayoutErrors(tester, where: 'head');
    await _scrollTo(tester, find.byKey(const ValueKey('fanbox-like')));
    expectNoLayoutErrors(tester, where: 'actions');
  });
}
