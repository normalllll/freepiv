import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  final body = ['[chapter:One]', '$readerParagraph a', '[uploadedimage:1]', '$readerParagraph b'].join('\n\n');

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('a ${kind.name} tap on a thumbnail\'s open button leaves no tooltip', (tester) async {
      await mountReader(tester, history, size: const Size(1400, 900), text: readerText(body));
      await showReaderBars(tester);
      await tester.tap(find.byKey(const ValueKey('reader-illustrations')));
      await settlePilot(tester);
      final block = readerController(tester).model.imageBlocks.single;
      openedExtras.clear();
      final gesture = await tester.createGesture(kind: kind);
      final button = find.byKey(ValueKey('reader-illustration-open-$block'));
      await gesture.addPointer(location: tester.getCenter(button));
      await gesture.moveTo(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.down(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));
      await settlePilot(tester);
      expect(openedExtras.whereType<OriginalImageViewerArgs>(), isNotEmpty);
      expect(find.text('Open picture'), findsNothing, reason: 'no tooltip once the picture is opened');
    });
  }
}
