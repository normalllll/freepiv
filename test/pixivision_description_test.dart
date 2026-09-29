import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/pixivision/description.dart';

void main() {
  test('decodes entities and drops the site marker', () {
    expect(
      cleanPixivisionDescription('[pixivision]Savior (hereinafter referred to as&nbsp;Savior of the Divine)'),
      'Savior (hereinafter referred to as Savior of the Divine)',
    );
    expect(cleanPixivisionDescription('【pixivision】A &amp; B &lt;c&gt; &quot;d&quot; &#39;e&#39; &#x41;&#66;'), 'A & B <c> "d" \'e\' AB');
  });

  test('collapses whitespace and tolerates unknown or invalid entities', () {
    expect(cleanPixivisionDescription('  a\n\n b&nbsp;&nbsp;c &unknown; &#0; '), 'a b c &unknown; &#0;');
    expect(cleanPixivisionDescription(' [pixivision]  '), '');
  });
}
