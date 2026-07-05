import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/core.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/api/proxy.dart' as system_proxy;

Future<void> showProxySettingsDialog(BuildContext context) {
  return showDialog<void>(context: context, builder: (context) => const ProxySettingsDialog());
}

class ProxySettingsDialog extends ConsumerStatefulWidget {
  const ProxySettingsDialog({super.key});

  @override
  ConsumerState<ProxySettingsDialog> createState() => _ProxySettingsDialogState();
}

class _ProxySettingsDialogState extends ConsumerState<ProxySettingsDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late bool _enabled;
  late AppProxyProtocol _protocol;
  bool _isFetchingSystemProxy = false;
  String? _hostErrorText;
  String? _portErrorText;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(proxySettingsProvider);
    final url = settings.url;
    _enabled = settings.enabled;
    _protocol = url == null ? AppProxyProtocol.http : proxyProtocolFromUrl(url);
    _hostController = TextEditingController(text: url == null ? '' : proxyHostFromUrl(url));
    _portController = TextEditingController(text: url == null ? '' : proxyPortFromUrl(url));
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final proxyTranslations = translations.settings.proxy;
    final tokens = FreepivThemeTokens.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.viewInsets.bottom - media.padding.vertical - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight.clamp(360.0, double.infinity).toDouble()),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.line.withValues(alpha: 0.42)),
              boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 34, offset: const Offset(0, 18))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderIcon(tokens: tokens),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(proxyTranslations.title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(proxyTranslations.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProxyPowerTile(
                      enabled: _enabled,
                      onChanged: (enabled) {
                        setState(() {
                          _enabled = enabled;
                          _clearErrors();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _ProxyProtocolSelector(
                      protocol: _protocol,
                      enabled: _enabled,
                      onChanged: (protocol) {
                        setState(() {
                          _protocol = protocol;
                          _clearErrors();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProxyEndpointFields(
                      hostController: _hostController,
                      portController: _portController,
                      enabled: _enabled,
                      hostErrorText: _hostErrorText,
                      portErrorText: _portErrorText,
                      onChanged: (_) {
                        if (_hostErrorText != null || _portErrorText != null) {
                          setState(_clearErrors);
                        }
                      },
                    ),
                    if (isDesktopPlatform) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: _isFetchingSystemProxy ? null : _loadSystemProxy,
                          icon: _isFetchingSystemProxy
                              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.travel_explore_outlined),
                          label: Text(proxyTranslations.loadSystem),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(translations.common.cancel)),
                        const SizedBox(width: 8),
                        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: Text(proxyTranslations.save)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadSystemProxy() async {
    final translations = t.settings.proxy;

    if (!isDesktopPlatform) {
      AppToast.warning(translations.systemUnsupported);
      return;
    }

    setState(() {
      _isFetchingSystemProxy = true;
      _clearErrors();
    });

    try {
      final proxy = await system_proxy.getSystemProxy();
      if (!mounted) {
        return;
      }

      final normalizedProxy = proxy == null ? null : normalizeProxyUrl(proxy);
      if (normalizedProxy == null) {
        AppToast.warning(translations.systemNotFound);
        return;
      }

      final host = proxyHostFromUrl(normalizedProxy);
      final port = proxyPortFromUrl(normalizedProxy);
      _hostController
        ..text = host
        ..selection = TextSelection.collapsed(offset: host.length);
      _portController
        ..text = port
        ..selection = TextSelection.collapsed(offset: port.length);
      setState(() {
        _enabled = true;
        _protocol = proxyProtocolFromUrl(normalizedProxy);
        _clearErrors();
      });
      AppToast.success(translations.systemLoaded);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.errorWithCause(translations.systemLoadFailed, error);
    } finally {
      if (mounted) {
        setState(() => _isFetchingSystemProxy = false);
      }
    }
  }

  void _save() {
    final translations = t.settings.proxy;
    final rawHost = _hostController.text.trim();
    final rawPort = _portController.text.trim();
    final hasProxyInput = rawHost.isNotEmpty || rawPort.isNotEmpty;
    String? normalizedUrl;
    String? hostErrorText;
    String? portErrorText;

    if (_enabled || hasProxyInput) {
      if (rawHost.isEmpty) {
        hostErrorText = translations.hostRequired;
      } else if (!isValidProxyHostInput(rawHost)) {
        hostErrorText = translations.invalidHost;
      }

      if (rawPort.isEmpty) {
        portErrorText = translations.portRequired;
      } else if (!isValidProxyPortInput(rawPort)) {
        portErrorText = translations.invalidPort;
      }

      if (hostErrorText != null || portErrorText != null) {
        setState(() {
          _hostErrorText = hostErrorText;
          _portErrorText = portErrorText;
        });
        return;
      }

      normalizedUrl = normalizeProxyEndpoint(host: rawHost, port: rawPort, protocol: _protocol);
      if (normalizedUrl == null) {
        setState(() {
          _hostErrorText = translations.invalid;
          _portErrorText = translations.invalid;
        });
        return;
      }
    }

    ref.read(proxySettingsProvider.notifier).setProxySettings(AppProxySettings(enabled: _enabled, url: normalizedUrl));
    AppToast.success(translations.saved);
    Navigator.of(context).pop();
  }

  void _clearErrors() {
    _hostErrorText = null;
    _portErrorText = null;
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.tokens});

  final FreepivThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(tokens.brand.withValues(alpha: 0.16), tokens.surfaceRaised),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.brand.withValues(alpha: 0.24)),
      ),
      child: SizedBox.square(dimension: 44, child: Icon(Icons.hub_outlined, color: tokens.brand)),
    );
  }
}

class _ProxyPowerTile extends StatelessWidget {
  const _ProxyPowerTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!enabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: enabled ? Color.alphaBlend(tokens.brand.withValues(alpha: 0.10), tokens.surfaceRaised) : tokens.surfaceMuted.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: enabled ? tokens.brand.withValues(alpha: 0.34) : tokens.line.withValues(alpha: 0.54)),
          ),
          child: Row(
            children: [
              Icon(enabled ? Icons.power_settings_new : Icons.power_off_outlined, color: enabled ? tokens.brand : colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translations.enabled, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? translations.enabledStatus : translations.disabledStatus,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProxyProtocolSelector extends StatelessWidget {
  const _ProxyProtocolSelector({required this.protocol, required this.enabled, required this.onChanged});

  final AppProxyProtocol protocol;
  final bool enabled;
  final ValueChanged<AppProxyProtocol> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(translations.protocol, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppProxyProtocol>(
              selected: {protocol},
              onSelectionChanged: enabled ? (selected) => onChanged(selected.first) : null,
              segments: [
                ButtonSegment(value: AppProxyProtocol.http, icon: const Icon(Icons.public_outlined), label: Text(translations.protocolHttp)),
                ButtonSegment(value: AppProxyProtocol.socks, icon: const Icon(Icons.route_outlined), label: Text(translations.protocolSocks)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProxyEndpointFields extends StatelessWidget {
  const _ProxyEndpointFields({
    required this.hostController,
    required this.portController,
    required this.enabled,
    required this.hostErrorText,
    required this.portErrorText,
    required this.onChanged,
  });

  final TextEditingController hostController;
  final TextEditingController portController;
  final bool enabled;
  final String? hostErrorText;
  final String? portErrorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = hostErrorText != null || portErrorText != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final hostField = _ProxyHostField(controller: hostController, enabled: enabled, errorText: hostErrorText, onChanged: onChanged);
              final portField = _ProxyPortField(controller: portController, enabled: enabled, errorText: portErrorText, onChanged: onChanged);

              if (constraints.maxWidth < 420) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hostField, const SizedBox(height: 12), portField]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: hostField),
                  const SizedBox(width: 12),
                  SizedBox(width: 148, child: portField),
                ],
              );
            },
          ),
          if (!hasError) ...[
            const SizedBox(height: 7),
            Text(translations.helper, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _ProxyHostField extends StatelessWidget {
  const _ProxyHostField({required this.controller, required this.enabled, required this.errorText, required this.onChanged});

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;

    return TextField(
      controller: controller,
      enabled: enabled,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[:\s]'))],
      onChanged: onChanged,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: translations.address,
        hintText: translations.addressHint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.dns_outlined),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ProxyPortField extends StatelessWidget {
  const _ProxyPortField({required this.controller, required this.enabled, required this.errorText, required this.onChanged});

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;

    return TextField(
      controller: controller,
      enabled: enabled,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(labelText: translations.port, hintText: translations.portHint, errorText: errorText),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
