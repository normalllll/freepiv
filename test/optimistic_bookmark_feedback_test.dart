import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/shared/logic/illust_bookmark_logic.dart';
import 'package:freepiv/shared/logic/optimistic_mutation.dart';

void main() {
  test('slow bookmark failure shows the optimistic state then rolls it back', () async {
    var state = const IllustBookmarkState(illustId: 42, isBookmarked: false, isNovel: false);
    final pending = Completer<void>();
    final mutation = runOptimisticMutation<IllustBookmarkState>(
      previous: state,
      optimistic: state.copyWith(isBookmarked: true, updating: true),
      read: () => state,
      write: (next) => state = next,
      mutate: () => pending.future,
      settle: (current) => current.copyWith(updating: false),
      rollback: (previous) => previous.copyWith(updating: false),
    );

    expect(state.isBookmarked, isTrue);
    expect(state.updating, isTrue);
    pending.completeError(StateError('fixture failure'));
    await expectLater(mutation, throwsStateError);
    expect(state.isBookmarked, isFalse);
    expect(state.updating, isFalse);
  });
}
