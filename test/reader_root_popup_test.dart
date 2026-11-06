import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/app/router/route_activity.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/novel/logic/novel_detail_logic.dart';
import 'package:freepiv/features/novel/presentation/reader/novel_reader_page.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

const _novel = Novel(
  id: 7,
  title: 'A novel',
  caption: 'From the details',
  restrict: 0,
  xRestrict: 0,
  isOriginal: false,
  imageUrls: ImageUrls(squareMedium: '', medium: '', large: ''),
  createDate: '',
  tags: [],
  pageCount: 2,
  textLength: 1200,
  user: User(
    id: 2,
    name: 'Author name',
    account: 'author',
    profileImageUrls: ProfileImageUrls(medium: ''),
  ),
  series: Series(),
  totalBookmarks: 12,
  isBookmarked: false,
  totalView: 30,
  visible: true,
  totalComments: 0,
  isMuted: false,
  isMypixivOnly: false,
  isXRestricted: false,
  novelAiType: 0,
);

const _text = WebviewNovel(
  id: '7',
  title: 'A novel',
  userId: '2',
  coverUrl: '',
  tags: [],
  caption: '',
  cdate: '',
  rating: NovelRating(like: 0, bookmark: 12, view: 30),
  text: 'Paragraph to read.',
  illusts: [],
  images: [],
  glossaryItems: [],
  replaceableItemIds: [],
  aiType: 0,
  isOriginal: false,
);

void main() {
  testWidgets('a dialog of the root navigator releases the volume keys until it closes', (tester) async {
    await AppSettings.initialize(store: SampleSettingsStore({'readerVolumeKeys': true}));
    const channel = MethodChannel('test/reader_volume_keys');
    final enabled = <bool>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setEnabled') enabled.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: FrostScope(
            config: freepivFrostConfig,
            child: MaterialApp(
              navigatorKey: navigator,
              navigatorObservers: [appRootRouteActivity],
              theme: AppTheme.light(platform: TargetPlatform.android, locale: const Locale('en', 'US')),
              home: NovelReaderContent(
                detail: const NovelDetailData(novel: _novel, webviewNovel: _text),
                volumeKeys: ReaderVolumeKeys(channel: channel, supported: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(enabled.last, isTrue);

    showDialog<void>(
      context: navigator.currentContext!,
      builder: (_) => const Center(child: Text('dialog')),
    );
    await tester.pumpAndSettle();
    expect(appRootRouteActivity.popupOnTop, isTrue);
    expect(enabled.last, isFalse, reason: 'the reader is covered');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(enabled.last, isTrue);
  });
}
