import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/automation_entry.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('on Android the state names the package and the instance, without a window handle', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final native = automationState()['native']! as Map<String, Object?>;
    expect(native.keys, unorderedEquals(['pid', 'package', 'instanceToken']));
    expect(native['instanceToken'], instanceToken);
    expect(instanceToken, isNotEmpty);
  });

  test('on other desktops the state holds the process id alone', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect((automationState()['native']! as Map<String, Object?>).keys, ['pid']);
  });
}
