import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/transparency_logic.dart';
import 'package:frost_ui/frost_ui.dart';

Widget _surface({required bool reduceTransparency, bool highContrast = false, FrostSurfaceEdge edge = FrostSurfaceEdge.material}) {
  return ProviderScope(
    key: ValueKey((reduceTransparency, highContrast, edge)),
    overrides: [reduceTransparencyProvider.overrideWithValue(reduceTransparency)],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: _TransparencyScope(child: child!),
      ),
      home: Scaffold(
        body: Center(
          child: FrostSurface(role: FrostSurfaceRole.glassPanel, edge: edge, child: const SizedBox(width: 300, height: 180)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('large card uses bounded backdrop blur and respects solid surface modes', (tester) async {
    await tester.pumpWidget(_surface(reduceTransparency: false));
    final panel = find.byType(FrostSurface);
    expect(find.descendant(of: panel, matching: find.byType(BackdropFilter)), findsOneWidget);
    expect(_edgeCount(tester, panel), 1);

    await tester.pumpWidget(_surface(reduceTransparency: true));
    expect(tester.widget<BackdropFilter>(find.descendant(of: panel, matching: find.byType(BackdropFilter))).enabled, isFalse);
    expect(_edgeCount(tester, panel), 1);

    await tester.pumpWidget(_surface(reduceTransparency: false, highContrast: true));
    expect(tester.widget<BackdropFilter>(find.descendant(of: panel, matching: find.byType(BackdropFilter))).enabled, isFalse);
    expect(_edgeCount(tester, panel), 1);
  });

  testWidgets('edge-free glass keeps blur and clip, with one separating or high-contrast boundary', (tester) async {
    await tester.pumpWidget(_surface(reduceTransparency: false, edge: FrostSurfaceEdge.none));
    final panel = find.byType(FrostSurface);
    expect(find.descendant(of: panel, matching: find.byType(BackdropFilter)), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.byType(ClipRRect)), findsOneWidget);
    // Light glass keeps one functional neutral line against the pale canvas,
    // never a decorative highlight on top of it.
    expect(_edgeCount(tester, panel), 1);

    await tester.pumpWidget(_surface(reduceTransparency: true, edge: FrostSurfaceEdge.none));
    expect(tester.widget<BackdropFilter>(find.descendant(of: panel, matching: find.byType(BackdropFilter))).enabled, isFalse);
    expect(_edgeCount(tester, panel), 0);

    await tester.pumpWidget(_surface(reduceTransparency: false, highContrast: true, edge: FrostSurfaceEdge.none));
    expect(tester.widget<BackdropFilter>(find.descendant(of: panel, matching: find.byType(BackdropFilter))).enabled, isFalse);
    expect(_edgeCount(tester, panel), 1);
  });

  testWidgets('changing transparency retains the switch and its slide animation', (tester) async {
    final container = ProviderContainer(overrides: [reduceTransparencyProvider.overrideWith(_TestReduceTransparency.new)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => _TransparencyScope(child: child!),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FrostSurface(
                role: FrostSurfaceRole.glassPanel,
                edge: FrostSurfaceEdge.none,
                child: SwitchListTile.adaptive(
                  title: const Text('Reduce transparency'),
                  value: ref.watch(reduceTransparencyProvider),
                  onChanged: (value) => (ref.read(reduceTransparencyProvider.notifier) as _TestReduceTransparency).change(value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final before = tester.element(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(reduceTransparencyProvider), isTrue);
    expect(identical(tester.element(find.byType(Switch)), before), isTrue);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(tester.widget<BackdropFilter>(find.byType(BackdropFilter)).enabled, isFalse);
  });
}

// Mirrors the app root, which hands the setting to Frost surfaces.
class _TransparencyScope extends ConsumerWidget {
  const _TransparencyScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FrostScope(reduceTransparency: ref.watch(reduceTransparencyProvider), child: child);
}

class _TestReduceTransparency extends ReduceTransparency {
  @override
  bool build() => false;

  void change(bool enabled) => state = enabled;
}

int _edgeCount(WidgetTester tester, Finder panel) {
  return find
      .descendant(of: panel, matching: find.byType(DecoratedBox))
      .evaluate()
      .map((element) => element.widget as DecoratedBox)
      .where((box) => box.decoration is BoxDecoration && (box.decoration as BoxDecoration).border != null)
      .length;
}
