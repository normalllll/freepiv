import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/updater_service.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the project's community gathers.
const _telegramUrl = 'https://t.me/+ONtNV3HTQ0NhMzVh';
const _discordUrl = 'https://discord.gg/jQatz6965H';

/// What checking for an update has come to.
sealed class _UpdateCheck {
  const _UpdateCheck();
}

class _NotChecked extends _UpdateCheck {
  const _NotChecked();
}

class _Checking extends _UpdateCheck {
  const _Checking();
}

class _UpToDate extends _UpdateCheck {
  const _UpToDate();
}

class _Available extends _UpdateCheck {
  const _Available(this.update);
  final AppUpdateInfo update;
}

class _CheckFailed extends _UpdateCheck {
  const _CheckFailed();
}

/// About: the app's icon, name, version and build over
/// one group of rows: Check for updates, whose value says what it found, and
/// the project, release, Telegram and Discord links, opened outside.
class AboutPage extends StatefulWidget {
  const AboutPage({this.packageInfo = UpdaterService.packageInfo, this.checkForUpdate = UpdaterService.checkForUpdate, this.openUrl = _launch, super.key});

  final Future<PackageInfo> Function() packageInfo;
  final Future<AppUpdateInfo?> Function() checkForUpdate;

  /// Opens a link outside the app; false when nothing could.
  final Future<bool> Function(String url) openUrl;

  static Future<bool> _launch(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// The edge of the app icon.
  static const iconExtent = 72.0;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfo = widget.packageInfo();
  _UpdateCheck _check = const _NotChecked();

  /// Checks once at a time; a newer release opens its download for this platform.
  Future<void> _checkUpdate() async {
    if (_check is _Checking) return;
    setState(() => _check = const _Checking());
    final t = context.t.about;
    try {
      final update = await widget.checkForUpdate();
      if (!mounted) return;
      setState(() => _check = update == null ? const _UpToDate() : _Available(update));
      if (update == null) return;
      final downloadUrl = await UpdaterService.selectDownloadUrl(update.assets);
      if (!mounted) return;
      if (downloadUrl == null) {
        FrostToast.warning(t.downloadAssetUnavailable);
        await _open(update.releaseUrl, failure: t.openDownloadFailed);
        return;
      }
      await _open(downloadUrl, failure: t.openDownloadFailed);
    } catch (error) {
      if (!mounted) return;
      setState(() => _check = const _CheckFailed());
      toastErrorWithCause(t.checkUpdateFailed, error);
    }
  }

  Future<void> _open(String url, {String? failure}) async {
    final message = failure ?? context.t.about.openLinkFailed;
    try {
      if (!await widget.openUrl(url) && mounted) FrostToast.error(message);
    } catch (_) {
      if (mounted) FrostToast.error(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FrostPinnedChrome(
      chrome: FrostContentColumn(
        maxWidth: FrostMetrics.readingMaxWidth,
        child: FrostPageHeader(title: FrostText(t.about.title)),
      ),
      body: FrostLoadingScrollView(
        slivers: [
          const FrostChromeSpacer(),
          SliverToBoxAdapter(
            child: FrostContentColumn(
              maxWidth: FrostMetrics.readingMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FrostGap.section,
                children: [
                  _Identity(packageInfo: _packageInfo),
                  FrostGroupedSection(
                    children: [
                      _checkRow(context),
                      FrostListRow(
                        leading: const FrostGlyph.icon(PivIcons.code),
                        title: t.about.projectPage,
                        subtitle: const FrostRowSubtitle(UpdaterService.projectUrl, tone: FrostTextTone.tertiary),
                        accessory: FrostRowAccessory.external,
                        onPressed: () => unawaited(_open(UpdaterService.projectUrl)),
                      ),
                      FrostListRow(
                        leading: const FrostGlyph.icon(PivIcons.newspaper),
                        title: t.about.releasePage,
                        subtitle: const FrostRowSubtitle(UpdaterService.latestReleaseUrl, tone: FrostTextTone.tertiary),
                        accessory: FrostRowAccessory.external,
                        onPressed: () => unawaited(_open(UpdaterService.latestReleaseUrl, failure: t.about.openDownloadFailed)),
                      ),
                      FrostListRow(
                        leading: const FrostGlyph.icon(PivIcons.send),
                        title: t.about.telegram,
                        accessory: FrostRowAccessory.external,
                        onPressed: () => unawaited(_open(_telegramUrl)),
                      ),
                      FrostListRow(
                        leading: const FrostGlyph.icon(PivIcons.messageCircle),
                        title: t.about.discord,
                        accessory: FrostRowAccessory.external,
                        onPressed: () => unawaited(_open(_discordUrl)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check for updates; its value is what the last check found, a failure
  /// with its retry, or the release last seen.
  Widget _checkRow(BuildContext context) {
    final t = context.t.about;
    final check = _check;
    return ValueListenableBuilder(
      valueListenable: UpdaterService.latestRelease,
      builder: (context, latest, _) => FrostListRow(
        key: const ValueKey('about-check-update'),
        leading: const FrostGlyph.icon(PivIcons.refreshCw),
        title: t.checkUpdate,
        subtitle: switch (check) {
          _CheckFailed() => FrostRowSubtitle(t.checkUpdateFailed, tone: FrostTextTone.negative),
          _ => null,
        },
        value: switch (check) {
          _UpToDate() => t.noUpdate,
          _Available(:final update) => t.updateAvailable(version: update.version, buildNumber: update.buildNumber),
          _NotChecked() when latest != null => t.latestValue(version: latest.version, buildNumber: latest.buildNumber),
          _ => null,
        },
        trailing: switch (check) {
          _Checking() => FrostActivityIndicator(semanticLabel: t.checkingUpdate),
          _CheckFailed() => FrostButton.quiet(label: context.t.common.retry, onPressed: () => unawaited(_checkUpdate())),
          _ => null,
        },
        onPressed: check is _Checking ? null : () => unawaited(_checkUpdate()),
      ),
    );
  }
}

/// The app's icon and name, and its version and build once known.
class _Identity extends StatelessWidget {
  const _Identity({required this.packageInfo});

  final Future<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return FutureBuilder(
      future: packageInfo,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Column(
          spacing: FrostGap.related,
          children: [
            Image.asset('assets/icon-512.png', width: AboutPage.iconExtent, height: AboutPage.iconExtent, cacheWidth: 256, excludeFromSemantics: true),
            FrostText(t.about.appName, role: FrostTextRole.title1, textAlign: TextAlign.center),
            FrostText(
              switch ((info, snapshot.hasError)) {
                (final info?, _) => t.about.currentVersion(version: info.version, buildNumber: info.buildNumber),
                (_, true) => t.errors.generic,
                _ => t.about.loading,
              },
              role: FrostTextRole.footnote,
              tone: FrostTextTone.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
