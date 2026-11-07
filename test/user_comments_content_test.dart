import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_input_bar.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/user_previewer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';

const _images = ProfileImageUrls(medium: '');

Widget _app(Widget child, {double scale = 1, double width = 390}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844), textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('comment is a content row with a separate reply action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = User(id: 7, name: 'Comment author with a long name', account: 'long_author_account', profileImageUrls: _images);
    const comment = Comment(id: 1, comment: 'A short comment', date: '2026-09-27T00:00:00Z', user: user, hasReplies: false);
    var replies = 0;
    await tester.pumpWidget(
      _app(
        PixivCommentTile(comment: comment, assets: PixivCommentAssets.empty, workType: CommentWorkType.illust, onReply: (_) => replies++),
        scale: 2,
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Reply'));
    expect(replies, 1);
    final avatarTarget = tester.getSize(find.byType(FrostClickSurface).first);
    expect(avatarTarget.width, greaterThanOrEqualTo(48));
  });

  testWidgets('stamp keeps its full media slot in the comment flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = User(id: 7, name: 'Comment author', account: 'author', profileImageUrls: _images);
    const comment = Comment(
      id: 2,
      comment: '',
      date: '2026-09-27T00:00:00Z',
      user: user,
      hasReplies: false,
      stamp: Stamp(stampId: 1, stampUrl: 'stamp'),
    );
    await tester.pumpWidget(_app(const PixivCommentTile(comment: comment, assets: PixivCommentAssets.empty, workType: CommentWorkType.illust)));
    expect(tester.takeException(), isNull);
    final stamp = find.byWidgetPredicate((widget) => widget is PixivImage && widget.url == 'stamp');
    expect(tester.getSize(stamp).height, 96);
  });

  testWidgets('preview shares comment row and keeps reply context readable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = User(id: 7, name: 'Comment author', account: 'author', profileImageUrls: _images);
    const comment = Comment(id: 3, comment: 'An illustrated reply', date: '2026-09-27T00:00:00Z', user: user, hasReplies: true);
    await tester.pumpWidget(
      _app(const PixivCommentTile(comment: comment, assets: PixivCommentAssets.empty, workType: CommentWorkType.illust, preview: true, showReplies: false)),
    );
    expect(find.textContaining('@author'), findsOneWidget);
    expect(find.text(t.illust.comments.hasReplies), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow comment composer focuses the reply target without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = User(id: 7, name: 'Comment author', account: 'author', profileImageUrls: _images);
    const comment = Comment(id: 4, comment: 'Question', date: '2026-09-27T00:00:00Z', user: user, hasReplies: false);
    Widget frame(Comment? replyingTo) => _app(
      CommentInputBar(assets: PixivCommentAssets.empty, replyingTo: replyingTo, onCancelReply: () {}, onSubmit: ({required text, stampId}) async => true),
      width: 320,
      scale: 2,
    );
    await tester.pumpWidget(frame(null));
    await tester.pumpWidget(frame(comment));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creator row fits a narrow viewport at 2x text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const user = User(id: 7, name: 'A creator with a very long name', account: 'long_account_name', profileImageUrls: _images);
    const preview = UserPreview(user: user, illusts: [], isMuted: false);
    await tester.pumpWidget(_app(const UserPreviewer(userPreview: preview), scale: 2));
    expect(tester.takeException(), isNull);
  });

  test('800-wide author grid uses the shared artwork tile width', () {
    const contentWidth = 800.0 - 80 - 24;
    final columns = frostWaterfallColumnCount(width: contentWidth, preferredTileWidth: FrostMetrics.gridExtent, gap: FrostGap.grid, textScale: 1);
    expect(columns, 3);
  });
}
