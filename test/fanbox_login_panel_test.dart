import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/fanbox/logic.dart';
import 'package:freepiv/features/fanbox/login_panel.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// Signs in only with the right Cookie, recording what it was given.
final _given = <String>[];

class _Session extends FanboxSession {
  @override
  Future<String?> build() async => null;

  @override
  Future<bool> signIn(String input, {bool Function()? canCommit}) async {
    _given.add(input);
    if (input != 'good') throw StateError('rejected');
    state = const AsyncData('good');
    return true;
  }
}

Future<int> _mount(WidgetTester tester, {Uint8List? file, Size size = desktopSize, double textScale = 1}) async {
  _given.clear();
  var signedIn = 0;
  await mountPilotPage(
    tester,
    Center(
      child: FanboxLoginPanel(
        onSignedIn: () => signedIn++,
        browserAvailable: () async => true,
        readSessionFile: () async => file,
      ),
    ),
    size: size,
    textScale: textScale,
    overrides: {fanboxSessionProvider: fanboxSessionProvider.overrideWith(_Session.new)},
  );
  return signedIn;
}

void main() {
  testWidgets('the panel says what it does and offers the browser, the Cookie and a session file', (tester) async {
    await _mount(tester);
    expect(find.text(t.fanbox.login), findsOneWidget);
    expect(find.text(t.fanbox.browserHelp), findsOneWidget);
    expect(find.text(t.fanbox.manualLogin), findsOneWidget);
    expect(find.text(t.fanbox.importSession), findsOneWidget);
    expect(tester.widgetList<FrostButton>(find.byType(FrostButton)).where((button) => button.label == t.fanbox.browserLogin), hasLength(1));
  });

  testWidgets('a wrong Cookie keeps the form open with the reason; the right one signs in', (tester) async {
    var signedIn = 0;
    _given.clear();
    await mountPilotPage(
      tester,
      Center(child: FanboxLoginPanel(onSignedIn: () => signedIn++, browserAvailable: () async => true)),
      overrides: {fanboxSessionProvider: fanboxSessionProvider.overrideWith(_Session.new)},
    );
    await tester.tap(find.text(t.fanbox.manualLogin));
    await settlePilot(tester);
    final field = find.descendant(of: find.byType(FrostTextField), matching: find.byType(EditableText));
    await tester.enterText(field, 'bad');
    await tester.tap(find.text(t.fanbox.login).last);
    await settlePilot(tester);
    expect(_given, ['bad']);
    expect(find.text(t.fanbox.loginFailed), findsWidgets, reason: 'the form stays open and says why');
    expect(signedIn, 0);

    await tester.enterText(field, 'good');
    await tester.tap(find.text(t.fanbox.login).last);
    await settlePilot(tester);
    expect(_given.last, 'good');
    expect(signedIn, 1);
    expect(find.byType(FrostTextField), findsNothing, reason: 'the form closed');
  });

  testWidgets('a session file over 64 KB is refused without reading it as a session', (tester) async {
    final big = Uint8List(fanboxSessionFileLimit + 1);
    await _mount(tester, file: big);
    await tester.tap(find.text(t.fanbox.importSession));
    await settlePilot(tester);
    expect(_given, isEmpty);
    expect(find.text(t.fanbox.loginFailed), findsOneWidget);

    final good = Uint8List.fromList('good'.codeUnits);
    await _mount(tester, file: good);
    await tester.tap(find.text(t.fanbox.importSession));
    await settlePilot(tester);
    expect(_given, ['good']);
  });

  testWidgets('fits a phone at double text size', (tester) async {
    await _mount(tester, size: phoneSize, textScale: 2);
    expectNoLayoutErrors(tester);
  });
}
