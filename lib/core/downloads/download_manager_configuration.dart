import 'download_models.dart';

typedef MaxConcurrentDownloadsProvider = int Function();
typedef DownloadNetworkOptionsResolver = DownloadNetworkOptions Function(Uri url, DownloadNetworkOptions requested);

/// The headers a download needs from a signed-in session, such as a cookie:
/// added each time the download starts and never stored with it, so the
/// history holds no credentials. Throws when the session is missing, which
/// fails the download until it is retried signed in.
typedef DownloadSessionHeaders = Future<Map<String, String>> Function(DownloadJob job);

class DownloadManagerConfiguration {
  const DownloadManagerConfiguration({
    required this.maxConcurrentDownloads,
    this.resolveNetworkOptions = _identityNetworkOptions,
    this.sessionHeaders = _noSessionHeaders,
  });

  final MaxConcurrentDownloadsProvider maxConcurrentDownloads;
  final DownloadNetworkOptionsResolver resolveNetworkOptions;
  final DownloadSessionHeaders sessionHeaders;
}

Future<Map<String, String>> _noSessionHeaders(DownloadJob job) async => const {};

DownloadNetworkOptions _identityNetworkOptions(Uri url, DownloadNetworkOptions requested) {
  return requested.normalizedFor(url);
}
