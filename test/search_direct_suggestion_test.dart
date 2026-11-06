import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/search/logic/search_logic.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_autocomplete_session.dart';
import 'package:freepiv/features/search/presentation/widgets/search_box/search_models.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.enUs));

  test('a bare number offers to open the work or user, worded for the locale', () async {
    for (final (locale, illust, user, novel) in [
      (AppLocale.enUs, 'Open illustration #123', 'Open user #123', 'Open novel #123'),
      (AppLocale.zhCn, '打开插画 #123', '打开用户 #123', '打开小说 #123'),
      (AppLocale.jaJp, 'イラスト #123 を開く', 'ユーザー #123 を開く', '小説 #123 を開く'),
      (AppLocale.zhHantTw, '開啟插畫 #123', '開啟使用者 #123', '開啟小說 #123'),
    ]) {
      await LocaleSettings.setLocale(locale);
      final session = SearchAutocompleteSession(initialType: SearchType.illust);
      addTearDown(session.dispose);
      session.controller.text = '123';
      final direct = session.suggestions.where((suggestion) => suggestion.id != null).toList();
      expect(direct.map((suggestion) => suggestion.kind), [SearchItemKind.illust, SearchItemKind.user, SearchItemKind.novel]);
      expect(direct.map((suggestion) => suggestion.label), [illust, user, novel], reason: '$locale');
      expect(direct.every((suggestion) => !suggestion.label.contains(':')), isTrue);
    }
  });

  test('no ID suggestions once a word is completed', () {
    final session = SearchAutocompleteSession(initialType: SearchType.illust);
    addTearDown(session.dispose);
    session.controller.text = 'miku 123';
    expect(session.suggestions.where((suggestion) => suggestion.id != null), isEmpty);
  });
}
