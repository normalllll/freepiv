import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/platform/local_files.dart';

void main() {
  test('Windows selects the file in Explorer, with the path its own argument', () {
    final command = revealFileCommand(r'C:\Saved works\a.png', platform: TargetPlatform.windows);
    expect(command.executable, 'explorer.exe');
    expect(command.arguments, ['/select,', r'C:\Saved works\a.png']);
  });

  test('Windows normalises forward slashes, which Explorer does not take', () {
    expect(revealFileCommand('C:/Saved/a.png', platform: TargetPlatform.windows).arguments.last, r'C:\Saved\a.png');
  });

  test('macOS reveals the file in Finder', () {
    final command = revealFileCommand('/Users/me/a.png', platform: TargetPlatform.macOS);
    expect(command.executable, 'open');
    expect(command.arguments, ['-R', '/Users/me/a.png']);
  });

  test('Linux opens the folder', () {
    final command = revealFileCommand('/home/me/saved/a.png', platform: TargetPlatform.linux);
    expect(command.executable, 'xdg-open');
    expect(command.arguments, ['/home/me/saved']);
  });

  test('a missing file throws instead of opening or showing anything', () async {
    final missing = '${Directory.systemTemp.path}/freepiv-no-such-file.png';
    await expectLater(openLocalFile(missing), throwsA(isA<FileSystemException>()));
    await expectLater(revealLocalFile(missing), throwsA(isA<FileSystemException>()));
  });
}
