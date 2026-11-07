import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/illust/presentation/illust_detail_page.dart';
import 'package:freepiv/features/pixivision/navigation.dart' show pixivAppLocation;
import 'package:freepiv/features/user_detail/presentation/user_detail_page.dart';
import 'package:freepiv/ui/compositions/pixiv_text.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

/// What people write, with every character the rich grammar would take.
const _written = '(*´▽`*) **not bold** `not code` @someone #tag [x](y)';

Illust _work(String caption) {
  final base = sampleIllusts(count: 1).single;
  return Illust(
    id: base.id,
    title: 'Sample work',
    kind: base.kind,
    imageUrls: base.imageUrls,
    caption: caption,
    restrict: 0,
    user: base.user,
    tags: const [Tag(name: 'landscape')],
    tools: const [],
    createDate: base.createDate,
    pageCount: 1,
    width: 1000,
    height: 1400,
    sanityLevel: 2,
    xRestrict: 0,
    metaSinglePage: const MetaSinglePage(),
    metaPages: const [],
    totalView: 1000,
    totalBookmarks: 20,
    isBookmarked: false,
    visible: true,
    isMuted: false,
    totalComments: 0,
    illustAiType: 1,
  );
}

/// The text shows as written: nothing is styled or announced as a link.
void _expectLiteral(WidgetTester tester) {
  final text = find.byType(FrostExpandableText);
  expect(tester.widget<FrostExpandableText>(text).text, _written);
  // Frost paints the text itself; its painter holds the spans as shown.
  final painted = find.descendant(of: text, matching: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_PaintedText'));
  expect(painted, findsWidgets);
  final span = ((tester.widget(painted.first) as dynamic).painter as TextPainter).text! as TextSpan;
  expect(span.toPlainText(), _written, reason: 'every character painted as written');
  final base = span.style!;
  span.visitChildren((child) {
    final style = (child as TextSpan).style;
    expect(style?.fontWeight ?? base.fontWeight, base.fontWeight, reason: '"${child.text}" is not bold');
    expect(style?.fontStyle ?? base.fontStyle, base.fontStyle, reason: '"${child.text}" is not italic');
    expect(style?.fontFamily ?? base.fontFamily, base.fontFamily, reason: '"${child.text}" is not code');
    expect(style?.color ?? base.color, base.color, reason: '"${child.text}" is not coloured as a link');
    return true;
  });
  expect(
    find.descendant(of: text, matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.link == true)),
    findsNothing,
  );
}

Finder _links() => find.descendant(
  of: find.byType(FrostExpandableText),
  matching: find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.link == true),
);

