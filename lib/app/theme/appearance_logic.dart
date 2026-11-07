import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appearance_logic.g.dart';

@immutable
class AppearanceState {
  const AppearanceState({required this.settings, this.unsaved = false, this.saving = false, this.saveError});
  final FrostAppearance settings;
  final bool unsaved;
  final bool saving;
  final String? saveError;

  AppearanceState copyWith({FrostAppearance? settings, bool? unsaved, bool? saving, String? saveError, bool clearError = false}) => AppearanceState(
    settings: settings ?? this.settings,
    unsaved: unsaved ?? this.unsaved,
    saving: saving ?? this.saving,
    saveError: clearError ? null : saveError ?? this.saveError,
  );
}

class _AppearanceWrite {
  _AppearanceWrite.immediate(this.settings) : brightness = null, customColor = null, result = null;
  _AppearanceWrite.custom(this.brightness, this.customColor, this.result) : settings = null;

  FrostAppearance? settings;
  final Brightness? brightness;
  final Color? customColor;
  final Completer<bool>? result;
  bool get isImmediate => settings != null;
}

@Riverpod(keepAlive: true)
class Appearance extends _$Appearance {
  final Queue<_AppearanceWrite> _writes = Queue<_AppearanceWrite>();
  Future<void>? _drainFuture;
  int _revision = 0;

  @override
  AppearanceState build() => AppearanceState(settings: AppSettings.appearance);

  void setMode(ThemeMode mode) {
    if (state.settings.mode == mode) return;
    _applyImmediate(state.settings.copyWith(mode: mode));
  }

  void setTone(Brightness brightness, FrostTone tone) {
    final settings = state.settings;
    if (settings.toneFor(brightness) == tone) return;
    _applyImmediate(brightness == Brightness.light ? settings.copyWith(lightTone: tone) : settings.copyWith(darkTone: tone));
  }

  void setPreset(Brightness brightness, Color accent) {
    _setAccent(brightness, accent);
  }

  void restoreDefault(Brightness brightness) => _setAccent(brightness, freepivFrostConfig.palettes.defaultAccent(brightness));

  void _setAccent(Brightness brightness, Color accent) {
    if (!validateAccent(accent, brightness, freepivFrostConfig.palettes).canApply) return;
    final settings = state.settings;
    if (settings.accentFor(brightness) == accent) return;
    _applyImmediate(brightness == Brightness.light ? settings.copyWith(lightAccent: accent) : settings.copyWith(darkAccent: accent));
  }

  void _applyImmediate(FrostAppearance next) {
    _revision++;
    state = state.copyWith(settings: next, unsaved: true, saving: true, clearError: true);
    if (_writes.isNotEmpty && _writes.last.isImmediate) {
      _writes.last.settings = next;
    } else {
      _writes.add(_AppearanceWrite.immediate(next));
    }
    _startDrain();
  }

  Future<bool> applyCustom(Brightness brightness, Color accent) async {
    if (!validateAccent(accent, brightness, freepivFrostConfig.palettes).canApply) return false;
    final result = Completer<bool>();
    _writes.add(_AppearanceWrite.custom(brightness, accent, result));
    state = state.copyWith(saving: true, clearError: true);
    _startDrain();
    return result.future;
  }

  Future<void> retrySave() async {
    if (!state.unsaved) return;
    final next = state.settings;
    if (_writes.isNotEmpty && _writes.last.isImmediate) {
      _writes.last.settings = next;
    } else {
      _writes.add(_AppearanceWrite.immediate(next));
    }
    state = state.copyWith(saving: true, clearError: true);
    _startDrain();
    await _drainFuture;
  }

  void _startDrain() {
    _drainFuture ??= _drain().whenComplete(() {
      _drainFuture = null;
      if (_writes.isNotEmpty) _startDrain();
    });
  }

  Future<void> _drain() async {
    while (_writes.isNotEmpty) {
      final write = _writes.removeFirst();
      if (write.isImmediate) {
        final snapshot = write.settings!;
        final startedAt = _revision;
        try {
          await AppSettings.saveAppearance(snapshot);
          if (state.settings == snapshot) {
            state = state.copyWith(unsaved: false, clearError: true);
          }
        } catch (_) {
          if (startedAt == _revision) {
            state = state.copyWith(unsaved: true, saveError: 'appearanceSaveFailed');
          }
        }
      } else {
        final brightness = write.brightness!;
        final accent = write.customColor!;
        final before = state.settings;
        final candidate = brightness == Brightness.light
            ? before.copyWith(lightAccent: accent, lightCustomAccent: accent)
            : before.copyWith(darkAccent: accent, darkCustomAccent: accent);
        final startedAt = _revision;
        try {
          await AppSettings.saveAppearance(candidate);
          final latest = state.settings;
          final applied = brightness == Brightness.light
              ? latest.copyWith(lightAccent: accent, lightCustomAccent: accent)
              : latest.copyWith(darkAccent: accent, darkCustomAccent: accent);
          _revision++;
          if (applied != candidate) {
            if (_writes.isNotEmpty && _writes.last.isImmediate) {
              _writes.last.settings = applied;
            } else {
              _writes.add(_AppearanceWrite.immediate(applied));
            }
          }
          state = state.copyWith(settings: applied, unsaved: applied != candidate, clearError: true);
          write.result!.complete(true);
        } catch (_) {
          if (startedAt == _revision) {
            state = state.copyWith(saveError: 'appearanceSaveFailed');
          }
          write.result!.complete(false);
        }
      }
      state = state.copyWith(saving: _writes.isNotEmpty);
    }
  }
}
