import 'dart:async';

import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/shared/shared.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/enums.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'illust_detail_logic.g.dart';

class IllustDetailArgs {
  const IllustDetailArgs({this.illustId, this.illust}) : assert(illustId != null || illust != null);

  final int? illustId;
  final Illust? illust;

  int get resolvedIllustId {
    final illust = this.illust;
    if (illust != null) {
      return illust.id;
    }

    final illustId = this.illustId;
    if (illustId == null) {
      throw ArgumentError('Either illustId or illust must be provided.');
    }

    return illustId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is IllustDetailArgs && other.resolvedIllustId == resolvedIllustId;
  }

  @override
  int get hashCode => resolvedIllustId.hashCode;
}

@riverpod
class IllustDetail extends _$IllustDetail {
  @override
  FutureOr<Illust> build(IllustDetailArgs args) async {
    final illust = args.illust;
    if (illust != null) {
      return illust;
    }

    final detail = await pixivApi.getIllustDetail(illustId: args.resolvedIllustId);
    return detail.illust;
  }

  Future<void> reload() async {
    state = const AsyncLoading<Illust>();
    state = await AsyncValue.guard(() async {
      final detail = await pixivApi.getIllustDetail(illustId: args.resolvedIllustId);
      return detail.illust;
    });
  }
}

@Riverpod(keepAlive: true)
class IllustComments extends _$IllustComments {
  @override
  Future<CommentPageResult> build(int illustId) {
    return pixivApi.getIllustCommentPage(illustId: illustId);
  }

  Future<void> reload() async {
    state = const AsyncLoading<CommentPageResult>();
    state = await AsyncValue.guard(() => pixivApi.getIllustCommentPage(illustId: illustId));
  }
}

@Riverpod(keepAlive: true)
class IllustUserWorks extends _$IllustUserWorks {
  @override
  Future<IllustPageResult> build(int userId) {
    return pixivApi.getUserIllustPage(userId: userId, illustType: IllustType.illust);
  }

  Future<void> reload() async {
    state = const AsyncLoading<IllustPageResult>();
    state = await AsyncValue.guard(() => pixivApi.getUserIllustPage(userId: userId, illustType: IllustType.illust));
  }
}

@Riverpod(keepAlive: true)
class IllustRelatedWorks extends _$IllustRelatedWorks {
  @override
  IllustRelatedListSource build(int illustId) {
    final source = IllustRelatedListSource(illustId: illustId);
    ref.onDispose(source.dispose);
    return source;
  }
}

class IllustRelatedListSource extends NextUrlListSource<Illust, IllustPageResult> {
  IllustRelatedListSource({required this.illustId});

  final int illustId;

  @override
  Future<IllustPageResult> loadFirstPage() {
    return pixivApi.getIllustRelatedPage(illustId: illustId);
  }

  @override
  Future<IllustPageResult> loadNextPage(String nextUrl) {
    return pixivApi.getNextIllustPage(url: nextUrl);
  }

  @override
  String? nextUrlFromPage(IllustPageResult page) {
    return page.nextUrl;
  }

  @override
  List<Illust> itemsFromPage(IllustPageResult page) {
    return page.illusts;
  }
}
