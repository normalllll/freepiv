import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/ui/compositions/pixiv_image.dart';

import 'support/memory_history.dart';
import 'support/pilot_harness.dart';
import 'support/reader_harness.dart';

/// A picture that arrives when [release] is called.
class _Gated extends ImageProvider<_Gated> {
  _Gated(this.image, this.gate);

  final ui.Image image;
  final Future<void> gate;

  @override
  Future<_Gated> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Gated key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(gate.then((_) => ImageInfo(image: image)));
}

void main() {
  late HistoryRepository history;
  setUp(() => history = useMemoryHistory());

  Iterable<AppPixivImage> pictures(WidgetTester tester) =>
      tester.widgetList<AppPixivImage>(find.descendant(of: find.byType(NovelReaderContent), matching: find.byType(AppPixivImage)));

  testWidgets('text pictures follow the preview quality, with the small picture as placeholder, and keep the place', (tester) async {
    final body = [for (var i = 0; i < 1; i++) '$readerParagraph $i', '[uploadedimage:1]', for (var i = 0; i < 20; i++) '$readerParagraph more $i'].join('\n\n');
    await mountReader(tester, history, text: readerText(body));
    final image = readerText(body).images.first.urls;
    final first = pictures(tester).where((picture) => picture.placeholderUrl != null).first;
    expect(first.url, image.size480Mw, reason: 'medium is the default');
    expect(first.placeholderUrl, image.size240Mw);
    final before = readerController(tester).offset;

    final container = ProviderScope.containerOf(tester.element(find.byType(NovelReaderContent)));
    container.read(previewImageQualityProvider.notifier).setQuality(PreviewImageQuality.large);
    await settlePilot(tester);
    expect(pictures(tester).where((picture) => picture.placeholderUrl != null).first.url, image.size1200X1200);
    expect(readerController(tester).offset, before, reason: 'the place is kept');
  });
  testWidgets('the placeholder of a text picture is blurred while the picture loads, and the blur is gone once it is shown', (tester) async {
    final body = ['$readerParagraph a', '[uploadedimage:1]', for (var i = 0; i < 20; i++) '$readerParagraph more $i'].join('\n\n');
    final text = readerText(body);
    final urls = text.images.first.urls;
    final gate = Completer<void>();
    final picture = (await tester.runAsync(() => createTestImage(width: 48, height: 32)))!;
    final restore = pixivImageOverride;
    pixivImageOverride = (url) => url == urls.size480Mw ? _Gated(picture, gate.future) : sampleImageProvider(url);
    addTearDown(() => pixivImageOverride = restore);

    await mountReader(tester, history, text: text);
    Finder blurred() => find.descendant(of: find.byType(AppPixivImage), matching: find.byType(ImageFiltered));
    expect(pictures(tester).any((picture) => picture.blurPlaceholder), isTrue);
    expect(blurred(), findsOneWidget, reason: 'the small picture is drawn blurred while the picture loads');

    gate.complete();
    await settlePilot(tester);
    expect(blurred(), findsNothing, reason: 'the sharp picture shows without the blur');
  });
}
