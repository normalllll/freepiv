import 'dart:async';
import 'article_images.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:frost_data/frost_data.dart';

part 'logic.g.dart';

String pixivisionLanguagePath(AppLocale locale) => switch (locale) {
  AppLocale.zhCn => 'zh',
  AppLocale.zhHantTw => 'zh-tw',
  AppLocale.jaJp => 'ja',
  AppLocale.enUs => 'en',
};

@riverpod
Future<PixivisionApi> pixivisionApi(Ref ref, String language) => PixivisionApi.newInstance(
  config: PixivisionConfig(
    language: switch (language) {
      'zh' => Language.simplifiedChinese,
      'zh-tw' => Language.traditionalChinese,
      'ja' => Language.japanese,
      'ko' => Language.korean,
      'th' => Language.thai,
      'ms' => Language.malay,
      _ => Language.english,
    },
    proxy: ref.watch(proxySettingsProvider).activeUrl,
    acceptInvalidCerts: false,
  ),
);

class PixivisionListing {
  const PixivisionListing(this.page, {this.loadingMore = false, this.error});
  final ArticlePage page;
  final bool loadingMore;
  final Object? error;
}

enum PixivisionSection { articles, ranking, recommended, tags }

@Riverpod(keepAlive: true)
class PixivisionBrowseSelection extends _$PixivisionBrowseSelection {
  @override
  ({String? url, PixivisionSection section}) build() => (url: null, section: PixivisionSection.articles);
  void select({required String? url, required PixivisionSection section}) => state = (url: url, section: section);
}

@riverpod
class PixivisionBrowse extends _$PixivisionBrowse {
  @override
  Future<PixivisionListing> build(String url) async {
    final retention = ref.keepAlive();
    Timer? expiry;
    ref.onCancel(() => expiry = Timer(const Duration(minutes: 10), retention.close));
    ref.onResume(() => expiry?.cancel());
    ref.onDispose(() => expiry?.cancel());
    final language = Uri.parse(url).pathSegments.first;
    final api = await ref.watch(pixivisionApiProvider(language).future);
    return PixivisionListing(await api.getNextArticlePage(url: url));
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.loadingMore || current.page.nextUrl == null) return;
    final loading = PixivisionListing(current.page, loadingMore: true);
    state = AsyncData(loading);
    try {
      final api = await ref.read(pixivisionApiProvider(Uri.parse(url).pathSegments.first).future);
      final next = await api.getNextArticlePage(url: current.page.nextUrl!);
      if (!ref.mounted || !identical(state.asData?.value, loading)) return;
      final articles = {for (final item in current.page.articles) item.id: item};
      for (final item in next.articles) {
        articles[item.id] = item;
      }
      final old = current.page;
      state = AsyncData(
        PixivisionListing(
          ArticlePage(
            url: old.url,
            title: old.title,
            description: old.description,
            articles: articles.values.toList(growable: false),
            nextUrl: next.nextUrl == current.page.nextUrl || articles.length == current.page.articles.length ? null : next.nextUrl,
            previousUrl: old.previousUrl,
            monthlyRanking: old.monthlyRanking,
            recommended: old.recommended,
            categories: old.categories,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && identical(state.asData?.value, loading)) state = AsyncData(PixivisionListing(current.page, error: error));
    }
  }
}

class PixivisionDocument {
  const PixivisionDocument({required this.article, required this.imageRatios});
  final Article article;
  final Map<String, double> imageRatios;
}

@riverpod
Future<PixivisionDocument> pixivisionArticle(Ref ref, String url) async {
  final api = await ref.watch(pixivisionApiProvider(Uri.parse(url).pathSegments.first).future);
  final article = await api.getArticleByUrl(url: url);
  return PixivisionDocument(article: article, imageRatios: pixivisionKnownImageRatios(article));
}

@riverpod
Future<TagDirectory> pixivisionTags(Ref ref, String language) async => (await ref.watch(pixivisionApiProvider(language).future)).getTagDirectory();

/// Fetches one listing page of Pixivision by its address; sample data answers
/// its own.
final pixivisionPageLoaderProvider = Provider<Future<ArticlePage> Function(String url)>(
  (ref) => (url) async => (await ref.read(pixivisionApiProvider(Uri.parse(url).pathSegments.first).future)).getNextArticlePage(url: url),
);

/// The articles one section of a listing shows: the latest (or a category's,
/// or a search's) page by page from the next link; the monthly ranking and
/// the recommendations of the page in one go. An article another page
/// already brought is not shown twice.
class PixivisionArticleListSource extends FrostCursorListSource<ArticleSummary, ArticlePage> {
  PixivisionArticleListSource({required this.url, required this.section, required this.load});

  final String url;
  final PixivisionSection section;
  final Future<ArticlePage> Function(String url) load;
  final _seen = <int>{};
  final _visited = <String>{};

  @override
  Future<ArticlePage> loadFirstPage() {
    _seen.clear();
    _visited
      ..clear()
      ..add(url);
    return load(url);
  }

  @override
  Future<ArticlePage> loadNextPage(String nextUrl) {
    _visited.add(nextUrl);
    return load(nextUrl);
  }

  /// Only the latest pages on; a link back to a page already read ends it.
  @override
  String? nextUrlFromPage(ArticlePage page) => switch (page.nextUrl) {
    final next? when section == PixivisionSection.articles && !_visited.contains(next) => next,
    _ => null,
  };

  @override
  List<ArticleSummary> itemsFromPage(ArticlePage page) => [
    for (final article in switch (section) {
      PixivisionSection.ranking => page.monthlyRanking,
      PixivisionSection.recommended => page.recommended,
      _ => page.articles,
    })
      if (_seen.add(article.id)) article,
  ];
}

/// The list of [PixivisionArticleListSource] for a listing address and section.
final pixivisionArticlesProvider = Provider.autoDispose.family<PixivisionArticleListSource, (String, PixivisionSection)>((ref, key) {
  final source = PixivisionArticleListSource(url: key.$1, section: key.$2, load: ref.watch(pixivisionPageLoaderProvider));
  ref.onDispose(source.dispose);
  return source;
});
