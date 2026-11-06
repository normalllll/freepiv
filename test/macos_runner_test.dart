import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/window/app_window.dart';

/// The macOS runner is not built in CI here, so its startup contract with
/// frost_window is checked in its sources.
void main() {
  test('the macOS window starts hidden and shares the app minimum size', () {
    final xib = File('macos/Runner/Base.lproj/MainMenu.xib').readAsStringSync();
    final window = RegExp(r'<window [^>]*customClass="MainFlutterWindow"[^>]*>').firstMatch(xib)?.group(0);
    expect(window, isNotNull);
    expect(window, contains('visibleAtLaunch="NO"'), reason: 'frost_window shows it after the first frame');
    expect(window, isNot(contains('frameAutosaveName')));

    final swift = File('macos/Runner/MainFlutterWindow.swift').readAsStringSync();
    final minimum = RegExp(r'contentMinSize = NSSize\(width: (\d+), height: (\d+)\)').firstMatch(swift);
    expect(minimum, isNotNull);
    expect((double.parse(minimum!.group(1)!), double.parse(minimum.group(2)!)), (appMinimumWindowSize.width, appMinimumWindowSize.height));
    expect(swift, isNot(matches(RegExp(r'orderFront|makeKeyAndOrderFront|display: true'))), reason: 'nothing shows it early');
  });
}
