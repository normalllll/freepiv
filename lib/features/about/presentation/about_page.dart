import 'package:freepiv/shared/widgets/loading_skeleton/loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:freepiv/shared/layout/content_viewport.dart';
import 'package:freepiv/app/theme/app_theme_tokens.dart';
import 'package:freepiv/app/toast/app_toast.dart';
import 'package:freepiv/core/services/updater_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/layout/auto_scaffold.dart';
import 'package:freepiv/shared/layout/fp_page_header.dart';
import 'package:freepiv/shared/ui/fp_icon.dart';
import 'package:freepiv/shared/ui/fp_grouped_rows.dart';
import 'package:freepiv/shared/ui/fp_surface.dart';
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

    return AutoScaffold(
      builder: (context, layout, orientation, useHorizontalLayout) {
        return Scaffold(
          appBar: windowCaptionShowsPageTitle(context, useHorizontalLayout: useHorizontalLayout) ? null : FpPageHeader(title: Text(translations.about.title)),
          body: SafeArea(
            top: useHorizontalLayout,
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final packageInfo = snapshot.data;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: ContentColumn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AboutHero(
                          packageInfo: packageInfo,
                          packageInfoFailed: snapshot.hasError,
                          checkingUpdate: _checkingUpdate,
                          onCheckUpdate: _checkUpdate,
                          onOpenDownloadPage: _openDownloadPage,
                        ),
                        const SizedBox(height: 24),
                        _AboutSection(
                          title: translations.about.versionInfo,
                          children: [
                            _AboutValueRow(
                              icon: FpIconName.info,
                              title: translations.about.appVersion,
                              value: packageInfo == null
                                  ? snapshot.hasError
                                        ? translations.errors.generic
                                        : translations.about.loading
                                  : '${packageInfo.version}+${packageInfo.buildNumber}',
                            ),
                            ValueListenableBuilder<AppUpdateInfo?>(
                              valueListenable: UpdaterService.latestRelease,
                              builder: (context, latestRelease, child) {
                                return _AboutValueRow(
                                  icon: FpIconName.newspaper,
                                  title: translations.about.latestVersion,
                                  value: latestRelease == null ? translations.about.noCachedUpdate : '${latestRelease.version}+${latestRelease.buildNumber}',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _AboutSection(
                          title: translations.about.project,
                          children: [
                            _AboutActionRow(
                              icon: FpIconName.code,
                              title: translations.about.projectPage,
                              subtitle: UpdaterService.projectUrl,
                              onTap: () => _openUrl(UpdaterService.projectUrl),
                            ),
                            _AboutActionRow(
                              icon: FpIconName.newspaper,
                              title: translations.about.releasePage,
                              subtitle: UpdaterService.latestReleaseUrl,
                              onTap: _openDownloadPage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _AboutSection(
                          title: translations.about.community,
                          children: [
                            _AboutActionRow(
                              icon: FpIconName.send,
                              title: translations.about.telegram,
                              subtitle: 'https://t.me/+ONtNV3HTQ0NhMzVh',
                              onTap: () => _openUrl('https://t.me/+ONtNV3HTQ0NhMzVh'),
                            ),
                            _AboutActionRow(
                              icon: FpIconName.messageCircle,
                              title: translations.about.discord,
                              subtitle: 'https://discord.gg/jQatz6965H',
                              onTap: () => _openUrl('https://discord.gg/jQatz6965H'),
                            ),
                          ],
                        ),
                      ],
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
    try {
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        AppToast.error(failureMessage ?? context.t.about.openLinkFailed);
      }
    } catch (_) {
      if (mounted) AppToast.error(failureMessage ?? context.t.about.openLinkFailed);
    }
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero({
    required this.packageInfo,
    required this.packageInfoFailed,
    required this.checkingUpdate,
    required this.onCheckUpdate,
    required this.onOpenDownloadPage,
  });

  final PackageInfo? packageInfo;
  final bool packageInfoFailed;
  final bool checkingUpdate;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenDownloadPage;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.about;
    final tokens = FreepivThemeTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final currentPackageInfo = packageInfo;

    return FpSurface(
      role: FpSurfaceRole.glassPanel,
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
                            ? packageInfoFailed
                                  ? context.t.errors.generic
                                  : translations.loading
                            : translations.currentVersion(version: currentPackageInfo.version, buildNumber: currentPackageInfo.buildNumber),
                        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: checkingUpdate ? null : onCheckUpdate,
                  icon: checkingUpdate ? const SizedBox.square(dimension: 16, child: LoadingSkeletonBlock()) : const FpIcon(FpIconName.refreshCw, size: 18),
                  label: Text(translations.checkUpdate),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenDownloadPage,
                  icon: const FpIcon(FpIconName.externalLink, size: 18),
                  label: Text(translations.downloadPage),
                ),
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
        FpGroupedRows(children: children),
      ],
    );
  }
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final FpIconName icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: FpIcon(icon, size: 24),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const FpIcon(FpIconName.externalLink, size: 18),
    );
  }
}

class _AboutValueRow extends StatelessWidget {
  const _AboutValueRow({required this.icon, required this.title, required this.value});

  final FpIconName icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600 || MediaQuery.textScalerOf(context).scale(16) >= 24) {
      return ListTile(leading: FpIcon(icon, size: 24), title: Text(title), subtitle: Text(value));
    }
    return ListTile(
      leading: FpIcon(icon, size: 24),
      title: Text(title),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
