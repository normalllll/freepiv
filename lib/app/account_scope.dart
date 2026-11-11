import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:freepiv/app/router/app_router.dart';
import 'package:freepiv/core/services/pixiv_service.dart';

/// The app's provider scope, keyed by the current account's ID: switching
/// accounts, signing in and signing out build a new scope, so nothing cached
/// for one account is shown for another. Only what is created outside
/// (settings, downloads, the image cache, the window) carries over.
///
/// It also writes the client's refreshed session back to the stored account
/// when the app goes to the background or exits.
class AccountScope extends StatefulWidget {
  const AccountScope({required this.builder, this.overrides = const [], super.key});

  final List<Override> overrides;

  /// Builds what the scope holds for the account with this ID (null signed
  /// out). It should key what it builds by the ID: an element kept alive by a
  /// GlobalKey somewhere below (slang's TranslationProvider, Frost's toast host)
  /// is taken back by the next scope with its whole subtree, and only a new key
  /// above it keeps that subtree from being updated in place.
  final Widget Function(BuildContext context, String? accountId) builder;

  @override
  State<AccountScope> createState() => _AccountScopeState();
}

class _AccountScopeState extends State<AccountScope> with WidgetsBindingObserver {
  String? _accountId = pixivAccountNotifier.value?.user.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pixivAccountNotifier.addListener(_accountChanged);
  }

  @override
  void dispose() {
    pixivAccountNotifier.removeListener(_accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _accountChanged() {
    final id = pixivAccountNotifier.value?.user.id;
    if (id == _accountId) return;
    // A new router with new navigator keys is ready before the scope mounts.
    AppRouter.replace();
    setState(() => _accountId = id);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) persistPixivSession();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_accountId),
    overrides: widget.overrides,
    child: Builder(builder: (context) => widget.builder(context, _accountId)),
  );
}
