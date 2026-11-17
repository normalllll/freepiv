import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Starts the settings from [values] already in the box.
Future<Box<dynamic>> _start(Directory directory, [Map<String, dynamic> values = const {}]) async {
  Hive.init(directory.path);
  final box = await Hive.openBox<dynamic>(AppSettings.boxName);
  await box.putAll(values);
  await AppSettings.initialize(store: HiveAppSettingsStore(box));
  return box;
}

/// Writes through [write], then restarts on the same box.
Future<void> _restart(Directory directory, void Function() write) async {
  final box = await _start(directory);
  write();
  await Future<void>.delayed(Duration.zero);
  await box.flush();
  await box.close();
  await _start(directory);
}

void main() {
  late Directory directory;

  setUp(() async => directory = await Directory.systemTemp.createTemp('freepiv_reader_settings_'));
  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('a fresh install reads every reader key as its default', () async {
    await _start(directory);
    expect(AppSettings.readerFontSize, 18);
    expect(AppSettings.readerLineSpacing, ReaderLineSpacing.regular);
    expect(AppSettings.readerMargins, ReaderMargins.regular);
    expect(AppSettings.readerTheme, ReaderTheme.app);
    expect(AppSettings.readerFont, ReaderFont.sans);
    expect(AppSettings.readerIndent, isTrue);
    expect(AppSettings.readerPageMode, ReaderPageMode.scroll);
    expect(AppSettings.readerPageAnimation, ReaderPageAnimation.slide);
    expect(AppSettings.readerTapZones, ReaderTapZones.sides);
    expect(AppSettings.readerAutoScrollSpeed, ReaderAutoScrollSpeed.normal);
    expect(AppSettings.readerVolumeKeys, isFalse);
  });

  test('every reader key survives a restart', () async {
    await _restart(directory, () {
      AppSettings.readerLineSpacing = ReaderLineSpacing.relaxed;
      AppSettings.readerMargins = ReaderMargins.wide;
      AppSettings.readerTheme = ReaderTheme.night;
      AppSettings.readerFont = ReaderFont.kai;
      AppSettings.readerIndent = false;
      AppSettings.readerPageMode = ReaderPageMode.paged;
      AppSettings.readerPageAnimation = ReaderPageAnimation.cover;
      AppSettings.readerTapZones = ReaderTapZones.forward;
    });
    expect(AppSettings.readerLineSpacing, ReaderLineSpacing.relaxed);
    expect(AppSettings.readerMargins, ReaderMargins.wide);
    expect(AppSettings.readerTheme, ReaderTheme.night);
    expect(AppSettings.readerFont, ReaderFont.kai);
    expect(AppSettings.readerIndent, isFalse);
    expect(AppSettings.readerPageMode, ReaderPageMode.paged);
    expect(AppSettings.readerPageAnimation, ReaderPageAnimation.cover);
    expect(AppSettings.readerTapZones, ReaderTapZones.forward);
  });

  test('invalid stored values fall back without disturbing the others', () async {
    await _start(directory, {
      'readerLineSpacing': 'tight',
      'readerMargins': 3,
      'readerTheme': 'sepia',
      'readerFont': '',
      'readerIndent': 'yes',
      'readerPageMode': 'flip',
      'readerPageAnimation': null,
      'readerTapZones': 1.5,
      'readerFontSize': 22.0,
    });
    expect(AppSettings.readerLineSpacing, ReaderLineSpacing.regular);
    expect(AppSettings.readerMargins, ReaderMargins.regular);
    expect(AppSettings.readerTheme, ReaderTheme.app);
    expect(AppSettings.readerFont, ReaderFont.sans);
    expect(AppSettings.readerIndent, isTrue);
    expect(AppSettings.readerPageMode, ReaderPageMode.scroll);
    expect(AppSettings.readerPageAnimation, ReaderPageAnimation.slide);
    expect(AppSettings.readerTapZones, ReaderTapZones.sides);
    expect(AppSettings.readerFontSize, 22);
  });

  group('the retired line height', () {
    const cases = <(double, ReaderLineSpacing)>[
      (1.45, ReaderLineSpacing.compact),
      (1.674, ReaderLineSpacing.compact),
      (1.675, ReaderLineSpacing.regular),
      (1.78, ReaderLineSpacing.regular),
      (1.924, ReaderLineSpacing.regular),
      (1.925, ReaderLineSpacing.relaxed),
      (2.2, ReaderLineSpacing.relaxed),
    ];
    for (final (stored, expected) in cases) {
      test('$stored becomes ${expected.name} and the old key is removed', () async {
        final box = await _start(directory, {'readerLineHeight': stored});
        expect(AppSettings.readerLineSpacing, expected);
        await Future<void>.delayed(Duration.zero);
        expect(box.containsKey('readerLineHeight'), isFalse);
        expect(box.get('readerLineSpacing'), expected.name);
      });
    }

    test('a value that is not a number writes nothing and is removed', () async {
      final box = await _start(directory, {'readerLineHeight': 'wide'});
      expect(AppSettings.readerLineSpacing, ReaderLineSpacing.regular);
      await Future<void>.delayed(Duration.zero);
      expect(box.containsKey('readerLineHeight'), isFalse);
      expect(box.containsKey('readerLineSpacing'), isFalse);
    });

    test('a saved line spacing is not overwritten', () async {
      final box = await _start(directory, {'readerLineHeight': 2.2, 'readerLineSpacing': 'compact'});
      expect(AppSettings.readerLineSpacing, ReaderLineSpacing.compact);
      await Future<void>.delayed(Duration.zero);
      expect(box.get('readerLineSpacing'), 'compact');
      expect(box.containsKey('readerLineHeight'), isFalse);
    });
  });

  group('the retired auto scroll speed', () {
    const cases = <(num, ReaderAutoScrollSpeed)>[
      (12, ReaderAutoScrollSpeed.verySlow),
      (17, ReaderAutoScrollSpeed.verySlow),
      (18.5, ReaderAutoScrollSpeed.slow),
      (29, ReaderAutoScrollSpeed.slow),
      (36, ReaderAutoScrollSpeed.normal),
      (47, ReaderAutoScrollSpeed.normal),
      (49, ReaderAutoScrollSpeed.fast),
      (60, ReaderAutoScrollSpeed.fast),
      (77, ReaderAutoScrollSpeed.fast),
      (79, ReaderAutoScrollSpeed.veryFast),
      (96, ReaderAutoScrollSpeed.veryFast),
      (500, ReaderAutoScrollSpeed.veryFast),
    ];
    for (final (stored, expected) in cases) {
      test('$stored becomes ${expected.name} and the old key is removed', () async {
        final box = await _start(directory, {'readerAutoScrollSpeed': stored});
        expect(AppSettings.readerAutoScrollSpeed, expected);
        await Future<void>.delayed(Duration.zero);
        expect(box.containsKey('readerAutoScrollSpeed'), isFalse);
        expect(box.get('readerAutoScrollStep'), expected.name);
      });
    }

    test('a value that is not a number writes nothing and is removed', () async {
      final box = await _start(directory, {'readerAutoScrollSpeed': 'quick'});
      expect(AppSettings.readerAutoScrollSpeed, ReaderAutoScrollSpeed.normal);
      await Future<void>.delayed(Duration.zero);
      expect(box.containsKey('readerAutoScrollSpeed'), isFalse);
      expect(box.containsKey('readerAutoScrollStep'), isFalse);
    });

    test('a saved step is not overwritten', () async {
      final box = await _start(directory, {'readerAutoScrollSpeed': 96.0, 'readerAutoScrollStep': 'slow'});
      expect(AppSettings.readerAutoScrollSpeed, ReaderAutoScrollSpeed.slow);
      await Future<void>.delayed(Duration.zero);
      expect(box.get('readerAutoScrollStep'), 'slow');
      expect(box.containsKey('readerAutoScrollSpeed'), isFalse);
    });

    test('an unknown step falls back to normal', () async {
      await _start(directory, {'readerAutoScrollStep': 'warp'});
      expect(AppSettings.readerAutoScrollSpeed, ReaderAutoScrollSpeed.normal);
    });

    test('the step survives a restart', () async {
      await _restart(directory, () => AppSettings.readerAutoScrollSpeed = ReaderAutoScrollSpeed.veryFast);
      expect(AppSettings.readerAutoScrollSpeed, ReaderAutoScrollSpeed.veryFast);
    });
  });

  group('the shortcuts hint', () {
    test('is unseen on a fresh install and stays seen after a restart', () async {
      await _start(directory);
      expect(AppSettings.readerShortcutsHintSeen, isFalse);
      await _restart(directory, () => AppSettings.readerShortcutsHintSeen = true);
      expect(AppSettings.readerShortcutsHintSeen, isTrue);
    });

    test('a stored value that is not a bool reads as unseen', () async {
      await _start(directory, {'readerShortcutsHintSeen': 'yes'});
      expect(AppSettings.readerShortcutsHintSeen, isFalse);
    });
  });

  test('the providers write every reader setting through', () async {
    await _restart(directory, () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(readerSettingsProvider.notifier)
        ..setLineSpacing(ReaderLineSpacing.compact)
        ..setMargins(ReaderMargins.narrow)
        ..setTheme(ReaderTheme.paper)
        ..setFont(ReaderFont.serif)
        ..setIndent(false)
        ..setPageMode(ReaderPageMode.paged)
        ..setPageAnimation(ReaderPageAnimation.none)
        ..setTapZones(ReaderTapZones.forward);
      final state = container.read(readerSettingsProvider);
      expect(state.lineSpacing, ReaderLineSpacing.compact);
      expect(state.margins, ReaderMargins.narrow);
      expect(state.theme, ReaderTheme.paper);
      expect(state.font, ReaderFont.serif);
      expect(state.indent, isFalse);
      expect(state.pageMode, ReaderPageMode.paged);
      expect(state.pageAnimation, ReaderPageAnimation.none);
      expect(state.tapZones, ReaderTapZones.forward);
    });
    expect(AppSettings.readerLineSpacing, ReaderLineSpacing.compact);
    expect(AppSettings.readerMargins, ReaderMargins.narrow);
    expect(AppSettings.readerTheme, ReaderTheme.paper);
    expect(AppSettings.readerFont, ReaderFont.serif);
    expect(AppSettings.readerIndent, isFalse);
    expect(AppSettings.readerPageMode, ReaderPageMode.paged);
    expect(AppSettings.readerPageAnimation, ReaderPageAnimation.none);
    expect(AppSettings.readerTapZones, ReaderTapZones.forward);
  });

  test('settings that differ in any field are not equal', () {
    ReaderSettings settings({ReaderTheme theme = ReaderTheme.app, bool indent = true}) => ReaderSettings(
      textSize: 18,
      lineSpacing: ReaderLineSpacing.regular,
      margins: ReaderMargins.regular,
      theme: theme,
      font: ReaderFont.sans,
      indent: indent,
      pageMode: ReaderPageMode.scroll,
      pageAnimation: ReaderPageAnimation.slide,
      tapZones: ReaderTapZones.sides,
      autoScrollSpeed: ReaderAutoScrollSpeed.normal,
      volumeKeys: false,
    );
    expect(settings(), settings());
    expect(settings().hashCode, settings().hashCode);
    expect(settings(), isNot(settings(theme: ReaderTheme.black)));
    expect(settings(), isNot(settings(indent: false)));
  });
}
