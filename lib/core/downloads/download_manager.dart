import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_manager_configuration.dart';
import 'package:freepiv/core/downloads/download_manager_contract.dart';
import 'package:freepiv/core/services/app_settings.dart';

export 'download_manager_contract.dart';

DownloadManager? _downloadManager;
DownloadSessionHeaders? _sessionHeaders;

/// Sets where downloads get their session headers (see
/// DownloadSessionHeaders); called once at startup, before the manager is
/// first used.
void useDownloadSessionHeaders(DownloadSessionHeaders headers) {
  assert(_downloadManager == null, 'Session headers must be set before the download manager starts.');
  _sessionHeaders = headers;
}

DownloadManager get downloadManager {
  return _downloadManager ??= DefaultDownloadManager(
    configuration: DownloadManagerConfiguration(
      maxConcurrentDownloads: () => AppSettings.maxConcurrentDownloads,
      resolveNetworkOptions: (url, requested) {
        final proxyUrl = requested.proxyUrl ?? AppSettings.proxySettings.activeUrl;
        return requested.copyWith(proxyUrl: proxyUrl).normalizedFor(url);
      },
      sessionHeaders: (job) async => await _sessionHeaders?.call(job) ?? const {},
    ),
  );
}

Future<void> initializeDownloadManager() {
  return downloadManager.initialize();
}
