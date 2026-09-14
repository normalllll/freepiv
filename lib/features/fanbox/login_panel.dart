import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/interaction_controls.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'package:freepiv/src/rust/api/fanbox_login.dart';
import 'logic.dart';
import 'login_logic.dart';
import 'login_page.dart';
import 'login_platform.dart';

class FanboxLoginPanel extends ConsumerStatefulWidget {
  const FanboxLoginPanel({this.onSignedIn, super.key});
  final VoidCallback? onSignedIn;
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

  Future<void> _manual() async {
    final success = await showDialog<bool>(context: context, builder: (_) => const _FanboxCookieDialog());
    if (success == true && mounted) widget.onSignedIn?.call();
  }

  Future<void> _browser() async {
    if (!_login.begin()) return;
    _ownsLogin = true;
    try {
      if (Platform.isWindows && !await fanboxBrowserAvailable()) {
        if (!mounted) return;
        final choice = await showDialog<_RuntimeChoice>(context: context, builder: (_) => const _FanboxRuntimeDialog());
        if (!mounted) return;
        if (choice != _RuntimeChoice.ready) {
          _login.cancel();
          _ownsLogin = false;
          if (choice == _RuntimeChoice.manual) await _manual();
          return;
        }
      }
      if (!mounted) return;
      final success = Platform.isWindows
          ? await _login.runWindows()
          : await Navigator.of(context, rootNavigator: true).push<bool>(MaterialPageRoute(builder: (_) => const FanboxWebLoginPage(), fullscreenDialog: true));
      if (success == true && mounted) widget.onSignedIn?.call();
    } catch (error, stack) {
      _login.fail(error, stack);
    } finally {
      _login.finish();
      _ownsLogin = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final state = ref.watch(fanboxWebLoginProvider);
    final clearing = state.value == FanboxLoginStage.clearing;
    final busy = clearing || state.value == FanboxLoginStage.waiting || state.value == FanboxLoginStage.checking;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth > 568 ? (constraints.maxWidth - 520) / 2 : 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.article_outlined, size: 56),
            const SizedBox(height: 16),
            Text(t.login, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(t.browserHelp),
            const SizedBox(height: 24),
            if (supportsFanboxWebLogin) AppButton(label: t.browserLogin, kind: AppButtonKind.primary, loading: busy, onPressed: _browser),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: busy ? null : _manual, child: Text(t.manualLogin)),
            SizedBox(
              height: 48,
              child: busy ? TextButton(onPressed: clearing ? null : _login.cancel, child: Text(t.cancel)) : null,
            ),
            SizedBox(
              height: 80,
              child: state.hasError ? Text(fanboxLoginError(context.t, state.error!), style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
            ),
          ],
        ),
      ),
    );
  }
}

enum _RuntimeChoice { ready, manual }

class _FanboxRuntimeDialog extends StatefulWidget {
  const _FanboxRuntimeDialog();
  @override
  State<_FanboxRuntimeDialog> createState() => _FanboxRuntimeDialogState();
}

class _FanboxRuntimeDialogState extends State<_FanboxRuntimeDialog> {
  bool _checking = false;
  bool _failed = false;
  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    return AlertDialog(
      title: Text(t.runtimeTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.runtimeMissing),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.parse('https://developer.microsoft.com/en-us/microsoft-edge/webview2/'),
                  mode: LaunchMode.externalApplication,
                );
                if (mounted && !opened) setState(() => _failed = true);
              },
              child: Text(t.runtimeInstall),
            ),
            const SizedBox(height: 8),
            Text(t.runtimeHelp),
            SizedBox(
              height: 48,
              child: _checking
                  ? const Center(child: RefreshDots())
                  : _failed
                  ? Text(t.runtimeMissing)
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _RuntimeChoice.manual), child: Text(t.manualLogin)),
        TextButton(
          onPressed: _checking
              ? null
              : () async {
                  setState(() => _checking = true);
                  bool available = false;
                  try {
                    available = await fanboxBrowserAvailable();
                  } catch (_) {
                    /* Show the same actionable installation state. */
                  }
                  if (!context.mounted) return;
                  if (available) {
                    Navigator.pop(context, _RuntimeChoice.ready);
                  } else {
                    setState(() {
                      _checking = false;
                      _failed = true;
                    });
                  }
                },
          child: Text(t.runtimeRecheck),
        ),
      ],
    );
  }
}

class _FanboxCookieDialog extends ConsumerStatefulWidget {
  const _FanboxCookieDialog();
  @override
  ConsumerState<_FanboxCookieDialog> createState() => _FanboxCookieDialogState();
}

class _FanboxCookieDialogState extends ConsumerState<_FanboxCookieDialog> {
  final _cookie = TextEditingController();
  @override
  void dispose() {
    _cookie.clear();
    _cookie.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final success = await ref.read(fanboxOperationProvider('login').notifier).run(() async {
      await ref.read(fanboxSessionProvider.notifier).signIn(value, canCommit: () => mounted);
    });
    if (success && mounted) Navigator.pop(context, true);
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
    if (result.isEmpty || !mounted) return;
    final success = await ref.read(fanboxOperationProvider('login').notifier).run(() async {
      final file = result.single;
      if (await file.length() > 64 * 1024) throw const FormatException();
      final bytes = await file.readAsBytes();
      if (bytes.length > 64 * 1024 || !mounted) throw const FormatException();
      await ref.read(fanboxSessionProvider.notifier).signIn(utf8.decode(bytes), canCommit: () => mounted);
    });
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.fanbox;
    final operation = ref.watch(fanboxOperationProvider('login'));
    return AlertDialog(
      title: Text(t.manualLogin),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.loginHelp),
              const SizedBox(height: 16),
              TextField(
                controller: _cookie,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: 'FANBOXSESSID', hintText: t.cookieHint),
                onSubmitted: operation.isLoading ? null : _submit,
              ),
              const SizedBox(height: 16),
              AppButton(label: t.login, loading: operation.isLoading, kind: AppButtonKind.primary, onPressed: () => _submit(_cookie.text)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: operation.isLoading ? null : _import, child: Text(t.importSession)),
              SizedBox(
                height: 64,
                child: operation.hasError ? Text(t.loginFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)) : null,
              ),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel))],
    );
  }
}
