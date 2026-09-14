import 'package:freepiv/core/services/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_history_logic.g.dart';

@Riverpod(keepAlive: true)
class SearchHistory extends _$SearchHistory {
  @override
  List<String> build() => AppSettings.searchHistory;

  void record(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    state = List.unmodifiable([value, ...state.where((item) => item != value)].take(30));
    AppSettings.searchHistory = state;
  }

  void clear() {
    state = const [];
    AppSettings.searchHistory = state;
  }
}
