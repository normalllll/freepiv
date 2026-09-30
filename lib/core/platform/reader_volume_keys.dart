import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One owner for Android's Activity volume-key channel. A lease prevents a
/// departing reader from disabling a newer reader's capture.
class ReaderVolumeKeys {
  ReaderVolumeKeys({MethodChannel? channel, bool? supported})
    : _channel = channel ?? const MethodChannel('freepiv/reader_volume_keys'),
      supported = supported ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    if (this.supported) _channel.setMethodCallHandler(_handleCall);
  }

  static final instance = ReaderVolumeKeys();
  final MethodChannel _channel;
  final bool supported;
  ReaderVolumeKeyLease? _owner;
  Future<void> _pending = Future<void>.value();

  ReaderVolumeKeyLease claim({required ValueChanged<int> onTurn, required VoidCallback onError, required ValueChanged<bool> onFocusChanged}) {
    _owner?._enabled = false;
    final lease = ReaderVolumeKeyLease._(this, onTurn, onError, onFocusChanged);
    _owner = lease;
    _schedule();
    return lease;
  }

  Future<void> _handleCall(MethodCall call) async {
    final owner = _owner;
    if (owner == null || owner._released) return;
    if (call.method == 'turn' && owner._enabled && (call.arguments == 1 || call.arguments == -1)) {
      owner._onTurn(call.arguments as int);
    } else if (call.method == 'focus' && call.arguments is bool) {
      owner._onFocusChanged(call.arguments as bool);
    }
  }

  void _schedule() {
    if (!supported) return;
    _pending = _pending.then((_) async {
      final owner = _owner;
      final enabled = owner != null && !owner._released && owner._enabled;
      try {
        await _channel.invokeMethod<void>('setEnabled', enabled);
      } catch (_) {
        if (owner != null && identical(owner, _owner) && !owner._released) {
          owner._enabled = false;
          owner._onError();
        }
        // Fail closed, including when a platform update failed after capture.
        try {
          await _channel.invokeMethod<void>('setEnabled', false);
        } catch (_) {}
      }
    });
  }
}

class ReaderVolumeKeyLease {
  ReaderVolumeKeyLease._(this._service, this._onTurn, this._onError, this._onFocusChanged);
  final ReaderVolumeKeys _service;
  final ValueChanged<int> _onTurn;
  final VoidCallback _onError;
  final ValueChanged<bool> _onFocusChanged;
  bool _enabled = false;
  bool _released = false;

  void setEnabled(bool enabled) {
    if (_released || (_enabled == enabled && (!enabled || identical(_service._owner, this)))) return;
    _enabled = enabled;
    if (enabled) _service._owner = this;
    if (identical(_service._owner, this)) _service._schedule();
  }

  void release() {
    if (_released) return;
    _released = true;
    _enabled = false;
    if (identical(_service._owner, this)) {
      _service._owner = null;
      _service._schedule();
    }
  }
}
