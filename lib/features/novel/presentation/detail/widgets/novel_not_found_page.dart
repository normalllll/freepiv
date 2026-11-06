import 'package:flutter/widgets.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/ui/compositions/page_error.dart';

class NovelNotFoundPage extends StatelessWidget {
  const NovelNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageError.notFound(message: context.t.common.notFound);
}
