// app-owned: novel reader page turn
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:frost_ui/frost_ui.dart';

/// Two pages part way through a turn. [progress] runs from 0, only [current]
/// in view, to 1, only [next] in view; [direction] is 1 turning forward and -1
/// turning back.
///
/// A cover turn slides [next] over [current] on the reading [background], its
/// edge shadow growing in the first quarter of the turn. A slide turn moves
/// both pages across [width] together.
class ReaderPageTurn extends StatelessWidget {
  const ReaderPageTurn({
    required this.cover,
    required this.direction,
    required this.progress,
    required this.width,
    required this.background,
    required this.current,
    required this.next,
    super.key,
  });

  final bool cover;
  final int direction;
  final double progress;
  final double width;
  final Color background;
  final Widget current;
  final Widget next;

  @override
  Widget build(BuildContext context) {
    final incoming = Offset(direction * (1 - progress) * width, 0);
    if (cover) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(child: current),
          Transform.translate(
            offset: incoming,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                boxShadow: [BoxShadow(color: FrostThemeTokens.of(context).shadow, blurRadius: 16 * math.min(1, progress * 4), spreadRadius: 1)],
              ),
              child: Center(child: next),
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(
          offset: Offset(-direction * progress * width, 0),
          child: Center(child: current),
        ),
        Transform.translate(
          offset: incoming,
          child: Center(child: next),
        ),
      ],
    );
  }
}
