import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';

void main() {
  _tickerModeCase();
  testWidgets('the menu grows out of its anchor, closes after a choice, and Escape closes it', (tester) async {
    String? picked;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: FrostMenuAnchor(
                menuChildren: [
                  FrostMenuItem(onPressed: () => picked = 'one', child: const Text('One')),
                  FrostMenuItem(onPressed: () => picked = 'two', child: const Text('Two')),
                ],
                builder: (context, focusNode, toggle) => TextButton(focusNode: focusNode, onPressed: toggle, child: const Text('Open')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    // Mid-reveal the panel is still scaling up from its anchor side.
    final growing = tester.getRect(find.text('One'));
    await tester.pumpAndSettle();
    final open = tester.getRect(find.text('One'));
    expect(open.top, greaterThanOrEqualTo(tester.getRect(find.text('Open')).bottom - 1), reason: 'below the anchor');
    expect(growing.width, lessThanOrEqualTo(open.width));

    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(picked, 'two');
    expect(find.text('One'), findsNothing, reason: 'a choice closes the menu');

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing, reason: 'Escape closes it');
  });
}

void _tickerModeCase() {
  testWidgets('a menu whose subtree stops ticking closes at once instead of freezing mid-close', (tester) async {
    final ticking = ValueNotifier(true);
    addTearDown(ticking.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder(
                valueListenable: ticking,
                builder: (context, enabled, _) => TickerMode(
                  enabled: enabled,
                  child: FrostMenuAnchor(
                    menuChildren: [FrostMenuItem(onPressed: () {}, child: const Text('Delete'))],
                    builder: (context, focusNode, toggle) => TextButton(focusNode: focusNode, onPressed: toggle, child: const Text('More')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    // Like tapping outside the download panel: the menu starts closing and
    // the panel stops its tickers in the same frame.
    await tester.tapAt(const Offset(5, 5));
    ticking.value = false;
    await tester.pump();
    await tester.pump();
    expect(find.text('Delete'), findsNothing);
  });
}
