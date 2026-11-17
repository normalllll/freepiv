import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/novel/domain/novel_text.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

String _inline(NovelInline s) => switch (s) {
  NovelPlain() => 'P:${s.text}',
  NovelRuby() => 'R:${s.base}|${s.reading}',
  NovelLink() => 'K:${s.text}|${s.url}',
  NovelPageJump() => 'J:${s.page}',
};

String _block(NovelBlock b) => switch (b) {
  NovelLine() =>
    'L${b.blankLinesBefore > 0 ? '+${b.blankLinesBefore}' : ''}${b.authorIndented ? '>' : ''}[${b.spans.map(_inline).join(',')}]',
  NovelChapterTitle() => 'C:${b.title}',
  NovelPageBreak() => 'PB',
  NovelUploadedImage() => 'U:${b.id}:${b.image == null ? 'null' : 'img'}',
  NovelEmbeddedWork() => 'E:${b.key}:${b.illustId}:${b.page}:${b.work == null ? 'null' : 'work'}',
};

List<String> _parse(
  String text, {
  Map<String, WebviewNovelImage> images = const {},
  Map<String, WebviewNovelEmbeddedWork> works = const {},
}) => parseNovelText(text, uploadedImages: images, embeddedWorks: works).map(_block).toList();

WebviewNovelImage _image(String id) => WebviewNovelImage(
  novelImageId: id,
  urls: const WebviewNovelImageUrls(original: 'https://example.com/o.png'),
);

WebviewNovelEmbeddedWork _work(String key, {int illustId = 1, int page = 1}) => WebviewNovelEmbeddedWork(
  key: key,
  illustId: illustId,
  page: page,
  visible: true,
  title: 'Work',
  xRestrict: 0,
  userId: '2',
  userName: 'Author',
);

WebviewNovel _novel(String text, {List<WebviewNovelEmbeddedWork> illusts = const [], List<WebviewNovelImage> images = const []}) =>
    WebviewNovel(
      id: '1',
      title: 'Novel',
      userId: '2',
      coverUrl: '',
      tags: const [],
      caption: '',
      cdate: '',
      rating: const NovelRating(like: 0, bookmark: 0, view: 0),
      text: text,
      illusts: illusts,
      images: images,
      glossaryItems: const [],
      replaceableItemIds: const [],
      aiType: 0,
      isOriginal: false,
    );

