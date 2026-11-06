class DownloadException implements Exception {
  const DownloadException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final cause = this.cause;
    if (cause == null) {
      return message;
    }
    return '$message: $cause';
  }
}

/// A file the app made itself (an animation's GIF) failed; retrying would
/// download its source as the file, so it has to be made again from its work.
class GeneratedDownloadRetryRefused extends DownloadException {
  const GeneratedDownloadRetryRefused() : super('This file is made in the app; open its work to make it again.');
}

/// Everything asked for is already queued or downloading; nothing was added.
class DownloadAlreadyQueued extends DownloadException {
  const DownloadAlreadyQueued() : super('This image is already queued or downloading.');
}
