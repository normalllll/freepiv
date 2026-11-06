import 'package:integration_test/integration_test.dart';

import '../test/newest_discover_alignment_test.dart' as newest_discover;
import '../test/search_header_responsive_test.dart' as search_header;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  newest_discover.main();
  search_header.main();
}
