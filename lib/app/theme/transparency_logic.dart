import 'package:freepiv/core/services/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transparency_logic.g.dart';

@Riverpod(keepAlive: true)
class ReduceTransparency extends _$ReduceTransparency {
  @override
  bool build() => AppSettings.reduceTransparency;

  void setEnabled(bool enabled) {
    if (state == enabled) return;
    state = enabled;
    AppSettings.reduceTransparency = enabled;
  }
}
