// The sample app with the Flutter Driver hooks the flutter-ui-automation
// tool needs (state, settle, appScreenshot, input). Debug builds only:
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

Future<Map<String, Object?>> _screenshot() async {
  await _frame();
  final view = WidgetsBinding.instance.renderViews.first;
  final ratio = view.flutterView.devicePixelRatio;
  final layer = view.debugLayer! as OffsetLayer;
  // The root layer already scales by the device ratio.
  final image = await layer.toImage(Offset.zero & (view.size * ratio));
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
        case 'appScreenshot':
          return jsonEncode(await _screenshot());
        case 'tapAt':
          final at = Offset(_num(request['x']).toDouble(), _num(request['y']).toDouble());
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: 9001, kind: PointerDeviceKind.mouse, device: 9, position: at));
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: 9001, kind: PointerDeviceKind.mouse, device: 9, position: at));
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
        default:
          throw UnsupportedError('${request['command']}');
      }
    },
  );
  // The profile image picker answers with a drawn picture instead of opening
  // the system's file dialog, so the cropper can be driven offline.
  profileImagePicker = () async => PickedProfileImage.bytes(await _testPicture());
  final present = FlutterError.presentError;
  FlutterError.presentError = (details) {
    _errors.add(details.exceptionAsString());
    present(details);
  };
  app.main();
}

final _errors = <String>[];

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
