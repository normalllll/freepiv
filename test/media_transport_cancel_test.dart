import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/media/logic.dart';

void main() {
  test('cancelling before the end stops the download once and releases it', () async {
    var sourceCancelled = false;
    final source = StreamController<int>(onCancel: () => sourceCancelled = true);
    final calls = <String>[];
    final subscription = stopOnCancel(source.stream, stop: () => calls.add('stop'), release: () => calls.add('release')).listen((_) {});
    source.add(1);
    await pumpEventQueue();

    await subscription.cancel();

    expect(calls, ['stop', 'release']);
    expect(sourceCancelled, isTrue);
  });

  test('a download that ends is released without being stopped', () async {
    final calls = <String>[];
    final chunks = await stopOnCancel(Stream.fromIterable([1, 2]), stop: () => calls.add('stop'), release: () => calls.add('release')).toList();

    expect(chunks, [1, 2]);
    expect(calls, ['release']);
  });

  test('a download that fails is released without being stopped, and passes its error on', () async {
    final calls = <String>[];
    await expectLater(
      stopOnCancel(Stream<int>.error(StateError('offline')), stop: () => calls.add('stop'), release: () => calls.add('release')).toList(),
      throwsStateError,
    );
    expect(calls, ['release']);
  });
}
