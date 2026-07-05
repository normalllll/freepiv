import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/services/updater_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfoFuture = UpdaterService.packageInfo();
  bool _checkingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final tokens = FreepivThemeTokens.of(context);

    return AutoScaffold(
      builder: (context, layout, orientation, shouldUseDesktopShell) {
        final horizontalPadding = shouldUseDesktopShell ? 24.0 : 16.0;

        return Scaffold(
          backgroundColor: tokens.surface,
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(translations.about.title)),
          body: SafeArea(
            top: shouldUseDesktopShell,
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final packageInfo = snapshot.data;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (shouldUseDesktopShell) ...[
                            Text(translations.about.title, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 14),
                          ],
                          _AboutHero(
                            packageInfo: packageInfo,
                            checkingUpdate: _checkingUpdate,
                            onCheckUpdate: _checkUpdate,
                            onOpenDownloadPage: _openDownloadPage,
                          ),
                          const SizedBox(height: 14),
                          _AboutSection(
                            title: translations.about.project,
                            children: [
                              _AboutActionRow(
                                icon: Icons.code_outlined,
                                title: translations.about.projectPage,
                                subtitle: UpdaterService.projectUrl,
                                onTap: () => _openUrl(UpdaterService.projectUrl),
                              ),
                              _AboutActionRow(
                                icon: Icons.new_releases_outlined,
                                title: translations.about.releasePage,
                                subtitle: UpdaterService.latestReleaseUrl,
                                onTap: _openDownloadPage,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _AboutSection(
                            title: translations.about.versionInfo,
                            children: [
                              _AboutValueRow(
                                icon: Icons.app_shortcut_outlined,
                                title: translations.about.appVersion,
                                value: packageInfo == null ? translations.about.loading : '${packageInfo.version}+${packageInfo.buildNumber}',
                              ),
                              ValueListenableBuilder<AppUpdateInfo?>(
                                valueListenable: UpdaterService.latestRelease,
                                builder: (context, latestRelease, child) {
                                  return _AboutValueRow(
                                    icon: Icons.system_update_alt_outlined,
                                    title: translations.about.latestVersion,
                                    value: latestRelease == null ? translations.about.noCachedUpdate : '${latestRelease.version}+${latestRelease.buildNumber}',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _AboutSection(
                            title: translations.about.community,
                            children: [
                              _AboutActionRow(
                                icon: Icons.telegram_outlined,
                                title: translations.about.telegram,
                                subtitle: 'https://t.me/+ONtNV3HTQ0NhMzVh',
                                onTap: () => _openUrl('https://t.me/+ONtNV3HTQ0NhMzVh'),
                              ),
                              _AboutActionRow(
                                icon: Icons.discord_outlined,
                                title: translations.about.discord,
                                subtitle: 'https://discord.gg/jQatz6965H',
                                onTap: () => _openUrl('https://discord.gg/jQatz6965H'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkUpdate() async {
    if (_checkingUpdate) {
      return;
    }

    setState(() {
      _checkingUpdate = true;
    });

    final translations = context.t.about;
    try {
      AppToast.info(translations.checkingUpdate);
      final update = await UpdaterService.checkForUpdate();
      if (!mounted) {
        return;
      }

      if (update == null) {
        AppToast.info(translations.noUpdate);
        return;
      }

      AppToast.success(translations.updateAvailable(version: update.version, buildNumber: update.buildNumber));
      final downloadUrl = await UpdaterService.selectDownloadUrl(update.assets);
      if (!mounted) {
        return;
      }

      if (downloadUrl == null) {
        AppToast.warning(translations.downloadAssetUnavailable);
        await _openUrl(update.releaseUrl, failureMessage: translations.openDownloadFailed);
        return;
      }

      await _openUrl(downloadUrl, failureMessage: translations.openDownloadFailed);
    } catch (error) {
      if (mounted) {
        AppToast.errorWithCause(translations.checkUpdateFailed, error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
        });
      }
    }
  }

  Future<void> _openDownloadPage() {
    return _openUrl(UpdaterService.latestReleaseUrl, failureMessage: context.t.about.openDownloadFailed);
  }

  Future<void> _openUrl(String url, {String? failureMessage}) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppToast.error(failureMessage ?? context.t.about.openLinkFailed);
    }
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero({required this.packageInfo, required this.checkingUpdate, required this.onCheckUpdate, required this.onOpenDownloadPage});

  final PackageInfo? packageInfo;
  final bool checkingUpdate;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenDownloadPage;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.about;
    final tokens = FreepivThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final currentPackageInfo = packageInfo;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.line),
        boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: tokens.surfaceTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tokens.line),
                    ),
                    child: Image.asset('assets/icon-512.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(translations.appName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(
                        currentPackageInfo == null
                            ? translations.loading
                            : translations.currentVersion(version: currentPackageInfo.version, buildNumber: currentPackageInfo.buildNumber),
                        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(translations.subtitle, style: textTheme.bodyMedium?.copyWith(height: 1.35)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: checkingUpdate ? null : onCheckUpdate,
                  icon: checkingUpdate
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.system_update_alt_outlined),
                  label: Text(checkingUpdate ? translations.checkingUpdateShort : translations.checkUpdate),
                ),
                OutlinedButton.icon(onPressed: onOpenDownloadPage, icon: const Icon(Icons.open_in_new_outlined), label: Text(translations.downloadPage)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.line),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AboutRowShell(
      onTap: onTap,
      icon: icon,
      trailing: const Icon(Icons.north_east_outlined, size: 18),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AboutValueRow extends StatelessWidget {
  const _AboutValueRow({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _AboutRowShell(
      icon: icon,
      trailing: Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      child: Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
    );
  }
}

class _AboutRowShell extends StatelessWidget {
  const _AboutRowShell({required this.icon, required this.child, required this.trailing, this.onTap});

  final IconData icon;
  final Widget child;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = FreepivThemeTokens.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: tokens.surfaceTint, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: tokens.brand),
              ),
              const SizedBox(width: 12),
              child,
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
