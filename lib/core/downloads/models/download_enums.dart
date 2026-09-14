enum DownloadEngineType { desktopRust, androidOkHttpForeground, iosUrlSession, unsupported, mobileRust }

enum DownloadStatus { queued, running, paused, downloaded, failed, cancelled }

enum SaveState { none, pending, saving, saved, failed }

enum SaveTargetType { downloadsFolder, mediaStore, photos }
