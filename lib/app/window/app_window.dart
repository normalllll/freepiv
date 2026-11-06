import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:frost_ui/frost_ui.dart';

/// Narrow desktop windows use the same compact layout as a phone.
const appMinimumWindowSize = Size(320, 480);

/// The first window of a fresh install: the acceptance window size, shrunk
/// to fit smaller work areas by frost_window.
const appFirstWindowSizing = FrostWindowSizing(preferredSize: Size(1147, 717), minimumSize: Size(640, 480));

/// Whether the platform has a desktop window frost_window manages.
bool get hasDesktopWindow => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Creates the window controller and, on desktop, places the still hidden
/// native window where it was left (or at [appFirstWindowSizing]). A saved
/// placement that no longer fits a display comes back adjusted. Never throws:
/// whatever fails, the app still starts, in the runner's own window.
Future<FrostWindowController> prepareAppWindow({FrostWindowController? window}) async {
  window ??= FrostWindowController(minimumSize: appMinimumWindowSize);
  if (!hasDesktopWindow) return window;
  try {
    final placement = await window.prepare(saved: AppSettings.windowPlacement, sizing: appFirstWindowSizing);
    if (placement.adjustments.isNotEmpty) debugPrint('Window placement adjustments: ${placement.adjustments}');
  } catch (error, stack) {
    _report(error, stack, 'placing the window');
  }
  return window;
}

/// Shows the window after the first frame is on screen and keeps its
/// placement saved from then on. Never throws: a failure is reported and the
/// app keeps running.
Future<void> showAppWindow(WidgetsBinding binding, FrostWindowController window) async {
  if (!hasDesktopWindow) return;
  await binding.waitUntilFirstFrameRasterized;
  await revealAppWindow(window);
}

/// The part of [showAppWindow] after the first frame.
@visibleForTesting
Future<void> revealAppWindow(FrostWindowController window) async {
  try {
    await window.show();
  } catch (error, stack) {
    _report(error, stack, 'showing the window');
  }
  window.geometry.addListener(() => saveWindowGeometry(window.geometry.value));
}

void _report(Object error, StackTrace stack, String context) =>
    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'freepiv window', context: ErrorDescription(context)));

/// Saves [geometry]'s placement; the controller already debounces changes.
void saveWindowGeometry(FrostWindowGeometry? geometry) {
  if (geometry == null) return;
  AppSettings.windowPlacement = geometry.placement;
}
