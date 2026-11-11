import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_accounts.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  test('search history survives a real Hive write and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('freepiv_history_');
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('history_test');
    addTearDown(() async {
      if (box.isOpen) await box.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    await AppSettings.initialize(store: HiveAppSettingsStore(box));
    AppSettings.accounts = const PixivAccountBook().activate(sampleAccount, DateTime.utc(2026, 11, 1));
    AppSettings.searchHistory = ['alpha', 'miku'];
    await HiveAppSettingsStore(box).write(AppSettings.accountsKey, AppSettings.accounts.toJson());
    await box.close();

    final reopened = await Hive.openBox<dynamic>('history_test');
    addTearDown(() async {
      if (reopened.isOpen) await reopened.close();
    });
    await AppSettings.initialize(store: HiveAppSettingsStore(reopened));
    expect(AppSettings.accounts.activeId, sampleAccount.user.id);
    expect(AppSettings.searchHistory, ['alpha', 'miku']);
  });
}
