import 'package:flutter/material.dart';
import 'package:freepiv/app/theme/app_metrics.dart';
import 'package:freepiv/shared/ui/spring_builder.dart';

/// A count whose changed characters roll to their new value, upward when
/// the number grows and downward when it shrinks (docs/MOTION_SPEC.md 7).
/// Characters are matched from the right, so 9 → 10 rolls the ones digit and
/// adds the tens. With reduced motion the text is replaced at once.
class RollingText extends StatefulWidget {
  const RollingText(this.text, {this.style, super.key});

  final String text;
  final TextStyle? style;

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText> {
  /// 1 when the count grew (new characters come from below), -1 when it shrank.
  double _direction = 1;

  static int? _valueOf(String text) => int.tryParse(text.replaceAll(RegExp(r'\D'), ''));

  @override
  void didUpdateWidget(RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text) return;
    if ((_valueOf(oldWidget.text), _valueOf(widget.text)) case (final before?, final after?)) {
      _direction = after >= before ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.text.characters.toList();
    final duration = AppMotion.duration(context, AppMotion.expand);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < characters.length; index++)
            ClipRect(
              // Slots are keyed from the right so digits keep their place value.
              key: ValueKey(characters.length - index),
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: SpringCurve(AppMotion.snappy, AppMotion.expand),
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(characters[index]);
                  final from = Offset(0, incoming ? _direction : -_direction);
                  return SlideTransition(
                    position: animation.drive(Tween(begin: from, end: Offset.zero)),
                    child: child,
                  );
                },
                child: Text(characters[index], key: ValueKey(characters[index]), style: widget.style),
              ),
            ),
        ],
      ),
    );
  }
}
