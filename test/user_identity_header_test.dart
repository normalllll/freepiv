import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/features/user_detail/presentation/user_identity_header.dart';
import 'package:freepiv/ui/compositions/avatar_flight.dart';
import 'package:freepiv/ui/compositions/work_actions.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _foldSize = Size(750, 900);

Future<void> _mount(WidgetTester tester, Size size, {double textScale = 1}) => mountPilotPage(
  tester,
  UserDetailPage(userId: 2000, userDetail: sampleUserDetail),
  size: size,
  textScale: textScale,
);

Finder get _avatar => find.byType(AppFlightAvatar);
Finder get _banner => find.byType(UserBanner);
Finder get _name => find.descendant(of: find.byType(UserIdentityHeader), matching: find.text(sampleUserDetail.user.name));
Finder get _follow => find.byType(AppFollowButton);
Finder get _more => find.descendant(of: find.byType(UserIdentityHeader), matching: find.byType(FrostMenuAnchor));
Finder get _stat => find.byType(FrostStat).first;

void main() {
  for (final (label, size) in [('phone', phoneSize), ('fold', _foldSize), ('desktop', desktopSize)]) {
    testWidgets('$label: the banner runs edge to edge, the avatar half over it, Follow and More together at the end', (tester) async {
      await _mount(tester, size);
      final banner = tester.getRect(_banner);
      expect(banner.left, 0);
      expect(banner.right, moreOrLessEquals(size.width, epsilon: 24), reason: 'only the page outline may stay');
      final avatar = tester.getRect(_avatar);
      expect(avatar.center.dy, moreOrLessEquals(banner.bottom, epsilon: 1));
      expect(avatar.left, lessThan(size.width / 4), reason: 'at the start, not centred');

      final follow = tester.getRect(_follow), more = tester.getRect(_more);
      expect(more.left - follow.right, lessThan(16), reason: 'side by side');
      expect((follow.center.dy - more.center.dy).abs(), lessThan(2));
      expect(more.right, greaterThan(size.width * .8), reason: 'at the end');
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('nothing is painted over the banner behind the status bar', (tester) async {
    await _mount(tester, phoneSize);
    expect(find.byType(FrostMediaSystemChrome), findsNothing);
  });

  testWidgets('phone: the name goes under the avatar', (tester) async {
    await _mount(tester, phoneSize);
    expect(tester.getTopLeft(_name).dy, greaterThanOrEqualTo(tester.getBottomLeft(_avatar).dy));
    expect(tester.getTopLeft(_name).dx, moreOrLessEquals(tester.getTopLeft(_avatar).dx, epsilon: 1));
  });

  testWidgets('fold: the name goes beside the avatar, below the banner, the numbers under it', (tester) async {
    await _mount(tester, _foldSize);
    expect(tester.getTopLeft(_name).dx, greaterThan(tester.getTopRight(_avatar).dx));
    expect(tester.getTopLeft(_name).dy, greaterThan(tester.getBottomLeft(_banner).dy));
    expect(tester.getTopLeft(_stat).dy, greaterThan(tester.getBottomLeft(_name).dy));
    expect(tester.getTopLeft(_stat).dx, moreOrLessEquals(tester.getTopLeft(_name).dx, epsilon: 1));
  });

  testWidgets('desktop: the numbers share the name\'s row', (tester) async {
    await _mount(tester, desktopSize);
    expect(tester.getTopLeft(_stat).dy, lessThan(tester.getBottomLeft(_name).dy));
    expect(tester.getTopLeft(_stat).dx, greaterThan(tester.getTopRight(_name).dx - 1));
  });

  for (final size in [phoneSize, _foldSize, desktopSize]) {
    testWidgets('double text fits at ${size.width.toInt()} wide', (tester) async {
      await _mount(tester, size, textScale: 2);
      expectNoLayoutErrors(tester);
    });
  }

  testWidgets('without a banner the avatar washes the same band', (tester) async {
    await mountPilotPage(tester, const UserBanner(coverUrl: null, avatarUrl: 'https://example.com/avatar.png'));
    expect(find.byType(ImageFiltered), findsOneWidget);
    await mountPilotPage(tester, const UserBanner(coverUrl: '', avatarUrl: 'https://example.com/avatar.png'));
    expect(find.byType(ImageFiltered), findsOneWidget, reason: 'an empty url is no banner');
    await mountPilotPage(tester, const UserBanner(coverUrl: 'https://example.com/banner.png', avatarUrl: 'https://example.com/avatar.png'));
    expect(find.byType(ImageFiltered), findsNothing);
  });

  group('the status bar over a banner', () {
    Future<ui.Image> picture(Color top, Color bottom) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 64, 32), Paint()..color = top);
      canvas.drawRect(const Rect.fromLTWH(0, 32, 64, 32), Paint()..color = bottom);
      return recorder.endRecording().toImage(64, 64);
    }

    Future<Brightness?> iconsOver(WidgetTester tester, Color top, Color bottom) =>
        tester.runAsync<Brightness?>(() async => statusIconsOverBanner(await picture(top, bottom), const Size(200, 200), 40));

    const white = Color(0xFFFFFFFF), black = Color(0xFF000000);

    testWidgets('the icons follow the strip behind them, not the rest of the picture', (tester) async {
      expect(await iconsOver(tester, white, black), Brightness.dark);
      expect(await iconsOver(tester, black, white), Brightness.light);
    });

    testWidgets('a mid tone that white icons still read on keeps them', (tester) async {
      expect(await iconsOver(tester, const Color(0xFF6A4FB3), black), Brightness.light);
    });
  });
}
