import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/features/about/presentation/about_page.dart';
import 'package:freepiv/features/login/presentation/login_page.dart';
import 'package:freepiv/features/me/presentation/me_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('login, about and me pages render at compact, rail and sidebar widths', (tester) async {
    PackageInfo.setMockInitialValues(appName: 'freepiv', packageName: 'freepiv', version: '0.1.1', buildNumber: '5', buildSignature: '');
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.runAsync(() async {
      final systemFont = File('C:/Windows/Fonts/segoeui.ttf');
      if (await systemFont.exists()) {
        final bytes = await systemFont.readAsBytes();
        await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final overviewBounds = <String, Rect>{};
    for (final page in {'login': const LoginPage(), 'about': const AboutPage(), 'me': const MePage()}.entries) {
      for (final size in [const Size(390, 844), const Size(800, 900), const Size(1440, 900)]) {
        for (final dark in [false, true]) {
          tester.view.physicalSize = size;
          final boundary = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              child: TranslationProvider(
                child: MaterialApp(
                  theme: dark
                      ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                      : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
                  home: MediaQuery(
                    data: MediaQueryData(size: size, textScaler: TextScaler.linear(size.width == 390 ? 2 : 1)),
                    child: FrostLayoutScope(
                      child: RepaintBoundary(key: boundary, child: page.value),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '${page.key} $size ${dark ? 'dark' : 'light'}');
          if (page.key == 'about' || page.key == 'me') {
            expect(find.descendant(of: find.byType(FrostGroupedRows), matching: find.byType(Divider)), findsNothing);
            final key = '${size.width}-${dark ? 'dark' : 'light'}';
            final bounds = tester.getRect(find.byType(FrostSurface).first);
            if (page.key == 'about') {
              overviewBounds[key] = bounds;
            } else {
              expect(bounds.left, closeTo(overviewBounds[key]!.left, .1), reason: key);
              expect(bounds.width, closeTo(overviewBounds[key]!.width, .1), reason: key);
              BorderRadius rowCorners(String label) {
                BorderRadiusGeometry? corners;
                final row = find.text(label);
                expect(row, findsOneWidget, reason: '${page.key} $size ${dark ? 'dark' : 'light'}: $label');
                tester.element(row).visitAncestorElements((ancestor) {
                  if (ancestor.widget case ClipRRect(:final borderRadius)) {
                    corners = borderRadius;
                    return false;
                  }
                  return true;
                });
                return corners!.resolve(TextDirection.ltr);
              }

              final first = rowCorners(t.settings.downloads.tasksTitle);
              final middle = rowCorners(t.me.about);
              final last = rowCorners(t.me.settings);
              expect(first.topLeft.x, greaterThan(0));
              expect(first.bottomLeft.x, 0);
              expect(middle, BorderRadius.zero);
              expect(last.topLeft.x, 0);
              expect(last.bottomLeft.x, greaterThan(0));
              expect(ListTileTheme.of(tester.element(find.text(t.me.about))).shape, const RoundedRectangleBorder());
            }
          }
          if (size.width == 390 || size.width == 1440) {
            await tester.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final image = await render.toImage();
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('build/ui-review/${page.key}-${size.width.toInt()}-${dark ? 'dark' : 'light'}-actual.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (page.key == 'me' && size.width == 1440 && !dark) {
            final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
            await mouse.addPointer();
            await mouse.moveTo(tester.getCenter(find.text(t.me.about)));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
              final image = await render.toImage();
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('build/ui-review/me-1440-light-middle-hover-actual.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
            await mouse.removePointer();
          }
        }
      }
    }
  });
}
