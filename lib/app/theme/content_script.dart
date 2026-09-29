import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_system_fonts.dart';

/// Regional CJK glyph set a piece of user content should be drawn with.
enum ContentScript { japanese, simplifiedChinese, traditionalChinese }

// Common characters whose simplified and traditional forms differ. A text is
// Chinese only when it contains Han characters and no kana; the variant is
// whichever set it hits more often.
const _simplifiedOnly = '们这说对时会过发经还进门问间长东车书马鸟获风纪级费许为么们个来国说时过后发样实动现点见给关还没种话当进边问题开员学爱让认该应这吗页头电热听写达义钱层据图联场团单节论处总观类将带资证务战际设导标该让岁历复杂获几无块专两严丽举乐乡买亏亚产亲们众优伤传伦伪';
const _traditionalOnly = '們這說對時會過發經還進門問間長東車書馬鳥獲風紀級費許為麼個來國後樣實動現點見給關沒種話當邊問題開員學愛讓認該應嗎頁頭電熱聽寫達義錢層據圖聯場團單節論處總觀類將帶資證務戰際設導標歲歷複雜幾無塊專兩嚴麗舉樂鄉買虧亞產親眾優傷傳倫偽';

final _simplifiedSet = _simplifiedOnly.runes.toSet();
final _traditionalSet = _traditionalOnly.runes.toSet();

/// Classifies content text by script. Kana means Japanese; otherwise Han text
/// with simplified-only or traditional-only characters is Chinese. Anything
/// undecidable returns null and keeps the Japanese-first default, since
/// Pixiv content is predominantly Japanese.
ContentScript? detectContentScript(String text) {
  var han = false;
  var simplified = 0;
  var traditional = 0;
  for (final rune in text.runes) {
    if ((rune >= 0x3040 && rune <= 0x30FF) || (rune >= 0x31F0 && rune <= 0x31FF)) return ContentScript.japanese;
    if (rune >= 0x4E00 && rune <= 0x9FFF) {
      han = true;
      if (_simplifiedSet.contains(rune)) simplified++;
      if (_traditionalSet.contains(rune)) traditional++;
    }
  }
  if (!han || simplified == traditional) return null;
  return simplified > traditional ? ContentScript.simplifiedChinese : ContentScript.traditionalChinese;
}

Locale _localeFor(ContentScript? script) => switch (script) {
  ContentScript.simplifiedChinese => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ContentScript.traditionalChinese => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ContentScript.japanese || null => const Locale('ja'),
};

/// [style] with the locale and CJK fallback order for [text]'s own script,
/// so a Simplified Chinese title does not mix Japanese and Chinese glyphs.
/// Interface text keeps following the interface language.
TextStyle contentTextStyle(BuildContext context, String text, [TextStyle? style]) {
  final locale = _localeFor(detectContentScript(text));
  final fonts = AppSystemFonts.resolve(platform: Theme.of(context).platform, locale: locale);
  return (style ?? const TextStyle()).copyWith(locale: locale, fontFamily: fonts.family, fontFamilyFallback: fonts.fallbacks);
}