void main() {
  group('pixiv HTML as text runs', () {
    test('keeps every character people wrote, line breaks included, and makes each anchor a link run', () {
      expect(pixivTextRuns('  a *b* `c`<br />see <a href="pixiv://illusts/42">illust/42</a> &amp; @me #tag  '), [
        const FrostTextRun('a *b* `c`\nsee '),
        FrostTextRun('illust/42', link: Uri.parse('https://www.pixiv.net/artworks/42')),
        const FrostTextRun(' & @me #tag'),
      ]);
    });

    test('a label with brackets keeps its words', () {
      expect(pixivTextRuns('<a href="https://example.com/a">[news] part [2]</a>'), [
        FrostTextRun('[news] part [2]', link: Uri.parse('https://example.com/a')),
      ]);
    });

    test('an anchor that is not a web link stays as its words', () {
      expect(pixivTextRuns('<a href="javascript:alert(1)">x</a> y'), [const FrostTextRun('x y')]);
    });
  });

  group('pixiv link targets', () {
    test('a malformed /jump.php? value does not throw and is no link', () {
      expect(() => pixivLinkTarget('/jump.php?%zz'), returnsNormally);
      expect(pixivLinkTarget('/jump.php?%zz'), isNull);
      expect(pixivTextRuns('<a href="/jump.php?%zz">broken</a>'), [const FrostTextRun('broken')]);
    });

    test('/jump.php? with the address encoded opens that address', () {
      expect(pixivLinkTarget('/jump.php?https%3A%2F%2Fexample.com%2Fa%3Fb%3D1'), Uri.parse('https://example.com/a?b=1'));
    });

    test('/jump.php?url= opens the address it carries', () {
      expect(pixivLinkTarget('/jump.php?url=https%3A%2F%2Fexample.com%2Fa'), Uri.parse('https://example.com/a'));
      expect(pixivLinkTarget('https://www.pixiv.net/jump.php?url=https://example.com/b'), Uri.parse('https://example.com/b'));
    });

    test('pixiv:// app links become their web pages', () {
      expect(pixivLinkTarget('pixiv://users/7'), Uri.parse('https://www.pixiv.net/users/7'));
      expect(pixivLinkTarget('pixiv://novels/9'), Uri.parse('https://www.pixiv.net/novel/show.php?id=9'));
    });
  });

  group('pixiv addresses opened in the app', () {
    for (final (address, location) in [
      ('https://www.pixiv.net/artworks/42', '/illust/42'),
      ('https://www.pixiv.net/en/artworks/42', '/illust/42'),
      ('https://www.pixiv.net/users/7', '/user/7'),
      ('https://www.pixiv.net/novel/show.php?id=9', '/novel/9'),
      ('https://www.pixiv.net/member.php?id=7', '/user/7'),
      ('https://www.pixiv.net/member_illust.php?mode=medium&illust_id=42', '/illust/42'),
      ('https://www.pixiv.net/member_illust.php?id=7', '/user/7'),
      ('https://www.pixiv.net/i/42', '/illust/42'),
      ('https://touch.pixiv.net/member.php?id=7', '/user/7'),
      ('https://m.pixiv.net/artworks/42', '/illust/42'),
      ('http://pixiv.net/i/42', '/illust/42'),
    ]) {
      test(address, () => expect(pixivAppLocation(Uri.parse(address)), location));
    }

    test('other addresses are left to the browser', () {
      expect(pixivAppLocation(Uri.parse('https://www.pixiv.net/ranking.php')), isNull);
      expect(pixivAppLocation(Uri.parse('https://example.com/artworks/42')), isNull);
      expect(pixivAppLocation(Uri.parse('https://www.pixiv.net/artworks/abc')), isNull);
    });
  });

  testWidgets('in a caption only the anchors are links, and a pixiv link opens in the app', (tester) async {
    await mountPilotPage(tester, IllustDetailPage(illust: _work('*wow* @me #tag see <a href="https://www.pixiv.net/member_illust.php?illust_id=42">this</a>')));
    final links = _links();
    expect(links, findsOneWidget);
    expect(tester.widget<Semantics>(links).properties.label, 'this');
    expect(tester.widget<FrostExpandableText>(find.byType(FrostExpandableText)).text, '*wow* @me #tag see this');
    await tester.ensureVisible(links);
    await tester.pump();
    await tester.tap(links);
    await settlePilot(tester);
    expect(openedLocations, ['/illust/42']);
  });

  testWidgets('a work\'s caption keeps its stars, backticks and symbols as written', (tester) async {
    await mountPilotPage(tester, IllustDetailPage(illust: _work('${_written.replaceAll('&', '&amp;')}<br />')));
    _expectLiteral(tester);
  });

  testWidgets('an author\'s bio keeps its stars, backticks and symbols as written', (tester) async {
    final detail = UserDetailResult(
      user: UserInfo(
        id: 2000,
        name: 'Sample artist',
        account: 'sample',
        profileImageUrls: sampleUserDetail.user.profileImageUrls,
        comment: _written,
        isFollowed: false,
      ),
      profile: sampleUserDetail.profile,
      profilePublicity: sampleUserDetail.profilePublicity,
      workspace: sampleUserDetail.workspace,
    );
    await mountPilotPage(tester, UserDetailPage(userId: 2000, userDetail: detail));
    _expectLiteral(tester);
  });
}
