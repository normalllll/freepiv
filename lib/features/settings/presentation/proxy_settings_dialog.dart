import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/api/proxy.dart' as system_proxy;
import 'package:frost_ui/frost_ui.dart';

/// Asks the system for its proxy; tests answer it themselves.
@visibleForTesting
Future<String?> Function() systemProxyLookup = system_proxy.getSystemProxy;

/// The proxy form: on or off, protocol, host and port,
/// and on desktop the system's proxy. A wrong host or port keeps the form
/// open with the reason; other settings never wait on it.
Future<void> showProxySettingsDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final draft = _ProxyDraft(container.read(proxySettingsProvider));
  try {
    await showFrostFormDialog(
      context: context,
      title: context.t.settings.proxy.title,
      submitLabel: context.t.settings.proxy.save,
      sections: [_ProxyForm(draft: draft)],
      onSubmit: () {
        final settings = draft.validate();
        if (settings == null) return false;
        try {
          container.read(proxySettingsProvider.notifier).setProxySettings(settings);
          FrostToast.success(t.settings.proxy.saved);
          return true;
        } catch (error) {
          toastErrorWithCause(t.settings.proxy.saveFailed, error);
          return false;
        }
      },
    );
  } finally {
    draft.dispose();
  }
}

class _ProxyDraft extends ChangeNotifier {
  _ProxyDraft(AppProxySettings settings)
    : enabled = settings.enabled,
      protocol = settings.url == null ? AppProxyProtocol.http : proxyProtocolFromUrl(settings.url!),
      host = TextEditingController(text: settings.url == null ? '' : proxyHostFromUrl(settings.url!)),
      port = TextEditingController(text: settings.url == null ? '' : proxyPortFromUrl(settings.url!));

  bool enabled;
  AppProxyProtocol protocol;
  final TextEditingController host;
  final TextEditingController port;
  String? hostError;
  String? portError;
  bool loadingSystem = false;

  /// The dialog closed; a lookup still running drops its answer.
  bool _disposed = false;

  void change(void Function() update) {
    update();
    hostError = null;
    portError = null;
    notifyListeners();
  }

  /// The settings to save, or null after marking what is wrong.
  AppProxySettings? validate() {
    final labels = t.settings.proxy;
    final rawHost = host.text.trim();
    final rawPort = port.text.trim();
    if (!enabled && rawHost.isEmpty && rawPort.isEmpty) return const AppProxySettings(enabled: false);
    hostError = rawHost.isEmpty ? labels.hostRequired : (isValidProxyHostInput(rawHost) ? null : labels.invalidHost);
    portError = rawPort.isEmpty ? labels.portRequired : (isValidProxyPortInput(rawPort) ? null : labels.invalidPort);
    final url = hostError == null && portError == null ? normalizeProxyEndpoint(host: rawHost, port: rawPort, protocol: protocol) : null;
    if (url == null && hostError == null && portError == null) {
      hostError = labels.invalid;
      portError = labels.invalid;
    }
    notifyListeners();
    return url == null ? null : AppProxySettings(enabled: enabled, url: url);
  }

  Future<void> loadSystem() async {
    final labels = t.settings.proxy;
    loadingSystem = true;
    notifyListeners();
    try {
      final proxy = await systemProxyLookup();
      if (_disposed) return;
      final normalized = proxy == null ? null : normalizeProxyUrl(proxy);
      if (normalized == null) {
        FrostToast.warning(labels.systemNotFound);
        return;
      }
      change(() {
        host.text = proxyHostFromUrl(normalized);
        port.text = proxyPortFromUrl(normalized);
        enabled = true;
        protocol = proxyProtocolFromUrl(normalized);
      });
      FrostToast.success(labels.systemLoaded);
    } catch (error) {
      if (!_disposed) toastErrorWithCause(labels.systemLoadFailed, error);
    } finally {
      if (!_disposed) {
        loadingSystem = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    host.dispose();
    port.dispose();
    super.dispose();
  }
}

class _ProxyForm extends StatelessWidget {
  const _ProxyForm({required this.draft});

  final _ProxyDraft draft;

  @override
  Widget build(BuildContext context) {
    final labels = context.t.settings.proxy;
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => FrostFormSection(
        children: [
          FrostText(labels.helper, role: FrostTextRole.footnote, tone: FrostTextTone.secondary),
          FrostListRow.toggle(title: labels.enabled, value: draft.enabled, onChanged: (value) => draft.change(() => draft.enabled = value)),
          FrostFormRow(
            label: FrostText(labels.protocol),
            control: FrostPicker<AppProxyProtocol>.segmented(
              label: labels.protocol,
              value: draft.protocol,
              options: [
                FrostPickerOption(value: AppProxyProtocol.http, label: labels.protocolHttp),
                FrostPickerOption(value: AppProxyProtocol.socks, label: labels.protocolSocks),
              ],
              onChanged: (value) => draft.change(() => draft.protocol = value),
            ),
          ),
          FrostTextField(
            controller: draft.host,
            label: labels.address,
            placeholder: labels.addressHint,
            error: draft.hostError,
            onChanged: (_) => draft.change(() {}),
          ),
          FrostTextField(
            controller: draft.port,
            label: labels.port,
            placeholder: labels.portHint,
            error: draft.portError,
            keyboardType: TextInputType.number,
            onChanged: (_) => draft.change(() {}),
          ),
          if (isDesktopPlatform)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FrostButton.quiet(
                label: labels.loadSystem,
                state: draft.loadingSystem ? const FrostActionState.running() : FrostActionState.idle,
                onPressed: draft.loadingSystem ? null : () => unawaited(draft.loadSystem()),
              ),
            ),
        ],
      ),
    );
  }
}
