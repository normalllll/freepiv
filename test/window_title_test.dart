import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/window/window_title.dart';
import 'package:freepiv/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = AppLocale.enUs.translations;

  test('route title follows detail data, related works, and back without fetching', () {
    final registry = WindowTitleRegistry();
    addTearDown(registry.dispose);
    final owner = Object();

    expect(resolveWindowTitle(Uri.parse('/'), translations, registry), translations.navigation.home);
    expect(resolveWindowTitle(Uri.parse('/illust/123456789'), translations, registry), 'Illust: 123456789');
    registry.setWork('/illust/123456789', owner, const WorkWindowTitle(id: 123456789, title: 'A long work title', kind: 'manga'));
    expect(resolveWindowTitle(Uri.parse('/illust/123456789'), translations, registry), 'Manga: 123456789 · A long work title');
    expect(resolveWindowTitle(Uri.parse('/illust/123456789/related'), translations, registry), 'Related works · A long work title');
    expect(resolveWindowTitle(Uri.parse('/illust/123456789'), translations, registry), 'Manga: 123456789 · A long work title');
    registry.remove('/illust/123456789', owner);
    expect(resolveWindowTitle(Uri.parse('/illust/123456789/related'), translations, registry), 'Related works · Illust: 123456789');
    expect(resolveWindowTitle(Uri.parse('/downloads'), translations, registry), translations.settings.downloads.tasksTitle);
  });

  test('stacked copies of the same detail restore the previous title', () {
    final registry = WindowTitleRegistry();
    addTearDown(registry.dispose);
    final first = Object();
    final second = Object();
    registry.setWork('/novel/7', first, const WorkWindowTitle(id: 7, title: 'First', kind: 'novel'));
    registry.setWork('/novel/7', second, const WorkWindowTitle(id: 7, title: 'Second', kind: 'novel'));
    expect(resolveWindowTitle(Uri.parse('/novel/7'), translations, registry), 'Novel: 7 · Second');
    registry.remove('/novel/7', second);
    expect(resolveWindowTitle(Uri.parse('/novel/7'), translations, registry), 'Novel: 7 · First');
  });
}
