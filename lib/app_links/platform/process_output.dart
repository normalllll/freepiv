import 'dart:io';

String processOutput(ProcessResult result) {
  final stderr = result.stderr.toString().trim();
  if (stderr.isNotEmpty) {
    return stderr;
  }

  final stdout = result.stdout.toString().trim();
  if (stdout.isNotEmpty) {
    return stdout;
  }

  return 'exitCode=${result.exitCode}';
}
