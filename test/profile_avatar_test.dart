import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freepiv/core/services/app_settings.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/dev/sample_data.dart';
import 'package:freepiv/features/me/logic/profile_image_logic.dart';
import 'package:freepiv/features/me/presentation/account_edit_pages.dart';
import 'package:freepiv/features/me/presentation/profile_avatar_field.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/custom/avatar_cropper.dart';
import 'package:frost_ui/frost_ui.dart';

import 'support/pilot_harness.dart';

const _newAvatarUrl = 'https://i.pximg.test/user-profile/new_170.jpg';

/// Pixiv refusing the upload, with a message for the image.
class _ImageRefused implements PixivError {
  @override
  Future<String?> fieldMessage({required String field}) async => field == 'profile_image' ? 'The image is too large.' : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('unexpected call: ${invocation.memberName}');
}

class _Api implements PixivApi {
  UserProfileEdit? edit;
  Object? failure;
  int detailReads = 0;

  @override
  Future<String> postUserProfileEdit({required UserProfileEdit edit}) async {
    if (failure case final failure?) throw failure;
    this.edit = edit;
    return '';
  }

  @override
  Future<UserDetailResult> getUserDetail({required int userId}) async {
    detailReads++;
    return UserDetailResult(
      user: UserInfo(
        id: userId,
        name: 'Name',
        account: 'name',
        profileImageUrls: const ProfileImageUrls(medium: _newAvatarUrl),
        comment: 'Bio',
        isFollowed: false,
      ),
      profile: sampleUserDetail.profile,
      profilePublicity: sampleUserDetail.profilePublicity,
      workspace: sampleUserDetail.workspace,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #setAccount) return null;
    if (invocation.memberName == #account) return sampleAccount.copyWith(accessToken: 'refreshed by the client');
    throw StateError('unexpected request: ${invocation.memberName}');
  }
}

late _Api _api;
late Uint8List _picture;
final _crops = <AvatarCrop>[];
var _pickedBytes = Uint8List(0);

Future<Uint8List> _png(WidgetTester tester, int width, int height) async => (await tester.runAsync(() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = const Color(0xFFCC6633));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}))!;

Future<void> _open(WidgetTester tester) async {
  _picture = await _png(tester, 600, 400);
  _pickedBytes = _picture;
  await mountPilotPage(tester, const ProfileEditPage());
}

/// Real time for the image codec, then frames for the dialog or the page.
Future<void> _later(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await settlePilot(tester, frames: 4);
}

/// Past the wait before a loading state is shown, with the image codec given
/// real time to finish.
Future<void> _waitPastLoadingDelay(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// The avatar field's own activity dots; buttons hold dots of their own.
Finder get _avatarDots => find.descendant(of: find.byType(ProfileAvatarField), matching: find.byType(FrostActivityIndicator));

/// Whether the profile form lets its page be popped.
bool _pageCanPop(WidgetTester tester) => tester
    .widget<PopScope<Object?>>(find.ancestor(of: find.byType(ProfileAvatarField), matching: find.byWidgetPredicate((widget) => widget is PopScope)).first)
    .canPop;

Future<void> _chooseAndCrop(WidgetTester tester) async {
  await tester.tap(find.text(t.profileEdit.avatarChange));
  await _later(tester);
  expect(find.byType(AvatarCropViewport), findsOneWidget);
  await tester.tap(find.text(t.profileEdit.cropDone));
  await _later(tester);
}

Finder get _saveButton => find.ancestor(of: find.text(t.profileEdit.save), matching: find.byType(FrostButton));

bool _canSave(WidgetTester tester) => tester.widget<FrostButton>(_saveButton).onPressed != null;

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text(t.profileEdit.save));
  await _later(tester);
}

