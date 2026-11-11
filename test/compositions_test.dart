import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/ui/compositions/composer_bar.dart';
import 'package:freepiv/ui/compositions/identity_header.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';

Widget _host(Widget child, {double width = 800, double textScale = 1}) => FrostApp.router(
  config: freepivFrostConfig,
  title: 'test',
  routerConfig: GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => MediaQuery(
          data: MediaQueryData(size: Size(width, 700), textScaler: TextScaler.linear(textScale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ],
  ),
);

void main() {
  group('composer bar', () {
    testWidgets('grows to five lines, Enter adds a line, and a reply can be closed', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var sent = 0;
      var closed = 0;
      await tester.pumpWidget(
        _host(
          AppComposerBar(
            controller: controller,
            placeholder: 'Write a comment',
            sendLabel: 'Send',
            onSend: () => sent++,
            emojiLabel: 'Emoji',
            emojiPanel: (context, close) => const SizedBox(),
            stampLabel: 'Stamp',
            stampPanel: (context, close) => const SizedBox(),
            replyLabel: 'Replying to Mika',
            onCancelReply: () => closed++,
          ),
          width: 320,
        ),
      );
      expect(find.text('Replying to Mika'), findsOneWidget);
      final field = tester.widget<FrostTextField>(find.byType(FrostTextField));
      expect(field.maxLines, AppComposerBar.maxLines);
      expect(field.appearance, FrostFieldAppearance.composer);
      expect(field.textInputAction, TextInputAction.newline);
      await tester.tap(_button('Send'));
      expect(sent, 1);
      await tester.tap(_button('Cancel'));
      expect(closed, 1);
      // Field, emoji, stamp and send share one row even at 320.
      final y = tester.getCenter(_button('Send')).dy;
      expect(tester.getCenter(_button('Emoji')).dy, y);
      expect(tester.takeException(), isNull);
    });
  });

  group('identity header', () {
    Widget header() => AppIdentityHeader(
      avatar: const FrostAvatar.person(name: 'Mika', size: FrostAvatarSize.xxlarge),
      name: 'Mika with a rather long display name',
      subtitle: '@mika',
      stats: const [
        AppIdentityStat(value: '120', caption: 'Following'),
        AppIdentityStat(value: '8', caption: 'Works'),
      ],
      primary: FrostButton.prominent(label: 'Follow', onPressed: () {}),
      more: [FrostMenuAction('Copy link', onSelected: () {})],
    );

    testWidgets('side by side on wide content', (tester) async {
      await tester.pumpWidget(_host(header(), width: 900));
      final avatar = tester.getCenter(find.byType(FrostAvatar));
      final follow = tester.getCenter(find.text('Follow'));
      expect(follow.dx, greaterThan(avatar.dx));
      expect((follow.dy - avatar.dy).abs(), lessThan(40));
    });

    testWidgets('centred and stacked on narrow content, follow taking the row', (tester) async {
      await tester.pumpWidget(_host(header(), width: 390, textScale: 2));
      final avatar = tester.getCenter(find.byType(FrostAvatar));
      expect(avatar.dx, closeTo(195, 1));
      expect(tester.getCenter(find.text('Follow')).dy, greaterThan(avatar.dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('page error', () {
    testWidgets('not found has the header and no retry', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 600,
            child: AppPageError.notFound(message: 'Not found', title: 'Work'),
          ),
        ),
      );
      expect(find.byType(FrostPageHeader), findsOneWidget);
      expect(find.text('Not found'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('an error retries', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 600,
            child: AppPageError.fromError(error: StateError('offline'), onRetry: () => retried++),
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });
}

Finder _button(String label) => find.byWidgetPredicate((widget) => widget is FrostButton && widget.label == label);
