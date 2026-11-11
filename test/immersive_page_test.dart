import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/immersive_pages.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/logic/profile_image_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/custom/avatar_cropper.dart';
import 'package:frost_ui/frost_ui.dart';

bool _entryVisible(WidgetTester tester) => tester.widget<FrostShell>(find.byType(FrostShell)).taskEntry!.visible;

void main() {
  testWidgets('a page marks itself immersive while it is in the tree', (tester) async {
    expect(immersivePageCount.value, 0);
    await tester.pumpWidget(const ImmersivePage(child: SizedBox()));
    await tester.pump();
    expect(immersivePageCount.value, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(immersivePageCount.value, 0);
  });

  testWidgets('the narrow cropper page hides the shell\'s download button, and it returns when the page closes', (tester) async {
    tester.view.physicalSize = const Size(560, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picture = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 600, 400), Paint()..color = const Color(0xFF3366CC));
      final image = await recorder.endRecording().toImage(600, 400);
      return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    }))!;
    final picker = profileImagePicker, preparer = profileImagePreparer;
    profileImagePicker = () async => PickedProfileImage.bytes(picture);
    profileImagePreparer = (Uint8List source, AvatarCrop crop) async => picture;
    addTearDown(() {
      profileImagePicker = picker;
      profileImagePreparer = preparer;
    });
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    pixivAccountNotifier.value = sampleAccount;
    addTearDown(() => pixivAccountNotifier.value = null);
    AppRouter.router.go(AppRoute.meProfileEdit.path);
    await tester.pumpWidget(
      FreepivApp(
        windowController: FrostWindowController(minimumSize: const Size(320, 480)),
        overrides: sampleOverrides,
      ),
    );
    Future<void> frames([int count = 10]) async {
      for (var frame = 0; frame < count; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await frames();
    expect(_entryVisible(tester), isTrue);

    await tester.tap(find.text(t.profileEdit.avatarChange));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await frames();
    expect(find.byType(AvatarCropViewport), findsOneWidget);
    expect(_entryVisible(tester), isFalse, reason: 'the button would lie over the slider');

    await tester.tap(find.text(t.profileEdit.cropDone));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await frames();
    expect(find.byType(AvatarCropViewport), findsNothing);
    expect(_entryVisible(tester), isTrue);
  });
}
