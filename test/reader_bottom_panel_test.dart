import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/features/novel/presentation/reader/chrome/reader_bottom_panel.dart';

import 'support/memory_history.dart';
import 'support/reader_harness.dart';

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  testWidgets('the chapter row shows with several chapters', (tester) async {
    await mountReader(tester, history);
    await showReaderBars(tester);
    expect(find.byKey(const ValueKey('reader-chapter-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-progress')), findsOneWidget);
  });

  testWidgets('a single chapter has no chapter row and keeps the rest of the panel', (tester) async {
    await mountReader(tester, history, text: readerText('$readerParagraph\n\n$readerParagraph 2'));
    await showReaderBars(tester);
    expect(find.byType(ReaderBottomPanel), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-chapter-title')), findsNothing);
    expect(find.byKey(const ValueKey('reader-progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-settings')), findsOneWidget);
  });
}
