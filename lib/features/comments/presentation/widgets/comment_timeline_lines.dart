import 'package:flutter/material.dart';
import 'package:frost_ui/frost_ui.dart';

/// Separates adjacent root comment groups within the content column.
class CommentSeparator extends StatelessWidget {
  const CommentSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: FrostThemeTokens.of(context).separator),
    );
  }
}

/// Marks reply nesting without adding a surface around each reply.
class CommentReplyRail extends StatelessWidget {
  const CommentReplyRail({required this.child, this.contentInset = 12, super.key});

  final Widget child;
  final double contentInset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: FrostThemeTokens.of(context).threadLine, width: 2)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: contentInset),
        child: child,
      ),
    );
  }
}
