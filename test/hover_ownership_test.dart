import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/illust_bookmark_button.dart';
import 'package:freepiv/shared/widgets/user_follow_button.dart';

void main() {
  testWidgets('card yields hover to bookmarks, follow, menus, nested links and disabled actions', (tester) async {
    for (final child in <Widget>[
      const IllustBookmarkButton(illustId: 9001, initialIsBookmarked: false),
      const IllustBookmarkButton(illustId: 9002, initialIsBookmarked: false, isNovel: true),
      const IllustBookmarkButton(illustId: 9003, initialIsBookmarked: false, floating: true),
      const UserFollowButton(userId: 9001, initialIsFollowed: false),
      FrostMenuButton<int>(
        value: 1,
        items: const [FrostSelectItem(value: 1, label: 'More')],
        onSelected: (_) {},
        child: const Padding(padding: EdgeInsets.all(16), child: Text('Menu')),
      ),
      FrostIconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      const IconButton(onPressed: null, icon: Icon(Icons.download)),
      TextButton(onPressed: () {}, child: const Text('Open')),
      FrostClickSurface(
        onTap: () {},
        child: const Padding(padding: EdgeInsets.all(16), child: Text('Creator')),
      ),
    ]) {
      var parentHovered = false;
      var parentTaps = 0;
      final parentKey = UniqueKey();
      final childKey = UniqueKey();
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.light(platform: TargetPlatform.windows, locale: const Locale('en')),
              home: Scaffold(
                body: Center(
                  child: Material(
                    child: FrostClickSurface(
                      key: parentKey,
                      onTap: () => parentTaps++,
                      onHover: (value) => parentHovered = value,
                      child: SizedBox(
                        width: 320,
                        height: 160,
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: KeyedSubtree(key: childKey, child: child),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      final cardPoint = tester.getTopLeft(find.byKey(parentKey)) + const Offset(16, 16);
      await mouse.moveTo(cardPoint);
      await tester.pumpAndSettle();
      expect(parentHovered, isTrue, reason: child.runtimeType.toString());
      await mouse.moveTo(tester.getCenter(find.byKey(childKey)));
      await tester.pumpAndSettle();
      expect(parentHovered, isFalse, reason: '${child.runtimeType} must own its hover');
      await mouse.moveTo(cardPoint);
      await tester.pumpAndSettle();
      expect(parentHovered, isTrue);
      expect(parentTaps, 0);
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(parentHovered, isFalse);
      expect(tester.takeException(), isNull);
    }
  });
}
