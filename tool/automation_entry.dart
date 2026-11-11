// The sample app with the Flutter Driver hooks the flutter-ui-automation
// tool needs (state, settle, appScreenshot, prepareCapture, input). Debug builds only:
// flutter build windows --debug -t tool/automation_entry.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:frost_ui/frost_ui.dart' show FrostToast;

import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/account/account_actions.dart';
import 'package:freepiv/features/me/logic/profile_image_logic.dart';
import 'package:freepiv/dev/sample_data.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:freepiv/app/theme/appearance_logic.dart';
import 'package:freepiv/features/ranking/logic/ranking_logic.dart';
import 'package:freepiv/features/search/presentation/app_search.dart';
import 'sample_main.dart' as app;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart' show simulateKeyDownEvent, simulateKeyUpEvent;

final _user = DynamicLibrary.open('user32.dll');
final _alloc = DynamicLibrary.open('ole32.dll').lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('CoTaskMemAlloc');
final _enumWindows = _user
    .lookupFunction<
      Int32 Function(Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>, IntPtr),
      int Function(Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>, int)
    >('EnumWindows');
const _noMoveNoZOrderNoActivate = 0x0002 | 0x0004 | 0x0010;
final _setWindowPos = _user.lookupFunction<Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32), int Function(int, int, int, int, int, int, int)>(
  'SetWindowPos',
);
final _windowPid = _user.lookupFunction<Uint32 Function(IntPtr, Pointer<Uint32>), int Function(int, Pointer<Uint32>)>('GetWindowThreadProcessId');
final _className = _user.lookupFunction<Int32 Function(IntPtr, Pointer<Uint16>, Int32), int Function(int, Pointer<Uint16>, int)>('GetClassNameW');
final _foreground = _user.lookupFunction<IntPtr Function(), int Function()>('GetForegroundWindow');
final _id = _alloc(4).cast<Uint32>();
final _name = _alloc(512).cast<Uint16>();
int _hwnd = 0;

int _visit(int handle, int _) {
  _windowPid(handle, _id);
  if (_id.value != pid) return 1;
  final length = _className(handle, _name, 256);
  final name = String.fromCharCodes(_name.asTypedList(length));
  if (name != 'FLUTTER_RUNNER_WIN32_WINDOW') return 1;
  _hwnd = handle;
  return 0;
}

int _window() {
  if (_hwnd != 0) return _hwnd;
  _enumWindows(Pointer.fromFunction<Int32 Function(IntPtr, IntPtr)>(_visit, 1), 0);
  return _hwnd;
}

bool _mouseAdded = false;
Offset _heldAt = Offset.zero;

Map<String, Object?> _state() => {
  'native': {'pid': pid, 'hwnd': _window(), 'isForeground': _foreground() == _window()},
};

Future<void> _frame() async {
  WidgetsBinding.instance.scheduleForcedFrame();
  await WidgetsBinding.instance.endOfFrame.timeout(const Duration(seconds: 3));
}

/// Pumps frames until no animation is running, at most [timeout].
Future<Map<String, Object?>> _settle(Duration timeout) async {
  final binding = WidgetsBinding.instance;
  final clock = Stopwatch()..start();
  var frames = 0;
  do {
    await _frame();
    frames++;
  } while (binding.transientCallbackCount > 0 && clock.elapsed < timeout);
  return {
    'settled': binding.transientCallbackCount == 0,
    'settleFrames': frames,
    'settleMs': clock.elapsedMilliseconds,
    'pendingTransientCallbacks': binding.transientCallbackCount,
  };
}

// The app's own pixels, which app screenshots read; the presentation marker
// paints above this boundary, so it reaches native captures only.
final _appBoundary = GlobalKey();
final _markerBits = GlobalKey();

/// The marker's token, and whether a native capture holds it on screen.
final _marker = ValueNotifier((token: 0, shown: false));

/// Open holds by ID, each until its expiry: concurrent captures release
/// their own, and a lost controller cannot leave the marker up.
final _holds = <int, DateTime>{};
var _holdSequence = 0;
Timer? _markerExpiry;

