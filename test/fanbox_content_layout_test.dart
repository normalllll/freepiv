import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/downloads/presentation/download_source_scope.dart';
import 'package:freepiv/features/fanbox/fanbox_actions.dart';
import 'package:freepiv/features/fanbox/post_page.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/fanbox.dart';
import 'package:freepiv/ui/compositions/fanbox_image.dart';
import 'package:freepiv/ui/compositions/fanbox_rows.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _user = FanboxUser(id: 'author', name: 'Author');

FanboxPost _post(String excerpt) => FanboxPost(
  id: 'post',
  creatorId: 'author',
  user: _user,
  title: 'A short post',
  excerpt: excerpt,
  publishedDatetime: '2026-09-27T00:00:00Z',
  updatedDatetime: '2026-09-27T00:00:00Z',
  feeRequired: 0,
  isRestricted: false,
  isLiked: false,
  likeCount: 2,
  commentCount: 1,
  tags: const [],
  blocks: const [],
);

Widget _column(Widget child) => SingleChildScrollView(
  child: Padding(padding: const EdgeInsets.all(FrostGap.group), child: child),
);

void main() {
  testWidgets('an empty excerpt reserves no lines and the avatar opens the creator, not the post', (tester) async {
    var creatorTaps = 0;
    var postTaps = 0;
    Widget card(String excerpt) => _column(AppFanboxPostCard(post: _post(excerpt), onOpen: () => postTaps++, onCreator: () => creatorTaps++));

    await mountPilotPage(tester, card(''), size: phoneSize);
    final emptyHeight = tester.getSize(find.byType(AppFanboxPostCard)).height;
    await tester.tap(find.byType(AppFanboxAvatar));
    expect(creatorTaps, 1);
    expect(postTaps, 0);

    await mountPilotPage(tester, card('A real preview for the post.'), size: phoneSize);
    expect(tester.getSize(find.byType(AppFanboxPostCard)).height, greaterThan(emptyHeight));
  });

  testWidgets('a body image reserves its own shape before it loads', (tester) async {
    const image = FanboxImage(id: 'image', originalUrl: '', thumbnailUrl: '', width: 400, height: 1200, extension_: 'jpg');
    await mountPilotPage(
      tester,
      DownloadSourceScope(
        source: fanboxPostDownloadSource(_post('')),
        child: _column(const FanboxBlockView(block: FanboxBlock.image(image: image))),
      ),
      size: phoneSize,
    );
    final size = tester.getSize(find.byType(AppFanboxImage));
    expect(size.height / size.width, moreOrLessEquals(3, epsilon: .01));
  });

  test('a paragraph keeps its links, bold and italic in the rich text', () {
    const text = 'Read the notes here, bold and slanted.';
    final rich = fanboxRichText(text, const [
      FanboxTextSpan(offset: 15, length: 4, bold: false, italic: false, url: 'https://example.test/notes'),
      FanboxTextSpan(offset: 21, length: 4, bold: true, italic: false),
      FanboxTextSpan(offset: 30, length: 7, bold: false, italic: true),
    ]);
    expect(rich, 'Read the notes [here](https://example.test/notes), **bold** and *slanted*.');
  });
}
