import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/router/app_route.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/api/fanbox_login.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'login_logic.dart';
import 'login_platform.dart';

/// The largest session file read.
const fanboxSessionFileLimit = 64 * 1024;

/// Signs in to FANBOX, on the FANBOX page and in
/// Settings: one task in the middle of the content: what it does, Sign in with
/// the browser (Windows, Android, iOS; Windows without WebView2 offers the
/// Cookie instead), and the two ways without it, pasting the Cookie or
/// reading a session file of at most 64 KB.
class FanboxLoginPanel extends ConsumerStatefulWidget {
  const FanboxLoginPanel({this.onSignedIn, this.browserAvailable = fanboxBrowserAvailable, this.readSessionFile = _readSessionFile, super.key});

  final VoidCallback? onSignedIn;

  /// Whether WebView2 is there for the Windows browser sign-in.
  final Future<bool> Function() browserAvailable;

  /// Reads a chosen session file; null when none was chosen. A file over
  /// [fanboxSessionFileLimit] bytes throws a [FormatException].
  final Future<Uint8List?> Function() readSessionFile;

  static Future<Uint8List?> _readSessionFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
    if (result.isEmpty) return null;
    final file = result.single;
    // The size may be unknown; the bytes are checked again once read.
    final size = await file.length();
    if (size != null && size > fanboxSessionFileLimit) throw const FormatException();
    return file.readAsBytes();
  }

  @override
  ConsumerState<FanboxLoginPanel> createState() => _FanboxLoginPanelState();
}

class _FanboxLoginPanelState extends ConsumerState<FanboxLoginPanel> {
  late final FanboxWebLogin _login = ref.read(fanboxWebLoginProvider.notifier);
  bool _ownsLogin = false;

  @override
  void dispose() {
    if (_ownsLogin) Future.microtask(_login.cancel);
    super.dispose();
  }

  /// The Cookie pasted into a form; a wrong one keeps the form open.
  Future<void> _paste() async {
    final t = context.t.fanbox;
    // The form owns the draft and lets it go once it has left the screen.
    final draft = _CookieDraft();
    final success = await showFrostFormDialog(
      context: context,
      title: t.manualLogin,
      submitLabel: t.login,
      sections: [_CookieForm(draft: draft)],
      onSubmit: () async {
        final success = await ref.read(fanboxOperationProvider('login').notifier).run(() async {
          await ref.read(fanboxSessionProvider.notifier).signIn(draft.cookie.text, canCommit: () => mounted);
        });
        draft.error.value = success ? null : t.loginFailed;
        return success;
      },
    );
    if (success && mounted) widget.onSignedIn?.call();
  }

  /// A session file of at most [fanboxSessionFileLimit] bytes.
  Future<void> _import() async {
    var chosen = false;
    final success = await ref.read(fanboxOperationProvider('login').notifier).run(() async {
      final bytes = await widget.readSessionFile();
      if (bytes == null) return;
      chosen = true;
      if (bytes.length > fanboxSessionFileLimit || !mounted) throw const FormatException();
      await ref.read(fanboxSessionProvider.notifier).signIn(utf8.decode(bytes), canCommit: () => mounted);
    });
    if (success && chosen && mounted) widget.onSignedIn?.call();
  }

  Future<void> _browser() async {
    if (!_login.begin()) return;
    _ownsLogin = true;
    try {
      if (Platform.isWindows && !await _runtimeReady()) {
        _login.cancel();
        return;
      }
      if (!mounted) return;
      final success = Platform.isWindows ? await _login.runWindows() : await GoRouter.of(context).push<bool>(AppRoute.fanboxWebLogin.path);
      if (success == true && mounted) widget.onSignedIn?.call();
    } catch (error, stack) {
      _login.fail(error, stack);
    } finally {
      _login.finish();
      _ownsLogin = false;
    }
  }

