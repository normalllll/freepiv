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
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('button feedback follows circles and rounded rectangles in both themes', (tester) async {
    pixivAccountNotifier.value = const UserAccountResult(
      accessToken: '',
      expiresIn: 0,
      tokenType: '',
      scope: '',
      refreshToken: '',
      user: LocalUser(
        profileImageUrls: LocalUserProfileImageUrls(px16X16: '', px50X50: '', px170X170: ''),
        id: '42',
        name: '',
        account: '',
        mailAddress: '',
        isPremium: false,
        xRestrict: 0,
        isMailAuthorized: false,
        requirePolicyAgreement: false,
      ),
    );
    addTearDown(() => pixivAccountNotifier.value = null);
    final controls = <String, Widget>{
      'back': IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
      'more': FrostIconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      'image-action': FrostSurfaceIconButton(onPressed: () {}, tooltip: 'Image', icon: FrostIconData.glyph(Icons.open_in_full)),
      'bookmark': const IllustBookmarkButton(illustId: 9101, initialIsBookmarked: false),
      'floating-bookmark': const IllustBookmarkButton(illustId: 9102, initialIsBookmarked: false, floating: true),
      'novel-bookmark': const IllustBookmarkButton(illustId: 9103, initialIsBookmarked: false, isNovel: true),
      'text': TextButton(onPressed: () {}, child: const Text('Open')),
    };
    for (final dark in [false, true]) {
      final tokens = dark ? FrostPalettes.pink.darkNeutral : FrostPalettes.pink.lightNeutral;
      for (final entry in controls.entries) {
        final key = GlobalKey();
        final textButton = entry.key == 'text';
        final width = textButton ? 96.0 : 48.0;
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: dark
                    ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                    : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
                home: Scaffold(
                  body: Center(
                    child: RepaintBoundary(
                      key: key,
                      child: Material(
                        color: tokens.surfaceRaised,
                        child: SizedBox(width: width, height: 48, child: entry.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        List<int>? hoveredPixel;
        for (final pressed in [false, true]) {
          if (pressed) await mouse.down(tester.getCenter(find.byKey(key)));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
            final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
            List<int> pixel(int x, int y) => bytes.sublist((y * image.width + x) * 4, (y * image.width + x) * 4 + 4);
            List<int> rgba(Color color) => [(color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round(), 255];
            final corner = textButton ? 1 : 4;
            expect(pixel(corner, corner), rgba(tokens.surfaceRaised), reason: '${entry.key}: feedback must not paint outside its shape');
            final inside = pixel(width ~/ 2, 4);
            expect(inside[3], 255, reason: '${entry.key}: feedback remains opaque inside its shape');
            if (pressed) {
              expect(inside, isNot(hoveredPixel), reason: '${entry.key}: pressed feedback differs from hover');
            } else {
              hoveredPixel = inside;
            }
            if (!dark && !pressed) {
              final png = await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('build/ui-review/shape-${entry.key}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(png!.buffer.asUint8List());
            }
            image.dispose();
          });
          if (pressed) await mouse.cancel();
        }
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
