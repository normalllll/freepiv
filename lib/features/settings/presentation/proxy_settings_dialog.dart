import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final TextEditingController _controller;
  late bool _enabled;
  bool _isFetchingSystemProxy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(proxySettingsProvider);
    _enabled = settings.enabled;
    _controller = TextEditingController(text: settings.url ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final proxyTranslations = translations.settings.proxy;
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height - media.viewInsets.bottom - media.padding.vertical - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight.clamp(320.0, double.infinity).toDouble()),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.line.withValues(alpha: 0.64)),
              boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 28, offset: const Offset(0, 16))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                              Text(
                                proxyTranslations.subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.35),
                              ),
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
                          _errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _ProxyAddressField(
                      controller: _controller,
                      enabled: _enabled,
                      errorText: _errorText,
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorText ?? proxyTranslations.helper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _errorText == null ? colorScheme.onSurfaceVariant : colorScheme.error,
                        fontWeight: _errorText == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    if (isDesktopPlatform) ...[
                      const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
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
      _errorText = null;
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

      _controller
        ..text = normalizedProxy
        ..selection = TextSelection.collapsed(offset: normalizedProxy.length);
      setState(() {
        _enabled = true;
        _errorText = null;
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
    final rawUrl = _controller.text.trim();
    final normalizedUrl = normalizeProxyUrl(rawUrl);

    if (_enabled && rawUrl.isEmpty) {
      setState(() => _errorText = translations.required);
      return;
    }

    if (rawUrl.isNotEmpty && normalizedUrl == null) {
      setState(() => _errorText = translations.invalid);
      return;
    }

    ref.read(proxySettingsProvider.notifier).setProxySettings(AppProxySettings(enabled: _enabled, url: normalizedUrl));
    AppToast.success(translations.saved);
    Navigator.of(context).pop();
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

class _ProxyAddressField extends StatelessWidget {
  const _ProxyAddressField({required this.controller, required this.enabled, required this.errorText, required this.onChanged});

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.settings.proxy;
    final tokens = FreepivThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(tokens.surfaceTint.withValues(alpha: 0.35), tokens.surfaceRaised),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasError ? colorScheme.error : tokens.line.withValues(alpha: 0.72), width: hasError ? 1.3 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Icon(Icons.route_outlined, color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations.address,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800),
                    ),
                    TextField(
                      controller: controller,
                      enabled: enabled,
                      onChanged: onChanged,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration.collapsed(hintText: translations.addressHint),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
