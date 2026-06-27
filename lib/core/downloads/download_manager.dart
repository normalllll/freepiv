import 'package:freepiv/core/downloads/default_download_manager.dart';
import 'package:freepiv/core/downloads/download_manager_contract.dart';

export 'download_manager_contract.dart';

DownloadManager? _downloadManager;

DownloadManager get downloadManager {
  return _downloadManager ??= DefaultDownloadManager();
}

Future<void> initializeDownloadManager() {
  return downloadManager.initialize();
}
