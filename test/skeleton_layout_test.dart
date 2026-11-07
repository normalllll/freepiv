import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/features/illust/presentation/illust_info.dart';
import 'package:freepiv/ui/compositions/artwork_card.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

void main() {
  testWidgets('a skeleton card has the loaded card\'s height, two lines and bookmark', (tester) async {
    const width = 220.0;
    const real = ValueKey('real'), bones = ValueKey('bones');
    await mountPilotPage(
      tester,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: real,
            width: width,
            child: AppArtworkCard(illust: illustPlaceholder(), square: true),
          ),
          const SizedBox(
            key: bones,
            width: width,
            child: AppArtworkCardSkeleton(aspectRatio: 1),
          ),
        ],
      ),
    );
    expect(tester.getSize(find.byKey(bones)).height, tester.getSize(find.byKey(real)).height);
    final footer = find.descendant(of: find.byKey(bones), matching: find.byType(AppArtworkCardFooter));
    expect(footer, findsOneWidget);
    expect(find.descendant(of: footer, matching: find.byType(FrostButton)), findsOneWidget);
    expectNoLayoutErrors(tester);
  });
}
