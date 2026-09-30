import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/platform/reader_volume_keys.dart';
import 'package:freepiv/features/novel/presentation/reader/reader_scroll_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scroll distance uses elapsed time and excludes paused time', () {
    final clock = ReaderScrollClock();
    expect(clock.advance(Duration.zero, 36), 0);
    expect(clock.advance(const Duration(milliseconds: 250), 36), 9);
    expect(clock.advance(const Duration(seconds: 1), 36), 27);
    clock.reset();
    expect(clock.advance(const Duration(seconds: 20), 36), 0);
    expect(clock.advance(const Duration(milliseconds: 20500), 48), 24);
    expect(clock.advance(const Duration(milliseconds: 20500), 48), 0);
  });

  test('volume capture releases and a stale reader cannot disable its successor', () async {
    const channel = MethodChannel('test/reader-volume');
    final calls = <bool>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final service = ReaderVolumeKeys(channel: channel, supported: true);
    final first = service.claim(onTurn: (_) {}, onError: () {}, onFocusChanged: (_) {});
    first.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, true);
    first.setEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, false);
    final second = service.claim(onTurn: (_) {}, onError: () {}, onFocusChanged: (_) {});
    second.setEnabled(true);
    first.release();
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, true);
    second.release();
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, false);
  });

  test('capture failure releases platform ownership and permits explicit retry', () async {
    const channel = MethodChannel('test/reader-volume-failure');
    final calls = <bool>[];
    var errors = 0;
    var fail = true;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.arguments as bool);
      if (call.arguments == true && fail) throw PlatformException(code: 'capture-failed');
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final service = ReaderVolumeKeys(channel: channel, supported: true);
    final lease = service.claim(onTurn: (_) {}, onError: () => errors++, onFocusChanged: (_) {});
    lease.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(errors, 1);
    expect(calls.last, false);
    fail = false;
    lease.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, true);
    lease.release();
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, false);
  });

  test('covered reader can resume its lease after the newer reader exits', () async {
    const channel = MethodChannel('test/reader-volume-resume');
    final calls = <bool>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final service = ReaderVolumeKeys(channel: channel, supported: true);
    final first = service.claim(onTurn: (_) {}, onError: () {}, onFocusChanged: (_) {});
    first.setEnabled(true);
    final second = service.claim(onTurn: (_) {}, onError: () {}, onFocusChanged: (_) {});
    second.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    second.release();
    first.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, true);
    first.release();
    await Future<void>.delayed(Duration.zero);
    expect(calls.last, false);
  });
}
