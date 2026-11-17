import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_input.dart';

KeyDownEvent _down(LogicalKeyboardKey key) => KeyDownEvent(physicalKey: PhysicalKeyboardKey.keyQ, logicalKey: key, timeStamp: Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => HardwareKeyboard.instance.clearState());

  group('keys', () {
    const scroll = ReaderPageMode.scroll;
    const paged = ReaderPageMode.paged;

    final both = {
      LogicalKeyboardKey.space: ReaderCommand.nextScreen,
      LogicalKeyboardKey.pageDown: ReaderCommand.nextScreen,
      LogicalKeyboardKey.arrowRight: ReaderCommand.nextScreen,
      LogicalKeyboardKey.pageUp: ReaderCommand.previousScreen,
      LogicalKeyboardKey.arrowLeft: ReaderCommand.previousScreen,
      LogicalKeyboardKey.bracketRight: ReaderCommand.nextChapter,
      LogicalKeyboardKey.bracketLeft: ReaderCommand.previousChapter,
      LogicalKeyboardKey.home: ReaderCommand.start,
      LogicalKeyboardKey.end: ReaderCommand.end,
      LogicalKeyboardKey.keyT: ReaderCommand.contents,
      LogicalKeyboardKey.escape: ReaderCommand.escape,
    };

    for (final MapEntry(:key, :value) in both.entries) {
      test('${key.keyLabel} is $value in both modes', () {
        expect(readerCommandFor(_down(key), mode: scroll), value);
        expect(readerCommandFor(_down(key), mode: paged), value);
      });
    }

    test('up and down scroll lines in scroll mode and turn pages in paged mode', () {
      expect(readerCommandFor(_down(LogicalKeyboardKey.arrowDown), mode: scroll), ReaderCommand.lineDown);
      expect(readerCommandFor(_down(LogicalKeyboardKey.arrowUp), mode: scroll), ReaderCommand.lineUp);
      expect(readerCommandFor(_down(LogicalKeyboardKey.arrowDown), mode: paged), ReaderCommand.nextScreen);
      expect(readerCommandFor(_down(LogicalKeyboardKey.arrowUp), mode: paged), ReaderCommand.previousScreen);
    });

    test('shift and space goes back', () {
      HardwareKeyboard.instance.handleKeyEvent(
        const KeyDownEvent(physicalKey: PhysicalKeyboardKey.shiftLeft, logicalKey: LogicalKeyboardKey.shiftLeft, timeStamp: Duration.zero),
      );
      expect(readerCommandFor(_down(LogicalKeyboardKey.space), mode: scroll), ReaderCommand.previousScreen);
      expect(readerCommandFor(_down(LogicalKeyboardKey.space), mode: paged), ReaderCommand.previousScreen);
    });

    test('control, meta and alt leave keys to shortcuts', () {
      for (final modifier in [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.altLeft]) {
        final physical = switch (modifier) {
          LogicalKeyboardKey.controlLeft => PhysicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.metaLeft => PhysicalKeyboardKey.metaLeft,
          _ => PhysicalKeyboardKey.altLeft,
        };
        HardwareKeyboard.instance.handleKeyEvent(KeyDownEvent(physicalKey: physical, logicalKey: modifier, timeStamp: Duration.zero));
        expect(readerCommandFor(_down(LogicalKeyboardKey.arrowRight), mode: scroll), isNull);
        HardwareKeyboard.instance.clearState();
      }
    });

    test('repeats act like presses; releases and other keys do nothing', () {
      const repeat = KeyRepeatEvent(physicalKey: PhysicalKeyboardKey.pageDown, logicalKey: LogicalKeyboardKey.pageDown, timeStamp: Duration.zero);
      expect(readerCommandFor(repeat, mode: scroll), ReaderCommand.nextScreen);
      const up = KeyUpEvent(physicalKey: PhysicalKeyboardKey.pageDown, logicalKey: LogicalKeyboardKey.pageDown, timeStamp: Duration.zero);
      expect(readerCommandFor(up, mode: scroll), isNull);
      expect(readerCommandFor(_down(LogicalKeyboardKey.keyA), mode: scroll), isNull);
      expect(readerCommandFor(_down(LogicalKeyboardKey.keyW), mode: paged), isNull);
    });
  });

  group('tap zones', () {
    const size = Size(900, 600);

    test('sides: left third back, right third forward, middle third toggles the bars', () {
      for (final y in [10.0, 300.0, 590.0]) {
        expect(readerTapActionFor(Offset(10, y), size, ReaderTapZones.sides), ReaderTapAction.back);
        expect(readerTapActionFor(Offset(450, y), size, ReaderTapZones.sides), ReaderTapAction.toggleBars);
        expect(readerTapActionFor(Offset(890, y), size, ReaderTapZones.sides), ReaderTapAction.forward);
      }
    });

    test('forward: the centre cell toggles the bars, everything else goes forward', () {
      expect(readerTapActionFor(const Offset(450, 300), size, ReaderTapZones.forward), ReaderTapAction.toggleBars);
      for (final point in const [Offset(10, 10), Offset(450, 10), Offset(890, 300), Offset(10, 300), Offset(450, 590), Offset(890, 590)]) {
        expect(readerTapActionFor(point, size, ReaderTapZones.forward), ReaderTapAction.forward, reason: '$point');
      }
    });
  });
}