void main() {
  group('line endings', () {
    test('CRLF, CR and LF each break a line', () {
      expect(_parse('a\r\nb\rc\nd'), ['L[P:a]', 'L[P:b]', 'L[P:c]', 'L[P:d]']);
    });

    test('CRLF counts as one break, so it adds no blank line', () {
      expect(_parse('a\r\nb'), ['L[P:a]', 'L[P:b]']);
    });

    test('two CRs and CRLF-CRLF each leave one blank line', () {
      expect(_parse('a\r\rb'), ['L[P:a]', 'L+1[P:b]']);
      expect(_parse('a\r\n\r\nb'), ['L[P:a]', 'L+1[P:b]']);
    });
  });

  group('blank lines', () {
    test('empty and whitespace-only text yield no blocks', () {
      expect(_parse(''), isEmpty);
      expect(_parse('\n\n'), isEmpty);
      expect(_parse('  \t\u3000\n\u3000\n'), isEmpty);
    });

    test('leading blank lines count in the first line', () {
      expect(_parse('\n\n第一行'), ['L+2[P:第一行]']);
    });

    test('blank lines between lines count in the following line', () {
      expect(_parse('a\n\n\nb\nc'), ['L[P:a]', 'L+2[P:b]', 'L[P:c]']);
    });

    test('a line of only spaces, tabs or U+3000 is blank', () {
      expect(_parse('a\n \n\t\n\u3000\nb'), ['L[P:a]', 'L+3[P:b]']);
    });

    test('trailing blank lines produce nothing', () {
      expect(_parse('a\n\n\n'), ['L[P:a]']);
      expect(_parse('a\n  \n\u3000'), ['L[P:a]']);
    });

    test('blank lines before a line that a marker splits go to its first piece only', () {
      expect(_parse('x\n\n\nabc[newpage]def'), ['L[P:x]', 'L+2[P:abc]', 'PB', 'L[P:def]']);
    });

    test('blank lines before a marker-only line count from that source line, not a later one', () {
      expect(_parse('a\n\n[newpage]\n\nb'), ['L[P:a]', 'PB', 'L+1[P:b]']);
    });

    test('blank lines before a line that starts with a marker go to the next line, not the later piece', () {
      expect(_parse('x\n\n[newpage]def'), ['L[P:x]', 'PB', 'L[P:def]']);
    });
  });

  group('author indent', () {
    test('U+3000 start marks the line and stays in the text', () {
      expect(_parse('\u3000\u3000本文'), ['L>[P:\u3000\u3000本文]']);
    });

    test('a space start marks the line and stays in the text', () {
      expect(_parse(' text'), ['L>[P: text]']);
    });

    test('a tab start marks the line and stays in the text', () {
      expect(_parse('\ttext'), ['L>[P:\ttext]']);
    });

    test('a line not starting with whitespace is not indented', () {
      expect(_parse('te xt\u3000'), ['L[P:te xt\u3000]']);
    });

    test('the indent stays in the first plain before inline markers', () {
      expect(_parse('\u3000[[rb:漢 > かん]]字'), ['L>[P:\u3000,R:漢|かん,P:字]']);
    });

    test('indent applies to the first piece of a split line only', () {
      final blocks = parseNovelText('\u3000abc[newpage]def');
      expect((blocks[0] as NovelLine).authorIndented, isTrue);
      expect((blocks[2] as NovelLine).authorIndented, isFalse);
      expect((blocks[2] as NovelLine).blankLinesBefore, 0);
    });
  });

  group('block markers', () {
    test('a marker splits a line into line, block, line', () {
      expect(_parse('abc[newpage]def'), ['L[P:abc]', 'PB', 'L[P:def]']);
    });

    test('several markers in one line', () {
      expect(_parse('a[chapter:T]b[newpage]c'), ['L[P:a]', 'C:T', 'L[P:b]', 'PB', 'L[P:c]']);
    });

    test('whitespace between or around markers yields no line', () {
      expect(_parse('  [newpage] \u3000[newpage]\t'), ['PB', 'PB']);
    });

    test('a marker alone on its line yields only the block', () {
      expect(_parse('a\n[newpage]\nb'), ['L[P:a]', 'PB', 'L[P:b]']);
    });

    test('inline markers stay with their piece of a split line', () {
      expect(_parse('[[rb:a>b]]x[newpage][jump:2]'), ['L[R:a|b,P:x]', 'PB', 'L[J:2]']);
    });
  });

  group('chapter marker', () {
    test('title is trimmed', () {
      expect(_parse('[chapter:  第一章 ]'), ['C:第一章']);
    });

    test('title may contain spaces and symbols inside', () {
      expect(_parse('[chapter:Part 1: Start]'), ['C:Part 1: Start']);
    });

    test('empty title stays literal', () {
      expect(_parse('[chapter:]'), ['L[P:[chapter:]]']);
    });
  });

  group('uploaded image marker', () {
    test('looks up the image by id', () {
      final img = _image('77');
      final blocks = parseNovelText('[uploadedimage:77]', uploadedImages: {'77': img});
      final block = blocks.single as NovelUploadedImage;
      expect(block.id, '77');
      expect(block.image, same(img));
    });

    test('unknown id gives a block with a null image', () {
      expect(_parse('[uploadedimage:5]', images: {'6': _image('6')}), ['U:5:null']);
    });

    test('empty id stays literal', () {
      expect(_parse('[uploadedimage:]'), ['L[P:[uploadedimage:]]']);
    });
  });

  group('pixivimage marker', () {
    test('page defaults to 1 and the work is found by the exact payload', () {
      final w = _work('123');
      final block = parseNovelText('[pixivimage:123]', embeddedWorks: {'123': w}).single as NovelEmbeddedWork;
      expect(block.key, '123');
      expect(block.illustId, 123);
      expect(block.page, 1);
      expect(block.work, same(w));
    });

    test('explicit page', () {
      final w = _work('123-4');
      final block = parseNovelText('[pixivimage:123-4]', embeddedWorks: {'123-4': w}).single as NovelEmbeddedWork;
      expect(block.key, '123-4');
      expect(block.illustId, 123);
      expect(block.page, 4);
      expect(block.work, same(w));
    });

    test('lookup is by the exact payload: an id without page does not match an id-1 key', () {
      expect(_parse('[pixivimage:123]', works: {'123-1': _work('123-1')}), ['E:123:123:1:null']);
      expect(_parse('[pixivimage:123-1]', works: {'123': _work('123')}), ['E:123-1:123:1:null']);
    });

    test('missing work gives a block with a null work', () {
      expect(_parse('[pixivimage:9-2]'), ['E:9-2:9:2:null']);
    });

    test('non-numeric, zero, negative or malformed payloads stay literal', () {
      for (final p in ['abc', '0', '12-0', '12-x', '-5', '', '1-2-3', '12-', '1.5']) {
        expect(_parse('[pixivimage:$p]'), ['L[P:[pixivimage:$p]]'], reason: p);
      }
    });
  });

  group('ruby marker', () {
    test('base and reading are trimmed', () {
      expect(_parse('[[rb:  漢字  >  かんじ ]]'), ['L[R:漢字|かんじ]']);
    });

    test('base may contain inner spaces', () {
      expect(_parse('[[rb:New York > ny]]'), ['L[R:New York|ny]']);
    });

    test('splits at the first >', () {
      expect(_parse('[[rb:a > b > c]]'), ['L[R:a|b > c]']);
    });

    test('inside text', () {
      expect(_parse('前[[rb:漢>かん]]後'), ['L[P:前,R:漢|かん,P:後]']);
    });

    test('missing > stays literal', () {
      expect(_parse('[[rb:abc]]'), ['L[P:[[rb:abc]]]']);
    });

    test('empty base or empty reading stays literal', () {
      expect(_parse('[[rb: > x]]'), ['L[P:[[rb: > x]]]']);
      expect(_parse('[[rb:a > ]]'), ['L[P:[[rb:a > ]]]']);
    });
  });

  group('jumpuri marker', () {
    test('http and https URLs become links with trimmed sides', () {
      expect(_parse('[[jumpuri: 官网 > https://example.com/a?b=1 ]]'), ['L[K:官网|https://example.com/a?b=1]']);
      expect(_parse('[[jumpuri:site > http://example.com]]'), ['L[K:site|http://example.com]']);
    });

    test('link url is a parsed Uri', () {
      final link = (parseNovelText('[[jumpuri:t > https://example.com/x]]').single as NovelLine).spans.single as NovelLink;
      expect(link.text, 't');
      expect(link.url, Uri.parse('https://example.com/x'));
    });

    test('splits at the last >, so the text may contain >', () {
      expect(_parse('[[jumpuri:a > b > https://example.com]]'), ['L[K:a > b|https://example.com]']);
    });

    test('a non-http(s) URL leaves the text as plain text, merged with neighbours', () {
      expect(_parse('see [[jumpuri:here > ftp://example.com/]] now'), ['L[P:see here now]']);
      expect(_parse('[[jumpuri:here > javascript:alert(1)]]'), ['L[P:here]']);
    });

    test('a URL without a host leaves the text as plain text', () {
      expect(_parse('[[jumpuri:here > https://]]'), ['L[P:here]']);
    });

    test('an unparsable URL leaves the text as plain text', () {
      expect(_parse('[[jumpuri:here > http://[bad]]'), ['L[P:here]']);
    });

    test('missing > stays literal', () {
      expect(_parse('[[jumpuri:https://example.com]]'), ['L[P:[[jumpuri:https://example.com]]]']);
    });

    test('empty text stays literal', () {
      expect(_parse('[[jumpuri: > https://example.com]]'), ['L[P:[[jumpuri: > https://example.com]]]']);
    });
  });

  group('jump marker', () {
    test('positive integer becomes a page jump', () {
      expect(_parse('go [jump:12] now'), ['L[P:go ,J:12,P: now]']);
    });

    test('zero, non-numeric, negative or empty stays literal', () {
      for (final p in ['0', 'x', '-1', '', '1.5', '2a']) {
        expect(_parse('[jump:$p]'), ['L[P:[jump:$p]]'], reason: p);
      }
    });
  });

  group('plain text', () {
    test('unknown brackets stay literal', () {
      expect(_parse('[foo:bar] [[x]] [abc [newpag]'), ['L[P:[foo:bar] [[x]] [abc [newpag]]']);
    });

    test('adjacent plain text including literal markers is merged into one NovelPlain', () {
      expect(_parse('a[chapter:]b[jump:0]c'), ['L[P:a[chapter:]b[jump:0]c]']);
    });

    test('no empty NovelPlain is produced next to inline markers', () {
      final line = parseNovelText('[[rb:a>b]][jump:3]').single as NovelLine;
      expect(line.spans, hasLength(2));
      expect(line.spans.whereType<NovelPlain>(), isEmpty);
    });
  });

  group('lengths', () {
    test('inline lengths', () {
      expect(const NovelPlain('abc').length, 3);
      expect(const NovelPlain('').length, 0);
      expect(const NovelRuby('漢字', 'かんじ').length, 2);
      expect(NovelLink('官网', Uri.parse('https://e.com')).length, 2);
      expect(const NovelPageJump(5).length, 1);
    });

    test('line length is the sum of its spans', () {
      expect(NovelLine([const NovelPlain('abc'), const NovelRuby('xy', 'r'), NovelLink('lnk', Uri.parse('https://e.com')), const NovelPageJump(2)]).length, 3 + 2 + 3 + 1);
      expect(const NovelLine([]).length, 0);
    });

    test('block lengths', () {
      expect(const NovelChapterTitle('第一章').length, 3);
      expect(const NovelPageBreak().length, 0);
      expect(const NovelUploadedImage('1', null).length, 1);
      expect(const NovelEmbeddedWork('1-1', 1, 1, null).length, 1);
    });

    test('parsed blocks report the same lengths', () {
      final blocks = parseNovelText('ab[[rb:漢>か]]\n[chapter: xyz ]\n[newpage]\n[uploadedimage:1]\n[pixivimage:2]');
      expect(blocks.map((b) => b.length), [3, 3, 0, 1, 1]);
    });
  });

  group('parseWebviewNovel', () {
    test('resolves uploaded images by id and works by key', () {
      final novel = _novel(
        '[uploadedimage:img1]\n[pixivimage:10-2]\n[pixivimage:10]\n[uploadedimage:other]',
        illusts: [_work('10-2', illustId: 10, page: 2)],
        images: [_image('img1')],
      );
      final blocks = parseWebviewNovel(novel);
      expect(blocks.map(_block), ['U:img1:img', 'E:10-2:10:2:work', 'E:10:10:1:null', 'U:other:null']);
      expect((blocks[0] as NovelUploadedImage).image, same(novel.images.single));
      expect((blocks[1] as NovelEmbeddedWork).work, same(novel.illusts.single));
    });

    test('plain text parses like parseNovelText', () {
      expect(parseWebviewNovel(_novel('a\n\nb')).map(_block), ['L[P:a]', 'L+1[P:b]']);
    });
  });
}
