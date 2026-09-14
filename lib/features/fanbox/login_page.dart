import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/widgets/refresh_dots.dart';
import 'package:freepiv/src/rust/api/fanbox_login.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'login_logic.dart';
import 'login_platform.dart';

class FanboxWebLoginPage extends ConsumerStatefulWidget {
  const FanboxWebLoginPage({super.key});

  @override
  ConsumerState<FanboxWebLoginPage> createState() => _FanboxWebLoginPageState();
}

class _FanboxWebLoginPageState extends ConsumerState<FanboxWebLoginPage> {
  WebViewController? _web;
  Timer? _poll;
  Timer? _deadline;
  late final FanboxWebLogin _login;
  bool _closing = false;
  bool _canPop = false;
  bool _reading = false;
  bool _loading = true;
  bool _navigatingBack = false;
  bool _expired = false;
  String? _lastCandidate;
  Object? _pageError;

  @override
  void initState() {
    super.initState();
    _login = ref.read(fanboxWebLoginProvider.notifier);
    _deadline = Timer(const Duration(minutes: 15), () {
      if (mounted && !_closing) {
        _expired = true;
        _poll?.cancel();
        _login.fail(FanboxBrowserFailure.timedOut, StackTrace.current);
      }
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await fanboxLoginChannel.invokeMethod<void>('configure', ref.read(proxySettingsProvider).activeUrl).timeout(const Duration(seconds: 20));
      if (!mounted || _closing) return;
      final web = WebViewController();
      await web.setJavaScriptMode(JavaScriptMode.unrestricted);
      await web.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            return uri != null && uri.scheme == 'https' && uri.userInfo.isEmpty ? NavigationDecision.navigate : NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (mounted && !_closing) {
              setState(() {
                _loading = true;
                _pageError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted && !_closing) {
              setState(() => _loading = false);
              unawaited(_check());
            }
          },
          onWebResourceError: (error) {
            if (mounted && !_closing && error.isForMainFrame == true) {
              setState(() {
                _loading = false;
                _pageError = FanboxBrowserFailure.unavailable;
              });
            }
          },
        ),
      );
      if (!mounted || _closing) return;
      setState(() => _web = web);
      await web.loadRequest(Uri.parse('https://www.fanbox.cc/'));
      if (!mounted || _closing) return;
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_check()));
    } catch (error) {
      if (mounted && !_closing) {
        setState(() {
          _loading = false;
          _pageError = error;
        });
      }
    }
  }

  Future<void> _check({bool force = false}) async {
    if (_reading || _closing || _expired || _web == null) return;
    _reading = true;
    try {
      final session = await readFanboxLoginSession().timeout(const Duration(seconds: 10));
      if (!mounted || _closing) return;
      if (session == null) {
        if (force) _login.fail(FanboxBrowserFailure.unavailable, StackTrace.current);
        return;
      }
      if (!force && session == _lastCandidate) return;
      _lastCandidate = session;
      if (await _login.check(session) && mounted && !_closing) _close(true);
    } catch (error, stack) {
      if (mounted && !_closing) _login.fail(error, stack);
    } finally {
      _reading = false;
    }
  }

  Future<void> _back() async {
    if (_closing || _navigatingBack) return;
    _navigatingBack = true;
    try {
      final web = _web;
      if (web != null && await web.canGoBack()) {
        if (mounted && !_closing) await web.goBack();
      } else if (mounted) {
        _close(false);
      }
    } catch (_) {
      if (mounted) _close(false);
    } finally {
      _navigatingBack = false;
    }
  }

  void _close(bool success) {
    if (_closing) return;
    _closing = true;
    _poll?.cancel();
    _deadline?.cancel();
    if (!success) _login.cancel();
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(success);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _deadline?.cancel();
    // Provider cancellation is performed before pop, outside widget disposal.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fanboxWebLoginProvider);
    ref.listen(fanboxWebLoginProvider, (_, next) {
      if (next.value == FanboxLoginStage.idle && !_closing) _close(false);
    });
    final t = context.t.fanbox;
    final checking = state.value == FanboxLoginStage.checking;
    final error = _pageError ?? state.error;
    return PopScope<bool>(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.login),
          leading: BackButton(onPressed: _back),
          actions: [IconButton(tooltip: t.cancel, icon: const Icon(Icons.close), onPressed: () => _close(false))],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 32, child: _loading || checking ? const RefreshDots() : null),
                      Expanded(child: Text(error == null ? t.browserHelp : fanboxLoginError(context.t, error), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 136,
                        child: TextButton(
                          onPressed: checking || _closing || _expired
                              ? null
                              : () {
                                  if (_pageError != null) {
                                    setState(() => _pageError = null);
                                    if (_web == null) {
                                      unawaited(_initialize());
                                    } else {
                                      unawaited(_web!.reload());
                                    }
                                  } else {
                                    unawaited(_check(force: true));
                                  }
                                },
                          child: Text(_pageError == null ? t.browserCheck : t.retry),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: switch (_web) {
                  final web? => WebViewWidget(controller: web),
                  null => const SizedBox.expand(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
