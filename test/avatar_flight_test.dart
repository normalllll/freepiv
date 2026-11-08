import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/ui/compositions/avatar_flight.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

Future<void> _mount(WidgetTester tester, {Size size = desktopSize, double textScale = 1, bool reducedMotion = false}) => mountPilotPage(
  tester,
  Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: UserDetailPage(userId: 2000, userDetail: sampleUserDetail),
    ),
  ),
  size: size,
  textScale: textScale,
);

ScrollController _outer(WidgetTester tester) => tester.state<NestedScrollViewState>(find.byType(NestedScrollView)).outerController;

AppAvatarFlight _flight(WidgetTester tester) => AppAvatarFlight.of(tester.element(find.byType(NestedScrollView)));

Future<void> _scrollTo(WidgetTester tester, double offset) async {
  _outer(tester).jumpTo(offset);
  await tester.pump();
}

Finder _visibilityOf(Finder inner) => find.ancestor(of: inner, matching: find.byType(Visibility)).first;

Finder get _large => find.descendant(of: find.byType(AppFlightAvatar), matching: find.byType(AppUserAvatar));
Finder get _slot => find.descendant(of: find.byType(AppFlightTitle), matching: find.byType(AppUserAvatar));
Finder get _name => find.descendant(of: find.byType(AppFlightTitle), matching: find.text(sampleUserDetail.user.name));

bool _shown(WidgetTester tester, Finder inner) => tester.widget<Visibility>(_visibilityOf(inner)).visible;

void main() {
  for (final (label, size, textScale) in [('wide', desktopSize, 1.0), ('narrow', phoneSize, 1.0), ('narrow at double text', phoneSize, 2.0)]) {
    testWidgets('$label: the avatar stays with the identity, flies, and lands in the header as the tabs stick', (tester) async {
      await _mount(tester, size: size, textScale: textScale);
      final flight = _flight(tester);
      expect(flight.phase.value, AppAvatarFlightPhase.identity);
      expect(_shown(tester, _large), isTrue);
      expect(_shown(tester, _slot), isFalse, reason: 'only the real one at the start');
      expect(_shown(tester, _name), isFalse);

      final sticks = _outer(tester).position.maxScrollExtent;
      await _scrollTo(tester, sticks * .8);
      expect(flight.phase.value, AppAvatarFlightPhase.flying);
      expect(_shown(tester, _large), isFalse, reason: 'hidden in flight');
      expect(_shown(tester, _slot), isFalse);
      final mid = flight.flyingRect!;
      final large = tester.getSize(_large).width, small = tester.getSize(_slot).width;
      expect(mid.width, inExclusiveRange(small, large), reason: 'between the two sizes');
      expect(mid.height, moreOrLessEquals(mid.width, epsilon: .01));

      await _scrollTo(tester, sticks - 1);
      final slot = tester.getRect(_slot);
      expect(flight.flyingRect!.width, moreOrLessEquals(slot.width, epsilon: 1), reason: 'almost there');
      expect(flight.flyingRect!.center.dy, moreOrLessEquals(slot.center.dy, epsilon: 1));

      await _scrollTo(tester, sticks);
      expect(flight.phase.value, AppAvatarFlightPhase.header);
      expect(_shown(tester, _slot), isTrue, reason: 'only the real one at the end');
      expect(_shown(tester, _name), isTrue);
      expectNoLayoutErrors(tester);

      await _scrollTo(tester, 0);
      expect(flight.phase.value, AppAvatarFlightPhase.identity);
      expect(_shown(tester, _large), isTrue);
    });
  }

  testWidgets('the flying avatar never takes a press and is a single avatar', (tester) async {
    await _mount(tester);
    await _scrollTo(tester, _outer(tester).position.maxScrollExtent * .8);
    final flow = find.byType(Flow);
    expect(flow, findsOneWidget);
    expect(find.ancestor(of: flow, matching: find.byType(IgnorePointer)), findsWidgets);
    expect(find.descendant(of: flow, matching: find.byType(FrostAvatar)), findsOneWidget);
  });

  testWidgets('with reduced motion nothing flies: the header avatar and name come when the identity has gone', (tester) async {
    await _mount(tester, reducedMotion: true);
    final flight = _flight(tester);
    final sticks = _outer(tester).position.maxScrollExtent;
    await _scrollTo(tester, sticks * .8);
    expect(flight.phase.value, AppAvatarFlightPhase.identity);
    expect(find.byType(Flow), findsNothing);
    expect(_shown(tester, _name), isFalse);
    await _scrollTo(tester, sticks);
    expect(flight.phase.value, AppAvatarFlightPhase.header);
    expect(_shown(tester, _slot), isTrue);
    expect(_shown(tester, _name), isTrue);
  });
}
