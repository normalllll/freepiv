import 'package:integration_test/integration_test.dart';

import '../test/newest_discover_alignment_test.dart' as newest_discover;
import '../test/page_tabs_consistency_test.dart' as page_tabs;
import '../test/search_header_responsive_test.dart' as search_header;
import '../test/third_work_package_visual_test.dart' as other_pages;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  newest_discover.main();
  page_tabs.main();
  search_header.main();
  other_pages.main();
}