void _scheduleMarkerExpiry() {
  _markerExpiry?.cancel();
  _marker.value = (token: _marker.value.token, shown: _holds.isNotEmpty);
  if (_holds.isEmpty) return;
  final next = _holds.values.reduce((a, b) => a.isBefore(b) ? a : b);
  _markerExpiry = Timer(next.difference(DateTime.now()), () {
    final now = DateTime.now();
    _holds.removeWhere((_, until) => !until.isAfter(now));
    _scheduleMarkerExpiry();
  });
}

Map<String, double>? _rect(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final offset = box.localToGlobal(Offset.zero);
  return {'x': offset.dx, 'y': offset.dy, 'width': box.size.width, 'height': box.size.height};
}

/// The app inside the screenshot boundary, with the marker above it.
Widget _captureHost(Widget app) => Directionality(
  textDirection: TextDirection.ltr,
  child: Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(key: _appBoundary, child: app),
      ValueListenableBuilder(
        valueListenable: _marker,
        builder: (context, marker, _) => marker.shown
            ? Positioned(
                right: 8,
                top: 8,
                child: IgnorePointer(
                  child: _PresentationMarker(bitsKey: _markerBits, token: marker.token),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  ),
);

/// The flutter-ui-automation presentation marker: an 8×4 dot matrix reading
/// row-major 1010, the 24-bit token, 0101, pink for 1 and aqua for 0. Its
/// colours and geometry must match the tool's decoders.
class _PresentationMarker extends StatelessWidget {
  const _PresentationMarker({required this.bitsKey, required this.token});

  final Key bitsKey;
  final int token;

  static const _one = Color(0xFFFF8FB1), _zero = Color(0xFF38BDD8);
  static const _columns = 8, _rows = 4;
  static const _pitch = 9.0, _dot = 7.0;

  Color _cell(int index) => (0xa << 28 | token << 4 | 0x5) >> (31 - index) & 1 == 1 ? _one : _zero;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x59FF8FB1)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: SizedBox(
        key: bitsKey,
        width: _columns * _pitch,
        height: _rows * _pitch,
        child: Column(
          children: [
            for (var row = 0; row < _rows; row++)
              Row(
                children: [
                  for (var column = 0; column < _columns; column++)
                    SizedBox.square(
                      dimension: _pitch,
                      child: Padding(
                        padding: const EdgeInsets.all((_pitch - _dot) / 2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: _cell(row * _columns + column), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

Future<Map<String, Object?>> _screenshot() async {
  await _frame();
  final ratio = WidgetsBinding.instance.renderViews.first.flutterView.devicePixelRatio;
  final boundary = _appBoundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: ratio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return {'png': base64Encode(bytes!.buffer.asUint8List()), 'width': image.width, 'height': image.height, 'pixelRatio': ratio};
  } finally {
    image.dispose();
  }
}

const _keys = {
  'Tab': LogicalKeyboardKey.tab,
  'Escape': LogicalKeyboardKey.escape,
  'Enter': LogicalKeyboardKey.enter,
  'ArrowDown': LogicalKeyboardKey.arrowDown,
  'ArrowUp': LogicalKeyboardKey.arrowUp,
};

void main() {
  enableFlutterDriverExtension(
    enableTextEntryEmulation: false,
    handler: (message) async {
      final request = jsonDecode(message!) as Map<String, Object?>;
      switch (request['command']) {
        case 'state':
          return jsonEncode(_state());
        case 'refresh':
        case 'settle':
          await _frame();
          return jsonEncode({'refreshed': true});
        case 'prepareCapture':
          // A fresh token painted above the app: the native capture accepts
          // only frames that show it, so blank or stale frames are rejected.
          final settle = request['settle'] == false || request['settle'] == 'false'
              ? null
              : await _settle(Duration(milliseconds: _num(request['settleMs'] ?? 3000).toInt()));
          final visibleUntil = DateTime.now().add(Duration(milliseconds: _num(request['holdMs'] ?? 12000).toInt()));
          final hold = ++_holdSequence;
          _holds[hold] = visibleUntil;
          _marker.value = (token: (_marker.value.token + 1) & 0xffffff, shown: true);
          _scheduleMarkerExpiry();
          await _frame();
          return jsonEncode({
            ...?settle,
            'token': _marker.value.token,
            'hold': hold,
            'visibleUntilMs': visibleUntil.millisecondsSinceEpoch,
            'rect': _rect(_markerBits),
            'pixelRatio': WidgetsBinding.instance.renderViews.first.flutterView.devicePixelRatio,
            'native': _state()['native'],
          });
        case 'releaseCapture':
          final hold = _num(request['hold']).toInt();
          _holds.remove(hold);
          _scheduleMarkerExpiry();
          await _frame();
          return jsonEncode({'released': hold, 'probeVisible': _holds.isNotEmpty});
        case 'unfocus':
          FocusManager.instance.primaryFocus?.unfocus();
          await _frame();
          return jsonEncode(_state());
        case 'appScreenshot':
          return jsonEncode(await _screenshot());
        case 'tapAt':
          final at = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: 9001, kind: PointerDeviceKind.mouse, device: 9, position: at));
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 9001, kind: PointerDeviceKind.mouse, device: 9, position: at));
          await _frame();
          return jsonEncode(_state());
        case 'secondaryTapAt':
          // A right click, which opens a context menu.
          final at = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          GestureBinding.instance.handlePointerEvent(
            PointerDownEvent(pointer: 9004, kind: PointerDeviceKind.mouse, device: 9, position: at, buttons: kSecondaryMouseButton),
          );
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 9004, kind: PointerDeviceKind.mouse, device: 9, position: at));
          await _frame();
          return jsonEncode(_state());
        case 'hoverAt':
          final at = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          if (!_mouseAdded) {
            _mouseAdded = true;
            GestureBinding.instance.handlePointerEvent(PointerAddedEvent(kind: PointerDeviceKind.mouse, device: 9, position: at));
          }
          GestureBinding.instance.handlePointerEvent(PointerHoverEvent(kind: PointerDeviceKind.mouse, device: 9, position: at));
          await _frame();
          return jsonEncode(_state());
        case 'key':
          final key = _keys[request['key']]!;
          await simulateKeyDownEvent(key);
          await simulateKeyUpEvent(key);
          await _frame();
          return jsonEncode(_state());
        case 'errors':
          return jsonEncode(_errors);
        case 'toast':
          FrostToast.info(request['text']! as String);
          await _frame();
          return jsonEncode(_state());
        case 'mouseDrag':
          final from = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          final by = Offset(_num(request['dx']).toDouble(), _num(request['dy']).toDouble());
          const steps = 12;
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: 9002, kind: PointerDeviceKind.mouse, device: 9, position: from));
          for (var i = 1; i <= steps; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
            GestureBinding.instance.handlePointerEvent(
              PointerMoveEvent(pointer: 9002, kind: PointerDeviceKind.mouse, device: 9, position: from + by * (i / steps), delta: by / steps.toDouble()),
            );
          }
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 9002, kind: PointerDeviceKind.mouse, device: 9, position: from + by));
          await _frame();
          return jsonEncode(_state());
        case 'pointerDown':
          // Presses and holds the mouse (see pointerMove and pointerUp), for what shows only while held.
          final at = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: 9003, kind: PointerDeviceKind.mouse, device: 9, position: at));
          _heldAt = at;
          await _frame();
          return jsonEncode(_state());
        case 'pointerMove':
          final to = _heldAt + Offset(_num(request['dx']).toDouble(), _num(request['dy']).toDouble());
          GestureBinding.instance.handlePointerEvent(
            PointerMoveEvent(pointer: 9003, kind: PointerDeviceKind.mouse, device: 9, position: to, delta: to - _heldAt),
          );
          _heldAt = to;
          await _frame();
          return jsonEncode(_state());
        case 'pointerUp':
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 9003, kind: PointerDeviceKind.mouse, device: 9, position: _heldAt));
          await _frame();
          return jsonEncode(_state());
        case 'go':
          // Opens a location as the app would: a push over the current page.
          unawaited(AppRouter.router.push(request['location']! as String));
          await _frame();
          return jsonEncode(_state());
        case 'signedOut':
          // The sign-in page as a signed-out user sees it, and back.
          if (request['value'] == 'true') {
            AppSettings.accounts = AppSettings.accounts.deactivated();
            pixivAccountNotifier.value = null;
          } else {
            await signInPixivAccount(sampleAccount);
          }
          AppRouter.router.go(request['value'] == 'true' ? '/login' : '/');
          await _frame();
          return jsonEncode(_state());
        case 'switchAccount':
          // Switches to the stored account with this ID, as the account menu does.
          await switchToAccount(AppRouter.rootNavigatorKey.currentContext!, request['value']! as String);
          await _frame();
          return jsonEncode(_state());
        case 'destination':
          // A destination's root page, as its navigation item opens it.
          AppRouter.router.go(request['location']! as String);
          await _frame();
          return jsonEncode(_state());
        case 'search':
          // The title-bar search, focused with [text] typed (empty for the compact discover).
          final session = ProviderScope.containerOf(_appContext()).read(appSearchSessionProvider);
          final text = request['text'] as String? ?? '';
          session.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          session.focusNode.requestFocus();
          await _frame();
          return jsonEncode(_state());
        case 'theme':
          // Light or dark, as the appearance setting would set it.
          ProviderScope.containerOf(_appContext()).read(appearanceProvider.notifier).setMode(request['value'] == 'dark' ? ThemeMode.dark : ThemeMode.light);
          await _frame();
          return jsonEncode(_state());
        case 'rankingDate':
          // The day the rankings are of, as YYYY-MM-DD; empty for the latest.
          final day = request['value'] as String? ?? '';
          ProviderScope.containerOf(_appContext()).read(rankingProvider.notifier).setDate(day.isEmpty ? null : DateTime.parse(day));
          await _frame();
          return jsonEncode(_state());
        case 'home':
          AppRouter.router.go('/');
          await _frame();
          return jsonEncode(_state());
        case 'resize':
          final ratio = WidgetsBinding.instance.renderViews.first.flutterView.devicePixelRatio;
          _setWindowPos(_window(), 0, 0, 0, (_num(request['width']) * ratio).round(), (_num(request['height']) * ratio).round(), _noMoveNoZOrderNoActivate);
          await _frame();
          return jsonEncode(_state());
        case 'profileImageReadDelay':
          // How long reading the picked profile image takes, in milliseconds,
          // as a large file on a slow disk would, so the wait can be seen.
          _profileImageReadDelay = Duration(milliseconds: _num(request['value'] ?? 0).toInt());
          return jsonEncode(_state());
        default:
          throw UnsupportedError('${request['command']}');
      }
    },
  );
  // The profile image picker answers with a drawn picture instead of opening
  // the system's file dialog, so the cropper can be driven offline.
  profileImagePicker = () async {
    final picture = await _testPicture();
    return PickedProfileImage(
      size: picture.length,
      read: () async {
        await Future<void>.delayed(_profileImageReadDelay);
        return picture;
      },
    );
  };
  final present = FlutterError.presentError;
  FlutterError.presentError = (details) {
    _errors.add(details.exceptionAsString());
    present(details);
  };
  app.runSampleApp(wrap: _captureHost);
}

