import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/api/fanbox_login.dart';
import 'logic.dart';
import 'login_platform.dart';

part 'login_logic.g.dart';

enum FanboxLoginStage { idle, waiting, checking, clearing, succeeded }

@Riverpod(keepAlive: true)
class FanboxWebLogin extends _$FanboxWebLogin {
  int _generation = 0;
  bool _active = false;
  bool _checking = false;
  bool _clearing = false;
  FanboxBrowserLogin? _window;
  Future<String?>? _windowResult;

  @override
  AsyncValue<FanboxLoginStage> build() {
    ref.onDispose(() => _window?.cancel());
    ref.listen(proxySettingsProvider, (previous, next) {
      if (previous != next && _active) cancel();
    });
    return const AsyncData(FanboxLoginStage.idle);
  }

  bool begin() {
    if (_active || _clearing || _windowResult != null) return false;
    _generation++;
    _active = true;
    _checking = false;
    state = const AsyncData(FanboxLoginStage.waiting);
    return true;
  }

  void cancel() {
    _generation++;
    _active = false;
    _checking = false;
    _window?.cancel();
    if (ref.mounted) state = const AsyncData(FanboxLoginStage.idle);
  }

  void finish() {
    _generation++;
    _active = false;
    _checking = false;
    _window?.cancel();
    if (ref.mounted && !state.hasError && state.value != FanboxLoginStage.succeeded) {
      state = const AsyncData(FanboxLoginStage.idle);
    }
  }

  Future<void> cancelAndWait() async {
    cancel();
    try {
      await _windowResult;
    } catch (_) {
      /* Cancellation can race a native failure. */
    }
  }

  Future<void> clearBrowser(Future<void> Function() clearSession) async {
    _clearing = true;
    try {
      await cancelAndWait();
      if (ref.mounted) state = const AsyncData(FanboxLoginStage.clearing);
      await clearSession();
      await clearFanboxLoginData().timeout(const Duration(seconds: 30));
    } catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      rethrow;
    } finally {
      _clearing = false;
      if (ref.mounted && state.value == FanboxLoginStage.clearing) state = const AsyncData(FanboxLoginStage.idle);
    }
  }

  void fail(Object error, StackTrace stack) {
    if (ref.mounted && _active) state = AsyncError(error, stack);
  }

  Future<bool> check(String session) async {
    if (!_active || _checking) return false;
    final generation = _generation;
    _checking = true;
    state = const AsyncData(FanboxLoginStage.checking);
    try {
      final saved = await ref.read(fanboxSessionProvider.notifier).signIn(session, canCommit: () => ref.mounted && _active && generation == _generation);
      if (!saved || !ref.mounted || generation != _generation) return false;
      _active = false;
      state = const AsyncData(FanboxLoginStage.succeeded);
      return true;
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) state = AsyncError(error, stack);
      return false;
    } finally {
      if (generation == _generation) _checking = false;
    }
  }

  Future<bool> runWindows() async {
    final generation = _generation;
    try {
      final directory = await getApplicationSupportDirectory();
      if (!ref.mounted || !_active || generation != _generation) return false;
      final t = LocaleSettings.currentLocale.translations.fanbox;
      final window = FanboxBrowserLogin();
      _window = window;
      final result = window.run(
        supportDirectory: directory.path,
        proxy: ref.read(proxySettingsProvider).activeUrl,
        language: LocaleSettings.currentLocale.languageTag,
        title: t.login,
        checkLabel: t.browserCheck,
        cancelLabel: t.cancel,
        failedLabel: t.browserCheckFailed,
      );
      _windowResult = result;
      final session = await result;
      if (!ref.mounted || !_active || generation != _generation) return false;
      if (session == null) {
        cancel();
        return false;
      }
      return await check(session);
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        _active = false;
        state = AsyncError(error, stack);
      }
      return false;
    } finally {
      _window?.dispose();
      _window = null;
      _windowResult = null;
    }
  }
}

String fanboxLoginError(Translations t, Object error) => switch (error) {
  FanboxBrowserFailure.runtimeMissing => t.fanbox.runtimeMissing,
  FanboxBrowserFailure.proxyUnsupported => t.fanbox.browserProxyUnsupported,
  FanboxBrowserFailure.cleanupFailed => t.fanbox.browserCleanupFailed,
  FanboxBrowserFailure.timedOut => t.fanbox.browserTimedOut,
  FanboxBrowserFailure.busy => t.fanbox.browserBusy,
  FanboxBrowserFailure.unavailable => t.fanbox.browserUnavailable,
  PlatformException(code: 'proxyUnsupported') => t.fanbox.browserProxyUnsupported,
  PlatformException(code: 'cleanupFailed') => t.fanbox.browserCleanupFailed,
  _ => t.fanbox.loginFailed,
};
