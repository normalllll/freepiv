import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/app.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/core/utils/illust_image_url.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

Future<void> _frames(WidgetTester tester, [int count = 12]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ImageProvider? _ambient(WidgetTester tester) => tester.widget<FrostAmbientBackdropHost>(find.byType(FrostAmbientBackdropHost)).image;

void main() {
  testWidgets('a work opened from its card tints the window with the card\'s picture, through the comments too', (tester) async {
    tester.view.physicalSize = const Size(1147, 717);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await AppSettings.initialize(store: SampleSettingsStore(sampleSettings));
    pixivAccountNotifier.value = sampleAccount;
    addTearDown(() => pixivAccountNotifier.value = null);
    AppRouter.router.go(AppRoute.home.path);
    await tester.pumpWidget(FreepivApp(windowController: FrostWindowController(minimumSize: const Size(320, 480)), overrides: sampleOverrides));
    await _frames(tester);
    expect(_ambient(tester), isNull, reason: 'no work, no artwork');

    final card = find.byType(AppArtworkCard).first;
    final illust = tester.widget<AppArtworkCard>(card).illust;
    final container = ProviderScope.containerOf(tester.element(card));
    final cardPicture = pixivImageProviderFor(
      container.read(rustMediaTransportProvider),
      illustPreviewImageUrl(illust.imageUrls, container.read(previewImageQualityProvider)),
    );

    AppRouter.router.push(AppLocations.illust(illust.id), extra: illust);
    // The page registers its artwork after its first frame.
    await tester.pump();
    await tester.pump();
    expect(find.byType(IllustDetailPage), findsOneWidget);
    expect(_ambient(tester), cardPicture, reason: 'the picture the card already decoded');
    await _frames(tester);
    expect(_ambient(tester), cardPicture, reason: 'the loaded detail and its large image do not change it');

    AppRouter.router.push(AppLocations.illustComments(illust.id));
    await _frames(tester);
    expect(AppRouter.currentUri.path, AppLocations.illustComments(illust.id));
    expect(_ambient(tester), cardPicture, reason: 'the comments keep the work\'s colour');
  });
}
