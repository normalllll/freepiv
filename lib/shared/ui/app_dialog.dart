import 'dart:ui' show SemanticsHitTestBehavior;

import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';

/// [showDialog] with the app's dialog motion (docs/MOTION_SPEC.md 8): the
/// dialog fades in while growing from 0.96 on a no-bounce spring, together
/// with its scrim, and leaves faster than it came. With reduced motion it
/// only fades.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _AppDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? DialogTheme.of(context).barrierColor ?? Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      // Like showDialog: taps inside the dialog never reach the scrim.
      pageBuilder: (dialogContext, _, _) => Semantics(
        hitTestBehavior: SemanticsHitTestBehavior.opaque,
        child: SafeArea(child: themes.wrap(Builder(builder: builder))),
      ),
    ),
  );
}

class _AppDialogRoute<T> extends RawDialogRoute<T> {
  _AppDialogRoute({required super.pageBuilder, required super.barrierDismissible, required super.barrierColor, required super.barrierLabel})
    : super(transitionDuration: AppMotion.page);

  static final _enter = SpringCurve(AppMotion.snappy, AppMotion.page);

  late final _fade = CurvedAnimation(parent: animation!, curve: Curves.easeOut);
  late final _scaleCurve = CurvedAnimation(parent: animation!, curve: _enter, reverseCurve: Curves.easeInCubic);
  late final _scale = _scaleCurve.drive(Tween(begin: .96, end: 1.0));

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final fade = FadeTransition(opacity: _fade, child: child);
    return MediaQuery.disableAnimationsOf(context) ? fade : ScaleTransition(scale: _scale, child: fade);
  }

  @override
  void dispose() {
    _fade.dispose();
    _scaleCurve.dispose();
    super.dispose();
  }
}

/// Bottom sheet motion (docs/MOTION_SPEC.md 8): rises on a no-bounce spring
/// and leaves faster. Dragging and flinging stay the sheet's own; with
/// reduced motion it appears and leaves at once.
AnimationStyle appSheetAnimationStyle(BuildContext context) => MediaQuery.disableAnimationsOf(context)
    ? const AnimationStyle(duration: Duration.zero, reverseDuration: Duration.zero)
    : AnimationStyle(duration: _sheetDuration, reverseDuration: AppMotion.exit, curve: SpringCurve(AppMotion.standard, _sheetDuration));

const _sheetDuration = Duration(milliseconds: 350);
