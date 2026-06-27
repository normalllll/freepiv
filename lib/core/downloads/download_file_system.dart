import 'dart:io';
import 'dart:typed_data';

import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const appDownloadDirectoryName = 'freepiv';
const downloadTempDirectoryName = 'freepiv_downloads';
const fallbackDownloadFilename = 'download';

String filenameFromUrl(Uri url) {
  if (url.pathSegments.isEmpty) {
    return fallbackDownloadFilename;
  }

  final filename = url.pathSegments.last;
  return filename.isEmpty ? fallbackDownloadFilename : filename;
}

String safeDownloadFilename(String filename) {
  final sanitized = filename.replaceAll(RegExp(r'[\\/\x00]'), '_').trim();
  return sanitized.isEmpty ? fallbackDownloadFilename : sanitized;
}

Future<String> resolveDesktopDownloadDirectory({String? explicitDirectory}) async {
  if (explicitDirectory != null && explicitDirectory.isNotEmpty) {
    return explicitDirectory;
  }

  final customDirectory = AppSettings.downloadCustomDirectory;
  if (AppSettings.downloadSavePathMode == DownloadSavePathMode.custom && customDirectory != null) {
    return customDirectory;
  }

  final downloads = await getDownloadsDirectory();
  if (downloads != null) {
    return p.join(downloads.path, appDownloadDirectoryName);
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return p.join(home, 'Downloads', appDownloadDirectoryName);
  }

  return p.join(Directory.current.path, appDownloadDirectoryName);
}

Future<String> prepareDesktopCustomDownloadDirectory(String selectedDirectory) async {
  final directory = Directory(p.join(selectedDirectory, appDownloadDirectoryName));
  await ensureWritableDirectory(directory);
  return directory.path;
}

Future<Directory> downloadTempDirectory() async {
  final temp = await getTemporaryDirectory();
  final directory = Directory(p.join(temp.path, downloadTempDirectoryName));
  await directory.create(recursive: true);
  return directory;
}

Future<void> ensureWritableDirectory(Directory directory) async {
  try {
    await directory.create(recursive: true);
    final probe = File(p.join(directory.path, '.freepiv-write-test-${DateTime.now().microsecondsSinceEpoch}'));
    await probe.writeAsString('ok', flush: true);
    await probe.delete();
  } catch (error) {
    throw DownloadException('Download directory is not writable', error);
  }
}

Future<void> deleteFileIfExists(File file) async {
  if (await file.exists()) {
    await file.delete();
  }
}

Future<DownloadedFile> writeBytesAtomically({required Uint8List bytes, required Directory directory, required String filename}) async {
  await ensureWritableDirectory(directory);

  final destination = File(p.join(directory.path, safeDownloadFilename(filename)));
  final partial = File('${destination.path}.part');
  IOSink? sink;
  try {
    await deleteFileIfExists(partial);
    sink = partial.openWrite();
    sink.add(bytes);
    await sink.flush();
    await sink.close();
    sink = null;

    await deleteFileIfExists(destination);
    final saved = await partial.rename(destination.path);
    return DownloadedFile(path: saved.path, bytesWritten: bytes.lengthInBytes);
  } catch (error) {
    if (sink != null) {
      await sink.close();
    }
    if (await partial.exists()) {
      await partial.delete();
    }
    throw DownloadException('Failed to save file', error);
  }
}
