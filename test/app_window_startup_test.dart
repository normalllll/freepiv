import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/app/window/app_window.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:frost_ui/frost_ui.dart';

/// A window whose native side fails with errors frost_window does not wrap.
class _BrokenWindow extends FrostWindowController {
  _BrokenWindow({required this.failShow}) : super(minimumSize: appMinimumWindowSize);

  final bool failShow;
  var shown = 0;

  @override
  Future<FrostWindowPlacementResult> prepare({FrostWindowPlacement? saved, FrostWindowSizing? sizing, String? displayId, bool useCursor = false}) =>
      Future.error(StateError('prepare broke'));

  @override
  Future<void> show() async {
    shown++;
    if (failShow) throw StateError('show broke');
  }
}

void main() {
  for (final failShow in [false, true]) {
    testWidgets('startup asks the window to show and keeps running when ${failShow ? 'prepare and show fail' : 'prepare fails'}', (tester) async {
      await AppSettings.initialize(store: SampleSettingsStore(const {}));
      final reported = <Object>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      try {
        final window = _BrokenWindow(failShow: failShow);
        final prepared = await prepareAppWindow(window: window);
        expect(prepared, same(window), reason: 'a failed placement still yields the window');

        await revealAppWindow(window);
        expect(window.shown, 1, reason: 'the window is always asked to show');
        expect(reported, [isStateError, if (failShow) isStateError], reason: 'failures are reported, not thrown');
        window.dispose();
      } finally {
        FlutterError.onError = previous;
      }
    }, skip: !hasDesktopWindow);
  }
}
