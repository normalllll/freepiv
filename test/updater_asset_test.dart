import 'dart:ffi' show Abi;

import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/updater_service.dart';

void main() {
  const assets = [
    AppReleaseAsset(name: 'freepiv-windows-x64.zip', downloadUrl: 'windows'),
    AppReleaseAsset(name: 'macos-arm64-nosigned.zip', downloadUrl: 'arm'),
    AppReleaseAsset(name: 'macos-x86_64-nosigned.zip', downloadUrl: 'intel'),
  ];

  test('an Intel Mac gets the x86_64 build', () {
    expect(UpdaterService.selectMacosAsset(assets, Abi.macosX64)?.downloadUrl, 'intel');
  });

  test('Apple silicon gets the arm64 build', () {
    expect(UpdaterService.selectMacosAsset(assets, Abi.macosArm64)?.downloadUrl, 'arm');
  });

  test('a release without the matching architecture offers nothing', () {
    expect(UpdaterService.selectMacosAsset(assets.where((asset) => asset.downloadUrl != 'intel').toList(), Abi.macosX64), isNull);
  });
}