  /// Whether WebView2 is there, asking to install it while it is not;
  /// choosing the Cookie instead opens that form.
  Future<bool> _runtimeReady() async {
    final t = context.t.fanbox;
    var missing = false;
    while (true) {
      bool available = false;
      try {
        available = await widget.browserAvailable();
      } catch (_) {
        // Shown as missing, with the same way to install it.
      }
      if (available) return true;
      if (!mounted) return false;
      final choice = await showFrostDialog<_RuntimeChoice>(
        context: context,
        builder: (context) => FrostDialog(
          title: t.runtimeTitle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostGap.related,
            children: [
              FrostText(t.runtimeMissing, tone: missing ? FrostTextTone.negative : FrostTextTone.primary),
              FrostText(t.runtimeHelp, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FrostButton.outlined(
                  label: t.runtimeInstall,
                  onPressed: () => unawaited(launchUrl(Uri.parse('https://developer.microsoft.com/en-us/microsoft-edge/webview2/'), mode: LaunchMode.externalApplication)),
                ),
              ),
            ],
          ),
          actions: [
            FrostDialogAction(label: t.manualLogin, value: _RuntimeChoice.manual),
            FrostDialogAction(label: t.runtimeRecheck, value: _RuntimeChoice.recheck, isDefault: true),
          ],
        ),
      );
      if (!mounted) return false;
      switch (choice) {
        case _RuntimeChoice.recheck:
          missing = true;
        case _RuntimeChoice.manual:
          unawaited(_paste());
          return false;
        case null:
          return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final stage = ref.watch(fanboxWebLoginProvider);
    final operation = ref.watch(fanboxOperationProvider('login'));
    final clearing = stage.value == FanboxLoginStage.clearing;
    final busy = clearing || stage.value == FanboxLoginStage.waiting || stage.value == FanboxLoginStage.checking || operation.isLoading;
    final error = switch ((stage.error, operation.error)) {
      (final error?, _) => fanboxLoginError(context.t, error),
      (_, final _?) => t.loginFailed,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: FrostGap.related,
      children: [
        FrostText(t.login, role: FrostTextRole.title2, textAlign: TextAlign.center),
        FrostText(t.browserHelp, tone: FrostTextTone.secondary, textAlign: TextAlign.center),
        const SizedBox(height: FrostGap.inline),
        if (supportsFanboxWebLogin)
          FrostButton.prominent(
            label: t.browserLogin,
            state: busy && !operation.isLoading ? const FrostActionState.running() : FrostActionState.idle,
            onPressed: busy ? null : () => unawaited(_browser()),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: FrostGap.related,
          children: [
            FrostButton.quiet(label: t.manualLogin, onPressed: busy ? null : () => unawaited(_paste())),
            FrostButton.quiet(
              label: t.importSession,
              state: operation.isLoading ? const FrostActionState.running() : FrostActionState.idle,
              onPressed: busy ? null : () => unawaited(_import()),
            ),
          ],
        ),
        if (busy && !operation.isLoading) FrostButton.quiet(label: t.cancel, onPressed: clearing ? null : _login.cancel),
        if (error != null) FrostText(error, role: FrostTextRole.footnote, tone: FrostTextTone.negative, textAlign: TextAlign.center),
      ],
    );
  }
}

enum _RuntimeChoice { recheck, manual }

/// The Cookie being typed and why the last one failed.
class _CookieDraft {
  final cookie = TextEditingController();
  final error = ValueNotifier<String?>(null);

  void dispose() {
    cookie
      ..clear()
      ..dispose();
    error.dispose();
  }
}

class _CookieForm extends StatefulWidget {
  const _CookieForm({required this.draft});

  final _CookieDraft draft;

  @override
  State<_CookieForm> createState() => _CookieFormState();
}

class _CookieFormState extends State<_CookieForm> {
  @override
  void dispose() {
    widget.draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    return ValueListenableBuilder(
      valueListenable: widget.draft.error,
      builder: (context, message, _) => FrostFormSection(
        children: [
          FrostText(t.loginHelp, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          FrostTextField.secure(controller: widget.draft.cookie, label: 'FANBOXSESSID', placeholder: t.cookieHint, error: message),
        ],
      ),
    );
  }
}
