import 'package:flutter/widgets.dart';
import 'package:freepiv/core/downloads/download_models.dart';

/// The source downloads started below are filed under: the article, novel or
/// FANBOX page showing the images. Pages wrap their content in one, so an
/// image menu deep inside knows what it is part of.
class DownloadSourceScope extends InheritedWidget {
  const DownloadSourceScope({required this.source, required super.child, super.key});

  final DownloadSource source;

  /// The nearest scope's source. Read when a download starts, so nothing
  /// rebuilds when it changes.
  static DownloadSource of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DownloadSourceScope>();
    if (scope == null) {
      throw FlutterError('No DownloadSourceScope above this widget; the page showing it must provide its download source.');
    }
    return scope.source;
  }

  @override
  bool updateShouldNotify(DownloadSourceScope oldWidget) => false;
}
