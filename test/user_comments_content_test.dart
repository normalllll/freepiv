import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/comments/domain/pixiv_comment_assets.dart';
import 'package:freepiv/features/comments/logic/work_comments_source.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_input_bar.dart';
import 'package:freepiv/features/comments/presentation/widgets/comment_tile.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_detail_tab_scaffold.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/pixiv_image.dart';
import 'package:freepiv/shared/widgets/user_previewer.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

const _images = ProfileImageUrls(medium: '');
const _detail = UserDetailResult(
  user: UserInfo(id: 7, name: 'A creator with a very long name', account: 'long_account_name', profileImageUrls: _images, isFollowed: false),
  profile: UserProfile(
    gender: '',
    birth: '',
    birthDay: '',
    birthYear: 0,
    region: '',
    addressId: 0,
    countryCode: '',
    job: '',
    jobId: 0,
    totalFollowUsers: 4,
    totalMypixivUsers: 0,
    totalIllusts: 12,
    totalManga: 3,
    totalNovels: 1,
    totalIllustBookmarksPublic: 0,
    totalIllustSeries: 0,
    totalNovelSeries: 0,
    isPremium: false,
    isUsingCustomProfileImage: false,
  ),
  profilePublicity: UserProfilePublicity(gender: '', region: '', birthDay: '', birthYear: '', job: '', pawoo: false),
  workspace: UserWorkspace(
    pc: '',
    monitor: '',
    tool: '',
    scanner: '',
    tablet: '',
    mouse: '',
    printer: '',
    desktop: '',
    music: '',
    desk: '',
    chair: '',
    comment: '',
  ),
);

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
  testWidgets('joined user glass follows actual outer collapse and stays stable through inner scrolling', (tester) async {
    double collapseExtent = 0;
    await tester.pumpWidget(
      _app(
        DefaultTabController(
          length: 1,
          child: Builder(
            builder: (context) {
              collapseExtent = UserCollapsibleHeaderSliver.collapseExtentFor(context, 390, _detail).roundToDouble();
              return UserDetailTabScaffold(
                detail: _detail,
                tabs: const [UserDetailTabItem(kind: 'works', label: 'Works', icon: Icons.image)],
                tabController: DefaultTabController.of(context),
                storageKey: 'glass-test',
                includeTopPadding: false,
                showBackButton: false,
                builder: (context, physics, locators) => CustomScrollView(
                  physics: physics,
                  slivers: [
                    UserDetailNestedSliverHeader(refreshSliverHeader: locators.sliverHeader),
                    const SliverToBoxAdapter(child: SizedBox(height: 2000)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView));
    List<double> glass() => tester.widgetList<FrostPinnedChromeGlass>(find.byType(FrostPinnedChromeGlass)).map((bar) => bar.opacity).toList();
    // The header and its tab bar share one glass.
    expect(glass(), [0]);
    nested.outerController.jumpTo(collapseExtent / 2);
    await tester.pump();
    expect(glass().single, closeTo(.5, .01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(glass().single, closeTo(.5, .01));
    nested.outerController.jumpTo(collapseExtent);
    nested.innerController.jumpTo(12);
    await tester.pump();
    expect(glass(), [1]);
    nested.innerController.jumpTo(0);
    nested.outerController.jumpTo(0);
    await tester.pump();
    expect(glass(), [0], reason: 'refresh-to-top has no boolean overlap flash');
    expect(tester.takeException(), isNull);
  });

  testWidgets('author without cover or introduction keeps a compact header at 2x text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        CustomScrollView(
          slivers: [
            const UserCollapsibleHeaderSliver(detail: _detail, includeTopPadding: false, showBackButton: true, bottom: SizedBox.shrink(), bottomHeight: 0),
            const SliverToBoxAdapter(child: SizedBox(height: 1000)),
          ],
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    // Without an introduction the header drops the comment block only; the
    // cover band keeps its height (an avatar wash fills it).
    final layout = UserCollapsibleHeaderLayout.forWidth(390);
    expect(layout.expandedHeight(commentHeight: 0, statsHeight: 40), lessThan(layout.expandedHeight(commentHeight: 40, statsHeight: 40)));
    final covered = UserCollapsibleHeaderLayout.forWidth(390, textScale: 2);
    expect(covered.stackedHeaderHeight, greaterThanOrEqualTo(covered.nameTop + covered.nameHeight));
  });

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
