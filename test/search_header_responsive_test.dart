import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_header.dart';
import 'package:freepiv/i18n/strings.g.dart';

Future<void> _pumpHeader(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
  AppLocale locale = AppLocale.enUs,
  SearchTypePlacement typePlacement = SearchTypePlacement.besideQueryOrTabs,
  ValueChanged<SearchType>? onTypeChanged,
  TabController Function(TickerProvider vsync)? typeController,
}) async {
  LocaleSettings.setLocale(locale);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(platform: TargetPlatform.windows, locale: locale.flutterLocale),
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 900), textScaler: TextScaler.linear(textScale)),
            child: FrostLayoutScope(
              child: Scaffold(
                body: typeController == null
                    ? SearchHeader(onSearch: (_) {}, onSelected: (_) {}, typePlacement: typePlacement, onTypeChanged: onTypeChanged)
                    : _ControlledHeader(create: typeController, typePlacement: typePlacement),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ControlledHeader extends StatefulWidget {
  const _ControlledHeader({required this.create, required this.typePlacement});

  final TabController Function(TickerProvider vsync) create;
  final SearchTypePlacement typePlacement;

  @override
  State<_ControlledHeader> createState() => _ControlledHeaderState();
}

class _ControlledHeaderState extends State<_ControlledHeader> with SingleTickerProviderStateMixin {
  late final TabController _controller = widget.create(this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchHeader(onSearch: (_) {}, onSelected: (_) {}, typePlacement: widget.typePlacement, typeController: _controller);
}

final _besideQuery = find.byWidgetPredicate((widget) => widget is SearchTypeSelector || widget is SearchTypeMenuButton);

/// The app's bundled fonts: the default test font draws every glyph as a
/// full square, which would make the labels far wider than they really are
/// and hide the wide-desktop segments.
Future<void> _loadAppFonts() async {
  for (final (family, asset) in [('Noto Sans SC', 'assets/fonts/NotoSansSC-Subset.ttf'), ('Noto Sans JP', 'assets/fonts/NotoSansJP-Subset.ttf')]) {
    await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
  }
}

void main() {
  setUpAll(_loadAppFonts);

  testWidgets('beside the sidebar the type shares the query row; phones put it in tabs below', (tester) async {
    for (final locale in AppLocale.values) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        for (final width in [320.0, 360.0, 390.0, 430.0, 600.0, 700.0, 760.0, 800.0, 960.0, 1440.0]) {
          final reason = '$locale at $width and $textScale×';
          await _pumpHeader(tester, width: width, textScale: textScale, locale: locale);
          expect(tester.takeException(), isNull, reason: reason);
          final input = tester.getRect(find.byType(FrostSearchInput));
          if (width < 600) {
            // Phone: the query row keeps its room; the type is a tab row.
            expect(_besideQuery, findsNothing, reason: reason);
            final tabs = tester.getRect(find.byType(SearchTypeTabs));
            expect(tabs.top, greaterThanOrEqualTo(input.bottom), reason: reason);
            for (final label in [t.search.type.illustManga, t.search.type.novel, t.search.type.user]) {
              expect(
                find.descendant(of: find.byType(SearchTypeTabs), matching: find.text(label)),
                findsOneWidget,
                reason: reason,
              );
            }
            continue;
          }
          expect(find.byType(SearchTypeTabs), findsNothing, reason: reason);
          final control = tester.getRect(_besideQuery);
          expect(control.left, greaterThan(input.right), reason: reason);
          expect(control.center.dy, closeTo(input.center.dy, 1), reason: reason);
          expect(control.right, lessThanOrEqualTo(width - 12), reason: reason);
          expect(
            find.descendant(of: _besideQuery, matching: find.byType(Scrollable)),
            findsNothing,
            reason: reason,
          );
          if (find.byType(SearchTypeSelector).evaluate().isNotEmpty) {
            // Segments only appear with every label whole on one line.
            for (final label in [t.search.type.illustManga, t.search.type.novel, t.search.type.user]) {
              final text = find.descendant(of: _besideQuery, matching: find.text(label));
              final painter = tester.renderObject<RenderParagraph>(text);
              expect(painter.didExceedMaxLines, isFalse, reason: '$label $reason');
              expect(tester.getSize(text).height, lessThan(24 * textScale + 1), reason: '$label $reason');
            }
          }
        }
      }
    }
  });

  testWidgets('segments are for very wide desktops; narrower sidebar layouts use a dropdown at the row end', (tester) async {
    await _pumpHeader(tester, width: 1440);
    expect(find.byType(SearchTypeSelector), findsOneWidget);
    // An unfolded Fold or a mid-size window: a labelled dropdown, sized for
    // the widest label so switching types never moves the field.
    await _pumpHeader(tester, width: 760);
    expect(find.byType(SearchTypeSelector), findsNothing);
    final menu = find.byType(SearchTypeMenuButton);
    expect(find.descendant(of: menu, matching: find.text(t.search.type.illustManga)), findsOneWidget);
    // Large text on a narrow window: only the type's icon, named by tooltip.
    await _pumpHeader(tester, width: 620, textScale: 2);
    expect(find.byType(SearchTypeSelector), findsNothing);
    expect(find.byTooltip(t.search.type.illustManga), findsOneWidget);
  });

  testWidgets('the type dropdown names every type and applies the choice', (tester) async {
    SearchType? chosen;
    await _pumpHeader(tester, width: 760, onTypeChanged: (type) => chosen = type);
    await tester.tap(find.byType(SearchTypeMenuButton));
    await tester.pumpAndSettle();
    for (final label in [t.search.type.novel, t.search.type.user]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text(t.search.type.novel));
    await tester.pumpAndSettle();
    expect(chosen, SearchType.novel);
  });

  testWidgets('phone results tabs move the controller of the page they sit above', (tester) async {
    late TabController controller;
    await _pumpHeader(tester, width: 390, typeController: (vsync) => controller = TabController(length: 3, vsync: vsync));
    final tabs = find.byType(SearchTypeTabs);
    await tester.tap(find.descendant(of: tabs, matching: find.text(t.search.type.user)));
    await tester.pumpAndSettle();
    expect(controller.index, 2);
  });

  testWidgets('discover leaves the type out on phones and keeps it beside the query otherwise', (tester) async {
    await _pumpHeader(tester, width: 390, typePlacement: SearchTypePlacement.besideQuery);
    expect(_besideQuery, findsNothing);
    expect(find.byType(SearchTypeTabs), findsNothing);
    await _pumpHeader(tester, width: 1280, typePlacement: SearchTypePlacement.besideQuery);
    expect(find.byType(SearchTypeSelector), findsOneWidget);
  });
}
