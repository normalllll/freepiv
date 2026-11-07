import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

/// The Frost theme built from [freepivFrostConfig], for tests that host a
/// widget in a bare app to choose the platform; the app itself takes its
/// theme from FrostApp.
abstract final class TestTheme {
  static ThemeData light({required TargetPlatform platform, required Locale locale}) =>
      FrostTheme.build(config: freepivFrostConfig, brightness: Brightness.light, platform: platform, locale: locale, tone: FrostTone.neutral);

  static ThemeData dark({required TargetPlatform platform, required Locale locale}) =>
      FrostTheme.build(config: freepivFrostConfig, brightness: Brightness.dark, platform: platform, locale: locale, tone: FrostTone.neutral);
}
