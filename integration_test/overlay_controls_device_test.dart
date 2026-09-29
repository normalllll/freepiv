import 'package:integration_test/integration_test.dart';

import '../test/download_dock_flow_test.dart' as downloads;
import '../test/more_menu_adaptive_test.dart' as more_menu;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  more_menu.main();
  downloads.main();
}
