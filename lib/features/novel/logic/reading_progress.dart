import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/core/history/history_models.dart';
import 'package:freepiv/core/history/history_service.dart';

/// Where the current account stopped reading a novel; null when it has not
/// started it. The reader invalidates it after saving.
final novelReadingProgressProvider = FutureProvider.autoDispose.family<ReadingProgress?, int>((ref, novelId) => loadReadingProgress(novelId));
