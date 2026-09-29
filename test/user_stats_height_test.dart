import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/features/user_detail/presentation/widgets/user_collapsible_header.dart';

Future<double> _statsHeight(WidgetTester tester, {required double scale, required double width}) async {
  late double height;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(platform: TargetPlatform.android, locale: const Locale('en')),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Builder(
          builder: (context) {
            height = UserCollapsibleHeaderSliver.statsHeightFor(context, width);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return height;
}

void main() {
  testWidgets('stats wrap onto more lines as text grows instead of overflowing', (tester) async {
    final normal = await _statsHeight(tester, scale: 1, width: 360);
    final large = await _statsHeight(tester, scale: 2, width: 360);
    expect(large, greaterThan(normal * 1.9), reason: 'at 2x the four stats need at least two lines');
  });
}
