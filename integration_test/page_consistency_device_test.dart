import 'package:integration_test/integration_test.dart';

import '../test/fanbox_account_spacing_test.dart' as fanbox_spacing;
import '../test/grouped_rows_visual_test.dart' as grouped_rows;
import '../test/page_visual_acceptance_test.dart' as page_visual;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  page_visual.main();
  fanbox_spacing.main();
  grouped_rows.main();
}
