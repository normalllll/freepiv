import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/logic/user_follow_logic.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';
import 'package:freepiv/shared/widgets/form_controls.dart';
import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'package:freepiv/shared/widgets/energetic_card.dart';
import 'package:freepiv/shared/widgets/constrained_segmented_button.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/enums.dart';

class _Follow extends UserFollow {
  Completer<void>? pending;
  @override
  Future<void> toggle({Restrict restrict = Restrict.public}) async {
    state = state.copyWith(isFollowed: !state.isFollowed, updating: true);
    pending = Completer<void>();
    await pending!.future;
    state = state.copyWith(updating: false);
  }
}

void main() {
  testWidgets('follow supports keyboard and stable pending/selected geometry in both themes', (tester) async {
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
    for (final dark in [false, true]) {
      final fake = _Follow();
      final args = const UserFollowArgs(userId: 1, isFollowed: false, accountId: '42');
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(dark),
          overrides: [userFollowProvider(args).overrideWith(() => fake)],
          child: TranslationProvider(
            child: MaterialApp(
              theme: dark
                  ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
                  : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: const Scaffold(body: Center(child: UserFollowButton(userId: 1))),
            ),
          ),
        ),
      );
      final button = find.byType(TextButton);
      final before = tester.getSize(button);
      expect(before.height, greaterThanOrEqualTo(48));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      expect(tester.getSize(button), before);
      fake.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(tester.getSize(button), before);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('component gallery renders both themes at portrait/landscape and large text', (tester) async {
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    await tester.runAsync(() async {
      final file = File('C:/Windows/Fonts/segoeui.ttf');
      if (await file.exists()) await (FontLoader('Segoe UI')..addFont(Future.value(ByteData.sublistView(await file.readAsBytes())))).load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final width in [390.0, 1000.0]) {
        tester.view.physicalSize = Size(width, 960);
        final key = GlobalKey();
        final theme = dark
            ? AppTheme.dark(platform: TargetPlatform.windows, locale: const Locale('en'))
            : AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en'));
        await tester.pumpWidget(
          ProviderScope(
            child: TranslationProvider(
              child: MaterialApp(
                theme: theme,
                home: RepaintBoundary(
                  key: key,
                  child: Scaffold(
                    appBar: AppBar(
                      leading: BackButton(onPressed: () {}),
                      title: const Text('Freepiv · Controls'),
                    ),
                    body: MediaQuery(
                      data: MediaQueryData(textScaler: TextScaler.linear(width == 390 ? 1.5 : 1)),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: const [UserFollowButton(userId: 10), UserFollowButton(userId: 11, initialIsFollowed: true)],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              AppButton(label: 'Read now', onPressed: () {}, kind: AppButtonKind.primary),
                              AppButton(label: 'Download', onPressed: () {}),
                              const AppButton(label: 'Unavailable', onPressed: null),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            children: [
                              AppIconButton(icon: const Icon(Icons.arrow_back), tooltip: 'Back', onPressed: () {}),
                              AppIconButton(icon: const Icon(Icons.favorite), selected: true, tooltip: 'Saved', onPressed: () {}),
                              const AppIconButton(icon: Icon(Icons.download), tooltip: 'Unavailable', onPressed: null),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Wrap(
                            spacing: 8,
                            children: [
                              EnergeticPill(child: Text('#Original')),
                              EnergeticPill(selected: true, child: Text('#Illustration')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AppSelect<int>(
                            value: 1,
                            label: 'Image quality',
                            items: const [
                              AppSelectItem(value: 1, label: 'Original quality'),
                              AppSelectItem(value: 2, label: 'Standard'),
                            ],
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 24),
                          ConstrainedSegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('Artwork')),
                              ButtonSegment(value: 2, label: Text('Novels')),
                            ],
                            selected: const {1},
                            onSelectionChanged: (_) {},
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AppSwitch(value: true, onChanged: (_) {}),
                              AppSwitch(value: false, onChanged: (_) {}),
                              Checkbox(value: true, onChanged: (_) {}),
                              Checkbox(value: false, onChanged: (_) {}),
                              const CircularProgressIndicator(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const EnergeticCard(
                            padding: EdgeInsets.all(16),
                            child: Text('Content stays central. Controls share a quiet, consistent visual language.'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui-review/components-${width.toInt()}-${dark ? 'dark' : 'light'}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
