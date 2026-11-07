import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app_links/app_links.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/features/settings/presentation/proxy_settings_dialog.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the sign-in stands.
enum LoginStage { idle, opening, waiting, exchanging, signedIn }

/// Pixiv sign-in, one task in the middle of the page:
/// the app, a line on how it works, "Sign in in the browser" and the proxy
/// settings. While the browser is out it waits with Reopen and Cancel; the
/// token exchange shows a bar; a failure shows why with its details. Tokens,
/// callback addresses and raw responses never show.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  AppLinkCallbackHandle? _callback;
  AppLinkCallbackHandle? _callbackError;
  final _handled = <String>{};
  UserAccountResult? _account;
  LoginStage _stage = LoginStage.idle;
  String? _error;
  String? _errorDetails;

  @override
  void initState() {
    super.initState();
    _callback = appLinkDispatcher.registerCallback(_handleAppLink);
    _callbackError = appLinkDispatcher.registerErrorCallback(_fail);
  }

  @override
  void dispose() {
    _callback?.dispose();
    _callbackError?.dispose();
    super.dispose();
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _stage = LoginStage.idle;
      _error = formatPixivError(error);
      _errorDetails = pixivErrorDetails(error);
    });
  }

  Future<void> _handleAppLink(AppLinkRequest request) async {
    if (request.route != AppLinkRoute.pixivAuthCallback || !mounted || _stage == LoginStage.exchanging) return;
    // The same callback can arrive twice (cold start and stream).
    if (!_handled.add(request.uri.toString())) return;
    final code = request.pixivAuthCode;
    if (code == null) {
      setState(() => _error = t.login.callbackMissingCode(uri: request.uri.scheme));
      return;
    }
    setState(() {
      _stage = LoginStage.exchanging;
      _error = null;
      _errorDetails = null;
    });
    try {
      final account = await pixivApi.initAccountAuthToken(code: code);
      if (!mounted) return;
      setPixivAccount(account);
      setState(() {
        _account = account;
        _stage = LoginStage.signedIn;
      });
    } catch (error) {
      _fail(error);
    }
  }

  Future<void> _open() async {
    if (!appServicesInitialized) {
      setState(() => _error = t.login.apiNotInitialized);
      return;
    }
    setState(() {
      _stage = LoginStage.opening;
      _error = null;
      _errorDetails = null;
    });
    try {
      await _openSystemBrowser(pixivApi.generateLoginUrl());
      if (mounted) setState(() => _stage = LoginStage.waiting);
    } catch (error) {
      _fail(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final account = _account ?? (appServicesInitialized ? pixivApi.account() : null);
    final proxy = ref.watch(proxySettingsProvider);
    final waiting = _stage == LoginStage.waiting;
    return FrostPinnedChrome(
      chrome: FrostContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        child: FrostPageHeader(title: FrostText(t.login.title)),
      ),
      body: FrostLoadingScrollView(
        slivers: [
          const FrostChromeSpacer(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: FrostContentColumn(
                maxWidth: FrostMetrics.readingMaxWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: FrostGap.section),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: FrostGap.group,
                    children: [
                      Image.asset('assets/icon-512.png', width: _iconExtent, height: _iconExtent, cacheWidth: 256, excludeFromSemantics: true),
                      FrostText('freepiv', role: FrostTextRole.title1, textAlign: TextAlign.center),
                      FrostText(
                        account == null ? t.loginPage.intro : t.login.signedInAs(name: account.user.name),
                        tone: FrostTextTone.secondary,
                        textAlign: TextAlign.center,
                      ),
                      if (waiting) ...[
                        FrostText(t.loginPage.waiting, role: FrostTextRole.headline, textAlign: TextAlign.center),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: FrostGap.related,
                          children: [
                            FrostButton.prominent(label: t.loginPage.reopen, onPressed: () => unawaited(_open())),
                            FrostButton(label: t.common.cancel, role: FrostButtonRole.cancel, onPressed: () => setState(() => _stage = LoginStage.idle)),
                          ],
                        ),
                      ] else
                        FrostButton.prominent(
                          label: account == null ? t.loginPage.signIn : t.login.signInAgain,
                          state: _stage == LoginStage.opening ? const FrostActionState.running() : FrostActionState.idle,
                          onPressed: _stage == LoginStage.exchanging || _stage == LoginStage.opening ? null : () => unawaited(_open()),
                        ),
                      if (_stage == LoginStage.exchanging) FrostActivityIndicator(semanticLabel: t.login.callbackReceived),
                      FrostButton.quiet(
                        label: proxy.active ? t.settings.proxy.entrySubtitleOn(url: proxy.url!) : t.settings.proxy.open,
                        onPressed: () => unawaited(showProxySettingsDialog(context)),
                      ),
                      if (_error case final error?) FrostInlineBanner(tone: FrostBannerTone.negative, message: error),
                      if (_errorDetails case final details?) FrostErrorDetails(details: details),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _iconExtent = 72.0;
}

Future<void> _openSystemBrowser(String url) async {
  if (Platform.isLinux) {
    final result = await Process.run('xdg-open', [url]);
    if (result.exitCode != 0) throw UnsupportedError(t.login.browserOpenUnsupported);
    return;
  }
  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) throw UnsupportedError(t.login.browserOpenUnsupported);
}
