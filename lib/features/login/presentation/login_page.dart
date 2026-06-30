import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app_links/app_links.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  UserAccountResult? _account;
  AppLinkCallbackHandle? _appLinkCallbackHandle;
  AppLinkCallbackHandle? _appLinkErrorCallbackHandle;
  final Set<String> _handledAuthCallbacks = <String>{};
  bool _isOpeningLogin = false;
  bool _isCompletingLogin = false;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _appLinkCallbackHandle = appLinkDispatcher.registerCallback(_handleAppLink);
    _appLinkErrorCallbackHandle = appLinkDispatcher.registerErrorCallback(_handleAppLinkError);
  }

  @override
  void dispose() {
    _appLinkCallbackHandle?.dispose();
    _appLinkErrorCallbackHandle?.dispose();
    super.dispose();
  }

  Future<void> _handleAppLink(AppLinkRequest request) async {
    switch (request.route) {
      case AppLinkRoute.pixivAuthCallback:
        await _handlePixivAuthCallback(request);
        return;
      case AppLinkRoute.unknown:
        return;
    }
  }

  void _handleAppLinkError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() => _error = formatPixivError(error));
  }

  Future<void> _openLogin() async {
    final translations = t;
    if (!appServicesInitialized) {
      setState(() => _error = translations.login.apiNotInitialized);
      return;
    }

    setState(() {
      _isOpeningLogin = true;
      _status = null;
      _error = null;
    });

    try {
      await _openSystemBrowser(pixivApi.generateLoginUrl());

      if (!mounted) {
        return;
      }
      setState(() {
        _status = translations.login.openedInBrowser;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = formatPixivError(error));
    } finally {
      if (mounted) {
        setState(() => _isOpeningLogin = false);
      }
    }
  }

  Future<void> _handlePixivAuthCallback(AppLinkRequest request) async {
    final rawUri = request.uri.toString();
    if (!_handledAuthCallbacks.add(rawUri)) {
      return;
    }

    final code = request.pixivAuthCode;
    if (code == null) {
      setState(() => _error = t.login.callbackMissingCode(uri: rawUri));
      return;
    }

    setState(() {
      _isCompletingLogin = true;
      _status = t.login.callbackReceived;
      _error = null;
    });

    try {
      final account = await pixivApi.initAccountAuthToken(code: code);
      setPixivAccount(account);

      if (!mounted) {
        return;
      }
      setState(() {
        _account = account;
        _isCompletingLogin = false;
        _status = t.login.signedInAs(name: account.user.name);
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCompletingLogin = false;
        _error = formatPixivError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = _account ?? (appServicesInitialized ? pixivApi.account() : null);
    final isBusy = _isOpeningLogin || _isCompletingLogin;
    final translations = t;
    final tokens = FreepivThemeTokens.of(context);
    final proxySettings = ref.watch(proxySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(translations.login.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: EnergeticCard(
              accentColor: tokens.brand,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.auto_awesome, color: tokens.brand, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    account == null ? translations.login.notSignedIn : translations.login.signedInAs(name: account.user.name),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _LoginProxyNotice(settings: proxySettings, onTap: () => showProxySettingsDialog(context)),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: isBusy ? null : _openLogin,
                    child: Text(
                      _isOpeningLogin
                          ? translations.login.openingBrowser
                          : account == null
                          ? translations.login.signInToPixiv
                          : translations.login.signInAgain,
                    ),
                  ),
                  if (_isCompletingLogin) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                  if (_status != null) ...[const SizedBox(height: 16), Text(_status!, textAlign: TextAlign.center)],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginProxyNotice extends StatelessWidget {
  const _LoginProxyNotice({required this.settings, required this.onTap});

  final AppProxySettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final proxyTranslations = translations.settings.proxy;
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final active = settings.active;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend((active ? tokens.brand : tokens.surfaceTint).withValues(alpha: active ? 0.08 : 0.34), tokens.surfaceRaised),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? tokens.brand.withValues(alpha: 0.20) : tokens.line.withValues(alpha: 0.52)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(active ? Icons.hub : Icons.hub_outlined, color: active ? tokens.brand : colorScheme.onSurfaceVariant, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    translations.login.proxyHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(onPressed: onTap, icon: const Icon(Icons.tune), label: Text(proxyTranslations.open)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openSystemBrowser(String url) async {
  if (Platform.isLinux) {
    final result = await Process.run('xdg-open', [url]);
    if (result.exitCode != 0) {
      throw UnsupportedError(t.login.browserOpenUnsupported);
    }
    return;
  }
  final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!launched) {
    throw UnsupportedError(t.login.browserOpenUnsupported);
  }
}
