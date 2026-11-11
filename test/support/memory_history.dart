import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/history/history_database.dart';
import 'package:freepiv/core/history/history_repository.dart';
import 'package:freepiv/core/history/history_service.dart';

/// Makes the browsing history an empty one in memory for the rest of the
/// test, so no test touches the app's own history file.
HistoryRepository useMemoryHistory() {
  // Each test opens its own database in memory; the warning is about files.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final repository = HistoryRepository(HistoryDatabase.withExecutor(NativeDatabase.memory()));
  historyRepository = repository;
  addTearDown(repository.close);
  return repository;
}
