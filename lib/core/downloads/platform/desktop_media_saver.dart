import 'dart:io';
import 'dart:typed_data';

import 'package:freepiv/core/downloads/download_file_system.dart';
import 'package:freepiv/core/downloads/download_models.dart';
import 'package:freepiv/core/downloads/media_saver.dart';
import 'package:path/path.dart' as p;

final class DesktopMediaSaver implements MediaSaver {
  const DesktopMediaSaver();

  @override
  Future<SaveResult> saveDownloadedFile({required DownloadJob job, required DownloadedFile file}) async {
    final destinationDirectory = Directory(await _resolveDirectory(job));
    await ensureWritableDirectory(destinationDirectory);

    final source = File(file.path);
    if (!await source.exists()) {
      throw DownloadException('Downloaded temp file does not exist: ${file.path}');
    }

    final destination = File(p.join(destinationDirectory.path, safeDownloadFilename(job.filename)));
    await deleteFileIfExists(destination);
    try {
      final moved = await source.rename(destination.path);
      return SaveResult(path: moved.path, bytesWritten: file.bytesWritten);
    } on FileSystemException catch (renameError) {
      try {
        final copied = await source.copy(destination.path);
        try {
          await source.delete();
        } catch (_) {
          // The destination is already saved; temp cleanup should not fail the save.
        }
        return SaveResult(path: copied.path, bytesWritten: file.bytesWritten);
      } catch (copyError) {
        throw DownloadException(
          'Failed to move downloaded file to destination. '
          'source=${source.path}, destination=${destination.path}, renameError=$renameError, copyError=$copyError',
        );
      }
    }
  }

  @override
  Future<SaveResult> saveBytes({required DownloadJob job, required Uint8List bytes}) async {
    final destinationDirectory = Directory(await _resolveDirectory(job));
    final saved = await writeBytesAtomically(bytes: bytes, directory: destinationDirectory, filename: job.filename);
    return SaveResult(path: saved.path, bytesWritten: saved.bytesWritten);
  }

  Future<String> _resolveDirectory(DownloadJob job) async {
    return resolveDesktopDownloadDirectory(explicitDirectory: job.saveTarget.directory);
  }
}
