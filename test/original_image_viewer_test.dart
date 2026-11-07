import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/shared/widgets/original_image_viewer_page.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

OriginalImageViewerArgs _args({String title = 'Sample work'}) => OriginalImageViewerArgs(
  title: title,
  source: const ArtworkSource(illustId: 1, title: 'Sample work'),
  pages: [
    for (var index = 0; index < 3; index++)
      OriginalImagePage(
        url: sampleImageUrl(index),
        previewUrl: sampleImageUrl(index, width: 60, height: 80),
        downloadOrigin: ArtworkPage(illustId: 1, pageIndex: index),
      ),
  ],
);

void main() {
  setUp(() => pixivImageOverride = sampleImageProvider);
  tearDown(() => pixivImageOverride = null);

  testWidgets('the top row names the work and the page; the arrow keys turn pages', (tester) async {
    await mountPilotPage(tester, OriginalImageViewerPage(args: _args()));
    expect(find.text('Sample work · 1 / 3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settlePilot(tester);
    expect(find.text('Sample work · 2 / 3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settlePilot(tester);
    expect(find.text('Sample work · 1 / 3'), findsOneWidget);
  });

  testWidgets('copy and download wait for the original file, which sample pictures never give', (tester) async {
    await mountPilotPage(tester, OriginalImageViewerPage(args: _args()));
    final download = tester.widgetList<FrostButton>(find.byType(FrostButton)).firstWhere((button) => button.label == 'Download');
    expect(download.onPressed, isNull);
  });

  testWidgets('a long title fits a phone at double text size', (tester) async {
    await mountPilotPage(
      tester,
      OriginalImageViewerPage(args: _args(title: longText)),
      size: phoneSize,
      textScale: 2,
    );
    expectNoLayoutErrors(tester);
  });

  test('the viewer strings exist in all four languages', () => expectLocalesComplete(['viewer']));
}
