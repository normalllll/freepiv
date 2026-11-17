// Original sample novel texts for the sample app and its tests: one in
// Chinese divided by chapters, one in Japanese divided only by `[newpage]`,
// and a long generated one for measuring performance. They use every marker
// the reader understands.
import 'package:freepiv/dev/sample_images.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';

/// A sample novel text and the images and works its markers refer to.
typedef SampleNovelBody = ({String text, List<WebviewNovelImage> images, List<WebviewNovelEmbeddedWork> works});

/// The sample text for the novel with [novelId]: the first sample novel is
/// Chinese, the third is the long one, odd ones are Japanese and the rest
/// Chinese.
SampleNovelBody sampleNovelBody(int novelId) => switch (novelId - 70000) {
  2 => (text: sampleLongNovelText(), images: const [], works: const []),
  final n when n.isOdd => (text: _japaneseText, images: _images, works: _works),
  _ => (text: _chineseText, images: _images, works: _works),
};

// Width and height of the five uploaded pictures: wide, square, tall,
// panoramic and very tall.
const _imageSizes = [(1200, 675), (900, 900), (800, 1200), (1400, 560), (600, 1500)];

final _images = [
  for (final (index, (width, height)) in _imageSizes.indexed)
    WebviewNovelImage(
      novelImageId: '${index + 1}',
      urls: WebviewNovelImageUrls(
        size128X128: sampleImageUrl(200 + index, width: 128, height: 128),
        size240Mw: sampleImageUrl(200 + index, width: 240, height: (240 * height / width).round()),
        size480Mw: sampleImageUrl(200 + index, width: 480, height: (480 * height / width).round()),
        size1200X1200: sampleImageUrl(200 + index, width: 1200, height: (1200 * height / width).round()),
        original: sampleImageUrl(200 + index, width: width, height: height),
      ),
    ),
];

/// A visible work with a picture, and one the viewer may not see.
final _works = [
  WebviewNovelEmbeddedWork(
    key: '9001',
    illustId: 9001,
    page: 1,
    visible: true,
    title: 'Lanterns on the pier',
    xRestrict: 0,
    userId: '2000',
    userName: 'Sample author',
    imageMedium: sampleImageUrl(210, width: 540, height: 756),
    imageOriginal: sampleImageUrl(210, width: 1000, height: 1400),
  ),
  const WebviewNovelEmbeddedWork(
    key: '9002-2',
    illustId: 9002,
    page: 2,
    visible: false,
    availableMessage: 'This work is private.',
    title: '',
    xRestrict: 0,
    userId: '2001',
    userName: '',
  ),
];

const _indent = '　';

final _chineseText = [
  '[chapter:第一章　黄昏]',
  '$_indent傍晚，渔船一艘接一艘地回到港湾，镇上的人[[rb:提着灯 > tí zhe dēng]]站在码头边等候。',
  '',
  '$_indent$_indent海风带着[[rb:潮汐 > cháo xī]]的气味，吹过晾在竹竿上的渔网。',
  '',
  '',
  '[uploadedimage:1]',
  '',
  '“你今天回来得晚了。”老人说。',
  '“风向变了。”她把缆绳抛给他，没有多说。',
  '[pixivimage:9001]',
  '想知道这座小镇的更多故事，可以看看[[jumpuri:作者的主页 > https://example.com/author]]，或者直接跳到[jump:2]。',
  '[newpage]',
  '[chapter:第二章　港口]',
  '$_indent夜里的港口很安静，只有浮标上的小灯一明一灭。',
  '[uploadedimage:2]',
  '',
  '',
  '',
  '$_indent她在栈桥尽头坐了很久，直到潮水退去，露出长满青苔的石阶。',
  '[uploadedimage:3]',
  '“明天还出海吗？”',
  '“出。”',
  '[pixivimage:9002-2]',
  '[newpage]',
  '[chapter:第三章　清晨]',
  '$_indent天亮得很慢。云层裂开一道缝，光落在刚刚靠岸的第一艘船上。',
  '[uploadedimage:4]',
  '$_indent$_indent镇上的钟敲了六下，面包店的门开了，热气从门缝里涌出来。',
  '[uploadedimage:5]',
  '$_indent故事到这里就结束了，谢谢你读到最后。',
].join('\n');

final _japaneseText = [
  '$_indent夕暮れになると、漁船が一艘ずつ港へ戻ってきて、町の人々は[[rb:提灯 > ちょうちん]]を手に桟橋で待っていた。',
  '',
  '$_indent$_indent潮風が干した網を揺らし、遠くで[[rb:鴎 > かもめ]]が鳴いた。',
  '',
  '',
  '[uploadedimage:1]',
  '「今日は遅かったな」と老人が言った。',
  '「風向きが変わったの」彼女は綱を投げ渡した。',
  '[pixivimage:9001]',
  '続きは[[jumpuri:作者のページ > https://example.com/author]]で読めます。三つ目の節へは[jump:3]から。',
  '[newpage]',
  '$_indent夜の港はひっそりとして、浮標の小さな灯だけが点いたり消えたりしていた。',
  '[uploadedimage:2]',
  '',
  '',
  '',
  '$_indent彼女は桟橋の先に長いあいだ座り、潮が引いて苔むした石段が現れるのを見ていた。',
  '[uploadedimage:3]',
  '「明日も出るの？」',
  '「出るよ」',
  '[pixivimage:9002-2]',
  '[newpage]',
  '$_indent夜明けはゆっくりと来た。雲の切れ間から光が差し、戻ったばかりの最初の船を照らした。',
  '[uploadedimage:4]',
  '$_indent$_indent町の鐘が六つ鳴り、パン屋の戸が開いて、温かい湯気が流れ出た。',
  '[uploadedimage:5]',
  '$_indentお話はここでおしまいです。最後まで読んでくれてありがとう。',
].join('\n');

const _longSentences = [
  '海风从港口的方向吹来，带着潮湿的盐味。',
  '她把外套的领子拉高，沿着栈桥慢慢往前走。',
  '远处的灯塔一明一灭，像是在回答谁的呼唤。',
  '“你相信那些传说吗？”他忽然问。',
  '没有人回答，只有木板在脚下发出轻轻的响声。',
  '渔网挂在竹竿上，被风吹得微微晃动。',
  '[[rb:黎明 > lí míng]]前的海面是一片安静的灰色。',
  '老人点了一支烟，目光越过防波堤，落在很远的地方。',
  '他们谈起了去年的风暴，也谈起了再也没有回来的那艘船。',
  '小镇的钟楼敲了十二下，声音在水面上拖得很长。',
];

/// A text of about 270,000 characters in 90 chapters of paragraphs of
/// varying length, for measuring performance on a very long novel.
String sampleLongNovelText({int chapters = 90, int charactersPerChapter = 3300}) {
  final text = StringBuffer();
  var step = 0;
  for (var chapter = 1; chapter <= chapters; chapter++) {
    if (chapter > 1) text.write('\n[newpage]\n');
    text.write('[chapter:第$chapter章]\n');
    var written = 0;
    while (written < charactersPerChapter) {
      final paragraph = StringBuffer(step % 3 == 0 ? _indent : '');
      final sentences = 1 + step % 4;
      for (var i = 0; i < sentences; i++) {
        paragraph.write(_longSentences[(step + i * 3) % _longSentences.length]);
      }
      step++;
      written += paragraph.length;
      text.write(paragraph);
      text.write(step % 7 == 0 ? '\n\n\n' : '\n');
    }
  }
  return text.toString();
}