void main() {
  setUp(() {
    pixivApi = _api = _Api();
    _crops.clear();
    final picker = profileImagePicker, preparer = profileImagePreparer;
    profileImagePicker = () async => PickedProfileImage.bytes(_pickedBytes);
    profileImagePreparer = (source, crop) async {
      _crops.add(crop);
      return _picture;
    };
    addTearDown(() {
      profileImagePicker = picker;
      profileImagePreparer = preparer;
    });
  });

  group('the profile image field', () {
    testWidgets('is the first field, with its button and hint', (tester) async {
      await _open(tester);
      expect(find.text(t.profileEdit.avatar), findsOneWidget);
      expect(find.text(t.profileEdit.avatarChange), findsOneWidget);
      expect(find.text(t.profileEdit.avatarHint), findsOneWidget);
      expect(tester.getTopLeft(find.text(t.profileEdit.avatar)).dy, lessThan(tester.getTopLeft(find.byType(FrostTextField).first).dy));
      expectNoLayoutErrors(tester);
    });

    testWidgets('a crop is shown as waiting to be saved, and Save becomes available', (tester) async {
      await _open(tester);
      expect(_canSave(tester), isFalse);
      await _chooseAndCrop(tester);
      expect(_crops, hasLength(1));
      expect(_crops.single, const AvatarCrop(x: 100, y: 0, side: 400));
      expect(find.text(t.profileEdit.avatarChanged), findsOneWidget);
      expect(find.text(t.profileEdit.avatarPickAgain), findsOneWidget);
      expect(find.text(t.profileEdit.avatarUndo), findsOneWidget);
      expect(_canSave(tester), isTrue, reason: 'only the profile image changed');
      expectNoLayoutErrors(tester);
    });

    testWidgets('undoing restores the original and sends no image', (tester) async {
      await _open(tester);
      await _chooseAndCrop(tester);
      await tester.tap(find.text(t.profileEdit.avatarUndo));
      await settlePilot(tester, frames: 3);
      expect(find.text(t.profileEdit.avatarHint), findsOneWidget);
      expect(find.text(t.profileEdit.avatarChange), findsOneWidget);
      expect(_canSave(tester), isFalse);
      await _save(tester);
      expect(_api.edit, isNull);
    });

    testWidgets('the cropper dialog is as tall as its content, with the viewport as large as fits', (tester) async {
      await _open(tester);
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      final viewport = tester.getSize(find.byType(AvatarCropViewport));
      // From the title down to the buttons.
      final content = tester.getBottomLeft(find.text(t.profileEdit.cropDone)).dy - tester.getTopLeft(find.text(t.profileEdit.cropTitle)).dy;
      expect(viewport.width, viewport.height);
      expect(viewport.width, greaterThan(320), reason: 'the dialog is wider than the old fixed viewport');
      expect(content - viewport.height, lessThan(200), reason: 'title, slider and buttons, and no empty bands');
      expectNoLayoutErrors(tester);
    });

    testWidgets('cancelling the cropper changes nothing', (tester) async {
      await _open(tester);
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      await tester.tap(find.text(t.common.cancel));
      await _later(tester);
      expect(_crops, isEmpty);
      expect(find.text(t.profileEdit.avatarHint), findsOneWidget);
      expect(_canSave(tester), isFalse);
    });

    testWidgets('a source over 30 MB is turned down before cropping', (tester) async {
      await _open(tester);
      _pickedBytes = Uint8List(profileImageSourceLimit + 1);
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      expect(find.byType(AvatarCropViewport), findsNothing);
      expect(find.text(t.profileEdit.avatarTooLarge), findsOneWidget);
      expect(_crops, isEmpty);
    });

    testWidgets('a source that is not an image is turned down before cropping', (tester) async {
      await _open(tester);
      _pickedBytes = Uint8List.fromList(List.filled(64, 7));
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      expect(find.byType(AvatarCropViewport), findsNothing);
      expect(find.text(t.profileEdit.avatarUnreadable), findsOneWidget);
    });

    testWidgets('a size known to be over 30 MB is turned down without reading the file', (tester) async {
      await _open(tester);
      var reads = 0;
      profileImagePicker = () async => PickedProfileImage(
        size: profileImageSourceLimit + 1,
        read: () async {
          reads++;
          return _picture;
        },
      );
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      expect(reads, 0);
      expect(find.byType(AvatarCropViewport), findsNothing);
      expect(find.text(t.profileEdit.avatarTooLarge), findsOneWidget);
    });

    testWidgets('while the picked file is read the field shows it is working', (tester) async {
      await _open(tester);
      final read = Completer<Uint8List>();
      profileImagePicker = () async => PickedProfileImage(size: null, read: () => read.future);
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _waitPastLoadingDelay(tester);
      expect(_avatarDots, findsOneWidget);
      expect(find.text(t.profileEdit.avatarWorking), findsOneWidget);
      read.complete(_picture);
      await _later(tester);
      expect(find.byType(AvatarCropViewport), findsOneWidget, reason: 'the cropper opens once the file is read');
      expect(find.text(t.profileEdit.avatarWorking), findsNothing);
    });

    testWidgets('while the crop is prepared the field shows it is working and the page takes no input', (tester) async {
      await _open(tester);
      final prepared = Completer<Uint8List>();
      profileImagePreparer = (source, crop) {
        _crops.add(crop);
        return prepared.future;
      };
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      await tester.tap(find.text(t.profileEdit.cropDone));
      await _waitPastLoadingDelay(tester);
      expect(_avatarDots, findsOneWidget);
      expect(find.text(t.profileEdit.avatarWorking), findsOneWidget);
      expect(find.text(t.profileEdit.avatarChange), findsNothing, reason: 'the dots stand in for the buttons');
      expect(_canSave(tester), isFalse);
      expect(_pageCanPop(tester), isFalse, reason: 'the page cannot be left while it works');

      await tester.tap(find.byType(EditableText).first, warnIfMissed: false);
      await tester.pump();
      expect(tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus, isFalse, reason: 'taps do not reach the fields');

      prepared.complete(_picture);
      await _later(tester);
      expect(find.text(t.profileEdit.avatarWorking), findsNothing);
      expect(find.text(t.profileEdit.avatarChanged), findsOneWidget);
      expect(_canSave(tester), isTrue);
      expect(_pageCanPop(tester), isFalse, reason: 'a changed form still asks before it is left');
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();
      expect(tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus, isTrue, reason: 'the fields take input again');
      expectNoLayoutErrors(tester);
    });

    testWidgets('on a phone the cropper is a page, and Done there keeps the crop', (tester) async {
      _picture = await _png(tester, 600, 400);
      _pickedBytes = _picture;
      // Narrow, but wide enough for the page header to show Done: the test font is wide.
      await mountPilotPage(tester, const ProfileEditPage(), size: const Size(560, 844));
      await tester.tap(find.text(t.profileEdit.avatarChange));
      await _later(tester);
      await settlePilot(tester);
      expect(find.byType(AvatarCropViewport), findsOneWidget);
      expect(find.byType(FrostDialog), findsNothing);
      await tester.tap(find.text(t.profileEdit.cropDone));
      await _later(tester);
      expect(_crops, hasLength(1));
      expect(find.text(t.profileEdit.avatarChanged), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  group('saving', () {
    testWidgets('the request carries the image only when it changed', (tester) async {
      await _open(tester);
      await tester.enterText(find.descendant(of: find.byType(FrostTextField).first, matching: find.byType(EditableText)), 'New name');
      await settlePilot(tester, frames: 2);
      await _save(tester);
      expect(_api.edit, isNotNull);
      expect(_api.edit!.profileImage, isNull);
      expect(_api.detailReads, 0, reason: 'no new profile image to read back');
    });

    testWidgets('the cropped image is sent as profile.jpg', (tester) async {
      await _open(tester);
      await _chooseAndCrop(tester);
      await _save(tester);
      final upload = _api.edit!.profileImage!;
      expect(upload.bytes, _picture);
      expect(upload.fileName, 'profile.jpg');
      expect(upload.mime, 'image/jpeg');
    });

    testWidgets('afterwards the account and its stored entry have the new image', (tester) async {
      await _open(tester);
      await _chooseAndCrop(tester);
      await _save(tester);
      expect(_api.detailReads, 1);
      final urls = pixivAccountNotifier.value!.user.profileImageUrls;
      expect(urls.px170X170, _newAvatarUrl);
      expect(urls.px50X50, _newAvatarUrl);
      expect(urls.px16X16, _newAvatarUrl);
      final stored = AppSettings.accounts.active!.session.user.profileImageUrls;
      expect(stored.px170X170, _newAvatarUrl);
      expect(AppSettings.accounts.active!.id, pixivAccountNotifier.value!.user.id);
    });

    testWidgets('Pixiv\'s complaint about the image shows on the field', (tester) async {
      await _open(tester);
      await _chooseAndCrop(tester);
      _api.failure = _ImageRefused();
      await _save(tester);
      expect(find.text('The image is too large.'), findsOneWidget);
      expect(find.byType(FrostInlineBanner), findsOneWidget);
      expect(_canSave(tester), isTrue, reason: 'the image is still waiting, to be changed or sent again');
      await tester.tap(find.text(t.profileEdit.avatarUndo));
      await settlePilot(tester, frames: 3);
      expect(find.text('The image is too large.'), findsNothing);
    });
  });
}
