import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/settings/presentation/settings_page.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  test('every locale is offered once, named in its own language', () {
    expect(languageOptionNames.keys.toSet(), AppLocale.values.toSet());
    expect(languageOptionNames.values.toList(), ['English', '简体中文', '繁體中文', '日本語']);
  });
}
