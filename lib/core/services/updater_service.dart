import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppReleaseAsset {
  const AppReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final String downloadUrl;
}

class AppUpdateInfo {
  const AppUpdateInfo({required this.version, required this.buildNumber, required this.releaseUrl, required this.assets});

  final String version;
  final int buildNumber;
  final String releaseUrl;
  final List<AppReleaseAsset> assets;
}

class UpdaterService {
  UpdaterService._();

  static const projectUrl = 'https://github.com/normalllll/freepiv';
  static const latestReleaseUrl = '$projectUrl/releases/latest';
  static const _latestReleaseApiUrl = 'https://api.github.com/repos/normalllll/freepiv/releases/latest';

  static final ValueNotifier<AppUpdateInfo?> latestRelease = ValueNotifier<AppUpdateInfo?>(null);
  static final ValueNotifier<AppUpdateInfo?> availableUpdate = ValueNotifier<AppUpdateInfo?>(null);

  static Future<void> checkOnAppStart() async {
    try {
      await checkForUpdate();
    } catch (_) {
      // Startup checks should never block entering the app.
    }
  }

  static Future<PackageInfo> packageInfo() {
    return PackageInfo.fromPlatform();
  }

  static Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final latest = await _fetchLatestRelease();
    latestRelease.value = latest;

    if (latest.buildNumber <= currentBuildNumber) {
      availableUpdate.value = null;
      return null;
    }

    availableUpdate.value = latest;
    return latest;
  }

  static Future<String?> selectDownloadUrl(List<AppReleaseAsset> assets) async {
    if (assets.isEmpty) {
      return null;
    }

    final lowerNames = {for (final asset in assets) asset.name.toLowerCase(): asset};
    AppReleaseAsset? exact(String name) => lowerNames[name.toLowerCase()];
    AppReleaseAsset? contains(List<String> needles) {
      for (final asset in assets) {
        final name = asset.name.toLowerCase();
        if (needles.every(name.contains)) {
          return asset;
        }
      }
      return null;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      for (final abi in androidInfo.supportedAbis) {
        final match = exact('app-$abi-release.apk') ?? contains([abi, '.apk']);
        if (match != null) {
          return match.downloadUrl;
        }
      }
      return (exact('app-universal-release.apk') ?? contains(['universal', '.apk']) ?? contains(['.apk']))?.downloadUrl;
    }

    if (Platform.isMacOS) {
      return (contains(['macos', 'arm64', '.zip']) ?? contains(['macos', 'x64', '.zip']) ?? contains(['macos', '.zip']))?.downloadUrl;
    }

    if (Platform.isWindows) {
      return (contains(['windows', 'x64', '.zip']) ?? contains(['windows', '.zip']))?.downloadUrl;
    }

    if (Platform.isLinux) {
      return (contains(['linux', 'amd64', '.tar.gz']) ??
              contains(['linux', 'x64', '.tar.gz']) ??
              contains(['amd64', '.deb']) ??
              contains(['amd64', '.rpm']) ??
              contains(['linux']))
          ?.downloadUrl;
    }

    return null;
  }

  static Future<AppUpdateInfo> _fetchLatestRelease() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_latestReleaseApiUrl));
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'freepiv-update-checker');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('GitHub release request failed: ${response.statusCode}', uri: Uri.parse(_latestReleaseApiUrl));
      }

      final json = jsonDecode(body);
      if (json is! Map<String, Object?>) {
        throw const FormatException('Invalid release response.');
      }

      return _parseRelease(json);
    } finally {
      client.close(force: true);
    }
  }

  static AppUpdateInfo _parseRelease(Map<String, Object?> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final match = RegExp(r'^v?(.+)\+(\d+)$').firstMatch(tagName);
    if (match == null) {
      throw FormatException('Invalid release tag: $tagName');
    }

    final assetsJson = json['assets'];
    final assets = <AppReleaseAsset>[];
    if (assetsJson is List) {
      for (final assetJson in assetsJson) {
        if (assetJson is! Map<String, Object?>) {
          continue;
        }
        final name = assetJson['name'] as String?;
        final url = assetJson['browser_download_url'] as String?;
        if (name == null || url == null) {
          continue;
        }
        assets.add(AppReleaseAsset(name: name, downloadUrl: url));
      }
    }

    return AppUpdateInfo(
      version: match.group(1)!,
      buildNumber: int.parse(match.group(2)!),
      releaseUrl: json['html_url'] as String? ?? latestReleaseUrl,
      assets: assets,
    );
  }
}
