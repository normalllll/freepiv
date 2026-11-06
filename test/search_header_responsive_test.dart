import 'package:flutter/material.dart';
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
