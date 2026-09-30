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

/// Everything asked for is already queued or downloading; nothing was added.
class DownloadAlreadyQueued extends DownloadException {
  const DownloadAlreadyQueued() : super('This image is already queued or downloading.');
}
