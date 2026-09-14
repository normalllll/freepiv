import 'dart:async';
import 'article_images.dart';
import 'package:freepiv/core/media/logic.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freepiv/core/services/app_settings_providers.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixivision.dart';

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
  final transport = ref.watch(rustMediaTransportProvider);
  final api = await ref.watch(pixivisionApiProvider(Uri.parse(url).pathSegments.first).future);
  final article = await api.getArticleByUrl(url: url);
  if (!ref.mounted) throw StateError('Article preparation cancelled');
  final ratios = await preparePixivisionImages(ref, article, transport);
  return PixivisionDocument(article: article, imageRatios: ratios);
}

@riverpod
Future<TagDirectory> pixivisionTags(Ref ref, String language) async => (await ref.watch(pixivisionApiProvider(language).future)).getTagDirectory();
