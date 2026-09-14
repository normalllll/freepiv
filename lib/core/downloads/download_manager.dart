import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_manager_contract.dart';
import 'package:freepiv/core/services/app_settings.dart';

export 'download_manager_contract.dart';

DownloadManager? _downloadManager;

DownloadManager get downloadManager {
  return _downloadManager ??= DefaultDownloadManager(
    configuration: DownloadManagerConfiguration(
      maxConcurrentDownloads: () => AppSettings.maxConcurrentDownloads,
      resolveNetworkOptions: (url, requested) {
        final proxyUrl = requested.proxyUrl ?? AppSettings.proxySettings.activeUrl;
        return requested.copyWith(proxyUrl: proxyUrl).normalizedFor(url);
      },
    ),
  );
}

Future<void> initializeDownloadManager() {
  return downloadManager.initialize();
}
