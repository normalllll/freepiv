import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/refresh/app_refresh.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/comment_thread_item.dart';
import 'package:freepiv/features/comments/presentation/work_comments_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/composer_bar.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:frost_ui/social.dart';

import 'support/pilot_harness.dart';

class _Comments extends WorkCommentsListSource {
  _Comments(this.first, {this.send}) : super(workType: CommentWorkType.illust, workId: 1);

  final Future<CommentPageResult> Function() first;
  final Future<Comment> Function()? send;

  @override
  Future<CommentPageResult> loadFirstPage() => first();

  @override
  Future<Comment> addComment({required String comment, int? stampId, int? parentCommentId}) => send!();
}

class _Replies extends CommentRepliesListSource {
  _Replies(this.replies, int parent) : super(workType: CommentWorkType.illust, parentCommentId: parent);

  final List<Comment> replies;
  final deleted = <int>[];

  @override
  Future<CommentPageResult> loadFirstPage() async => CommentPageResult(comments: replies);

  @override
  Future<void> deleteOnServer(Comment comment) async => deleted.add(comment.id);
}

Future<void> _mount(
  WidgetTester tester,
  _Comments source, {
  Size size = desktopSize,
  double textScale = 1,
  CommentRepliesListSource Function(CommentWorkType workType, int parent)? replies,
}) => mountPilotPage(
  tester,
  const WorkCommentsPage(workType: CommentWorkType.illust, workId: 1, totalComments: 10),
  size: size,
  textScale: textScale,
  overrides: {
    workCommentsSourceProvider: workCommentsSourceProvider.overrideWith((ref, _) => source),
    if (replies != null) commentRepliesSourceFactoryProvider: commentRepliesSourceFactoryProvider.overrideWithValue(replies),
  },
);

Comment _comment(int id, String text, {bool hasReplies = false, User? user}) {
  final sample = sampleComments(count: 1).single;
  return Comment(id: id, comment: text, date: sample.date, user: user ?? sample.user, hasReplies: hasReplies);
}

User _me() {
  final me = sampleAccount.user;
  return User(
    id: int.parse(me.id),
    name: me.name,
    account: me.account,
    profileImageUrls: const ProfileImageUrls(medium: ''),
  );
}

Comment _own() => _comment(sampleComments(count: 1).single.id, 'Mine', user: _me());

void main() {
  testWidgets('threads show under the count; only one\'s own comment can be deleted', (tester) async {
    await _mount(tester, _Comments(() async => CommentPageResult(comments: [_own(), ...sampleComments(count: 3)])));
    expect(find.text(t.illust.section.commentsWithCount(count: '10')), findsOneWidget);
    expect(find.byType(FrostThread), findsNWidgets(4));
    final items = tester.widgetList<FrostThread>(find.byType(FrostThread)).map((thread) => thread.item).toList();
    expect(items.first.contextMenu, isNotEmpty, reason: 'the signed-in user\'s comment');
    expect(items.skip(1).every((item) => item.contextMenu.isEmpty), isTrue);
    expect(pixivAccountNotifier.value, isNotNull);
  });

  testWidgets('Load replies shows the replies; a deleted one goes; a refresh loads them afresh', (tester) async {
    final made = <_Replies>[];
    await _mount(
      tester,
      _Comments(() async => CommentPageResult(comments: [_comment(1, 'Parent', hasReplies: true)])),
      replies: (_, parent) {
        final source = _Replies([_comment(11, 'First reply', user: _me()), _comment(12, 'Second reply')], parent);
        made.add(source);
        return source;
      },
    );
    expect(find.text('First reply'), findsNothing);
    // Load replies sits under its comment, on the comment's text column, not at the avatar's edge.
    final loadStart = tester.getTopLeft(find.text(t.illust.comments.loadReplies)).dx;
    final parentText = tester.getTopLeft(find.text('Parent')).dx;
    final avatarStart = tester.getTopLeft(find.byType(FrostAvatar).first).dx;
    expect(parentText, greaterThan(avatarStart + 8));
    expect(loadStart, greaterThanOrEqualTo(parentText));
    expect(tester.getTopLeft(find.text(t.illust.comments.loadReplies)).dy, greaterThan(tester.getTopLeft(find.text('Parent')).dy));
    await tester.tap(find.text(t.illust.comments.loadReplies));
    await settlePilot(tester);
    expect(find.text('First reply'), findsOneWidget);
    expect(find.text('Second reply'), findsOneWidget);
    expect(find.text(t.illust.comments.loadReplies), findsNothing);

    final reply = tester.widgetList<FrostThread>(find.byType(FrostThread)).map((thread) => thread.item).firstWhere((item) => item.contextMenu.isNotEmpty);
    (reply.contextMenu.whereType<FrostMenuAction>().single.onSelected)!();
    await settlePilot(tester);
    await tester.tap(find.text(t.illust.comments.delete).last);
    await settlePilot(tester);
    expect(made.single.deleted, [11]);
    expect(find.text('First reply'), findsNothing);
    expect(find.text('Second reply'), findsOneWidget);

    await tester.widget<AppRefreshScope>(find.byType(AppRefreshScope)).onRefresh();
    await settlePilot(tester);
    expect(made, hasLength(2), reason: 'the refreshed thread has a new replies source');
    expect(find.text('Second reply'), findsNothing, reason: 'its replies wait for Load replies again');
    expect(find.text(t.illust.comments.loadReplies), findsOneWidget);
  });

  testWidgets('empty: the page invites the first comment and keeps the input bar', (tester) async {
    await _mount(tester, _Comments(() async => const CommentPageResult(comments: [])));
    expect(find.text(t.commentsPage.empty), findsOneWidget);
    expect(find.byType(AppComposerBar), findsOneWidget);
  });

  testWidgets('a failed send keeps the draft and says why', (tester) async {
    await _mount(tester, _Comments(() async => CommentPageResult(comments: sampleComments(count: 2)), send: () async => throw StateError('offline')));
    await tester.enterText(find.descendant(of: find.byType(AppComposerBar), matching: find.byType(EditableText)), 'A draft');
    await tester.pump();
    final send = tester.widgetList<FrostButton>(find.byType(FrostButton)).firstWhere((button) => button.label == t.common.send);
    send.onPressed!();
    await settlePilot(tester);
    expect(find.text('A draft'), findsOneWidget);
  });

  testWidgets('loading shows rows at their size; the input bar and long names fit a phone at double text size', (tester) async {
    final never = Completer<CommentPageResult>();
    await _mount(tester, _Comments(() => never.future), size: phoneSize, textScale: 2);
    expect(find.byType(AppCommentRowsSkeleton), findsOneWidget);
    expectNoLayoutErrors(tester);
    await _mount(
      tester,
      _Comments(
        () async => CommentPageResult(
          comments: [
            Comment(
              id: 1,
              comment: longText,
              date: '2026-11-01T10:00:00+09:00',
              user: const User(
                id: 9,
                name: longText,
                account: longText,
                profileImageUrls: ProfileImageUrls(medium: ''),
              ),
              hasReplies: false,
            ),
          ],
        ),
      ),
      size: phoneSize,
      textScale: 2,
    );
    expectNoLayoutErrors(tester);
  });

  test('the comment strings exist in all four languages', () => expectLocalesComplete(['commentsPage', 'illust']));
}
