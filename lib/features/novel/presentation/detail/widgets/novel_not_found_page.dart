import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class NovelNotFoundPage extends StatelessWidget {
  const NovelNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoScaffold(
      builder: (BuildContext context, AutoScaffoldLayout layout, Orientation orientation, bool shouldUseDesktopShell) {
        return Scaffold(
          appBar: shouldUseDesktopShell ? null : AppBar(title: Text(context.t.common.notFound)),
          body: SafeArea(
            child: EmptyContent(icon: Icons.menu_book_outlined, title: context.t.common.notFound),
          ),
        );
      },
    );
  }
}
