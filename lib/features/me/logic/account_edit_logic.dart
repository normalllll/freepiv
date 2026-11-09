import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_edit_logic.g.dart';

/// The account's details as Pixiv holds them now. Both edit forms replace
/// everything they cover, so they never start from a kept copy.
@riverpod
Future<UserDetailResult> editableUserDetail(Ref ref, int userId) => pixivApi.getUserDetail(userId: userId);

@riverpod
Future<ProfilePresets> profilePresets(Ref ref) async => (await pixivApi.getProfilePresets()).profilePresets;

/// Whether Pixiv shows the account AI-generated works.
@riverpod
class AiShowSetting extends _$AiShowSetting {
  @override
  Future<bool> build(String accountId) async => (await pixivApi.getAiShowSettings()).showAi;

  Future<void> set(bool show) async {
    final previous = state;
    if (pixivAccountNotifier.value?.user.id != accountId) return;
    state = AsyncData(show);
    try {
      await pixivApi.postAiShowSettings(mode: show ? SearchAiMode.show_ : SearchAiMode.hide_);
    } catch (_) {
      if (ref.mounted && pixivAccountNotifier.value?.user.id == accountId) state = previous;
      rethrow;
    }
  }
}
