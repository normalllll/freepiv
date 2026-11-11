import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:frost_ui/frost_ui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  test('appearance record survives a real Hive write and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('freepiv_appearance_');
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('appearance_test');
    addTearDown(() async {
      if (box.isOpen) await box.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    await AppSettings.initialize(store: HiveAppSettingsStore(box));
    await AppSettings.saveAppearance(FrostAppearance.initial(FrostPalettes.pink).copyWith(mode: ThemeMode.light, lightAccent: Color(0xFF4C8DFF)));
    await box.close();

    final reopened = await Hive.openBox<dynamic>('appearance_test');
    addTearDown(() async {
      if (reopened.isOpen) await reopened.close();
    });
    await AppSettings.initialize(store: HiveAppSettingsStore(reopened));
    expect(AppSettings.appearance.mode, ThemeMode.light);
    expect(AppSettings.appearance.lightAccent, const Color(0xFF4C8DFF));
  });
}
