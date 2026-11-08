import 'package:flutter/widgets.dart';

/// Whether the system has transparency off, from the live window; the saved
/// background stays as chosen, only what is painted follows this.
class SystemTransparencyPreference extends InheritedWidget {
  const SystemTransparencyPreference({required this.disabled, required super.child, super.key});

  final bool disabled;

  static bool disabledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SystemTransparencyPreference>()?.disabled ?? MediaQuery.highContrastOf(context);

  @override
  bool updateShouldNotify(SystemTransparencyPreference oldWidget) => disabled != oldWidget.disabled;
}
