import 'package:flutter/material.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/shared/shared.dart';

class NovelNotFoundPage extends StatelessWidget {
  const NovelNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostAutoScaffold(
      builder: (BuildContext context, FrostSizeLayout layout, Orientation orientation, bool useHorizontalLayout) {
        return Scaffold(
          appBar: PivAppBar(FrostPageHeader(title: Text(context.t.common.notFound))),
          body: SafeArea(
            child: FrostEmptyState(icon: FrostIconData.glyph(Icons.menu_book_outlined), title: context.t.common.notFound),
          ),
        );
      },
    );
  }
}
