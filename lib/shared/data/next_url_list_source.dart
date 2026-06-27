import 'data_list_source.dart';

abstract class NextUrlListSource<Item, Page> extends DataListSource<Item> {
  String? _nextUrl;

  String? get nextUrl => _nextUrl;

  bool get hasNextPage => _nextUrl != null && _nextUrl!.isNotEmpty;

  Future<Page> loadFirstPage();

  Future<Page> loadNextPage(String nextUrl);

  String? nextUrlFromPage(Page page);

  List<Item> itemsFromPage(Page page);

  void didApplyPage(Page page) {}

  @override
  Future<List<Item>> initList() async {
    return _applyPage(await loadFirstPage());
  }

  @override
  Future<List<Item>> nextList() async {
    final nextUrl = _nextUrl;
    if (nextUrl == null || nextUrl.isEmpty) {
      return <Item>[];
    }

    return _applyPage(await loadNextPage(nextUrl));
  }

  @override
  bool hasMoreByResult(List<Item> list) {
    return hasNextPage;
  }

  @override
  void clearData() {
    _nextUrl = null;
    super.clearData();
  }

  List<Item> _applyPage(Page page) {
    _nextUrl = nextUrlFromPage(page);
    didApplyPage(page);
    return itemsFromPage(page);
  }
}