final _errors = <String>[];

/// Set by the profileImageReadDelay hook.
var _profileImageReadDelay = Duration.zero;

/// A 1200x800 PNG: a sky gradient, a sun and hills, with a grid that makes
/// panning and zooming easy to see.
Future<Uint8List> _testPicture() async {
  const width = 1200.0, height = 800.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(0, height), const [Color(0xFF7FB6F5), Color(0xFFF7C9D4)]),
  );
  final grid = Paint()
    ..color = const Color(0x33FFFFFF)
    ..strokeWidth = 2;
  for (var x = 0.0; x <= width; x += 100) {
    canvas.drawLine(Offset(x, 0), Offset(x, height), grid);
  }
  for (var y = 0.0; y <= height; y += 100) {
    canvas.drawLine(Offset(0, y), Offset(width, y), grid);
  }
  canvas.drawCircle(const Offset(800, 300), 150, Paint()..color = const Color(0xFFFFE08A));
  canvas.drawCircle(const Offset(300, 640), 340, Paint()..color = const Color(0xFF4E8F6A));
  canvas.drawCircle(const Offset(900, 760), 300, Paint()..color = const Color(0xFF356C54));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  try {
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// A context inside the app's provider scope.
BuildContext _appContext() => AppRouter.rootNavigatorKey.currentContext!;

// The automation tool passes request arguments as strings.
num _num(Object? value) => value is num ? value : num.parse('$value');
