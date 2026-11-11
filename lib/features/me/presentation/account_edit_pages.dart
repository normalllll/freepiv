import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freepiv/app/frost_config.dart';
import 'package:freepiv/core/services/pixiv_service.dart';
import 'package:freepiv/features/me/logic/account_edit_logic.dart';
import 'package:freepiv/features/me/logic/profile_image_logic.dart';
import 'package:freepiv/features/me/presentation/profile_avatar_field.dart';
import 'package:freepiv/features/user_detail/logic/user_detail_logic.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/error.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/api.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/models.dart';
import 'package:freepiv/src/rust/third_party/pixiv_rs/pixiv/responses.dart';
import 'package:freepiv/ui/compositions/content_rows.dart';
import 'package:freepiv/ui/compositions/page_error.dart';
import 'package:freepiv/ui/custom/avatar_cropper.dart';
import 'package:frost_ui/frost_ui.dart';

/// The chrome of an account form: its title and Save, and a question before
/// leaving with changes unsaved.
class _AccountForm extends StatefulWidget {
  const _AccountForm({required this.title, required this.dirty, required this.busy, required this.onSave, required this.fields, this.blocked = false});

  final String title;
  final bool dirty;
  final bool busy;

  /// The page takes no input and cannot be left while this is true.
  final bool blocked;
  final VoidCallback? onSave;
  final Widget fields;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  static const _saveMinWidth = 72.0;

  bool _discarded = false;

  bool get _canSave => widget.dirty && !widget.busy && !widget.blocked;

  Future<void> _confirmLeave() async {
    final t = context.t.profileEdit;
    final discard = await showFrostConfirm(
      context: context,
      title: t.discardTitle,
      message: t.discardMessage,
      confirmLabel: t.discard,
      cancelLabel: t.keepEditing,
    );
    if (!mounted || !discard) return;
    setState(() => _discarded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.blocked && (!widget.dirty || _discarded),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !widget.blocked && widget.dirty) unawaited(_confirmLeave());
    },
    child: ExcludeFocus(
      excluding: widget.blocked,
      child: AbsorbPointer(absorbing: widget.blocked, child: _page(context)),
    ),
  );

  Widget _page(BuildContext context) => FrostPinnedChrome(
    chrome: FrostContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      child: FrostPageHeader(
        title: FrostText(widget.title),
        actions: [
          FrostToolbarItem.custom(
            minWidth: MediaQuery.textScalerOf(context).scale(_saveMinWidth),
            plated: true,
            overflowEntry: FrostMenuAction(context.t.profileEdit.save, onSelected: _canSave ? widget.onSave : null),
            builder: (context) => FrostButton.prominent(label: context.t.profileEdit.save, onPressed: _canSave ? widget.onSave : null),
          ),
        ],
      ),
    ),
    body: FrostLoadingScrollView(
      slivers: [
        const FrostChromeSpacer(),
        FrostSliverContentColumn(
          maxWidth: FrostMetrics.readingMaxWidth,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: FrostGap.section),
              child: widget.fields,
            ),
          ),
        ),
      ],
    ),
  );
}

/// What both forms show until there is something to edit.
class _AccountFormLoading extends StatelessWidget {
  const _AccountFormLoading({required this.title, this.error, this.onRetry, this.signedOut = false});

  final String title;
  final Object? error;
  final VoidCallback? onRetry;
  final bool signedOut;

  @override
  Widget build(BuildContext context) => FrostPinnedChrome(
    chrome: FrostContentColumn(
      maxWidth: FrostMetrics.readingMaxWidth,
      child: FrostPageHeader(title: FrostText(title)),
    ),
    body: switch ((error, onRetry)) {
      _ when signedOut => FrostEmptyState(
        icon: PivIcons.user,
        title: context.t.settings.account.notSignedIn,
        message: context.t.settings.account.signedOutSubtitle,
      ),
      (final error?, final onRetry?) => AppPageError.fromError(error: error, onRetry: onRetry),
      _ => FrostLoadingScrollView(
        slivers: [
          const FrostChromeSpacer(),
          FrostSliverContentColumn(
            maxWidth: FrostMetrics.readingMaxWidth,
            sliver: const SliverToBoxAdapter(child: AppRowsSkeleton(subtitle: false)),
          ),
        ],
      ),
    },
  );
}

/// Pixiv's three answers for gender, named as it names them.
enum _Gender {
  unknown,
  male,
  female;

  static _Gender of(String value) => values.where((gender) => gender.name == value).firstOrNull ?? unknown;
}

/// Whichever form it is, the page needs the signed-in account first.
int? get _accountUserId => int.tryParse(pixivAccountNotifier.value?.user.id ?? '');

class ProfileEditPage extends ConsumerWidget {
  const ProfileEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.profileEdit;
    final userId = _accountUserId;
    if (userId == null) return _AccountFormLoading(title: t.title, signedOut: true);
    final detail = ref.watch(editableUserDetailProvider(userId));
    final presets = ref.watch(profilePresetsProvider);
    void retry() {
      ref.invalidate(editableUserDetailProvider(userId));
      ref.invalidate(profilePresetsProvider);
    }

    return switch ((detail, presets)) {
      (AsyncValue(value: final detail?), AsyncValue(value: final presets?)) => _ProfileForm(userId: userId, detail: detail, presets: presets),
      (AsyncValue(error: final error?), _) || (_, AsyncValue(error: final error?)) => _AccountFormLoading(title: t.title, error: error, onRetry: retry),
      _ => _AccountFormLoading(title: t.title),
    };
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.userId, required this.detail, required this.presets});

  final int userId;
  final UserDetailResult detail;
  final ProfilePresets presets;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

/// How far choosing a new profile image has got.
enum _AvatarStep {
  /// Nothing is under way.
  idle,

  /// The file picker or the cropper is open and takes the input itself.
  choosing,

  /// The image is being read, decoded or prepared; the page waits for it.
  working,
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = FrostFormController();
  late final String? _account = pixivAccountNotifier.value?.user.id;
  late final _name = TextEditingController(text: widget.detail.user.name);
  late final _website = TextEditingController(text: widget.detail.profile.webpage ?? '');
  late final _twitter = TextEditingController(text: widget.detail.profile.twitterAccount ?? '');
  late final _bio = TextEditingController(text: widget.detail.user.comment ?? '');
  late _Gender _gender = _Gender.of(widget.detail.profile.gender);
  late String _birthday = widget.detail.profile.birth;
  late int _address = widget.detail.profile.addressId;
  late String _country = widget.detail.profile.countryCode;
  late int _job = widget.detail.profile.jobId;

  String? _nameError;
  bool _busy = false;
  bool _saved = false;

  /// The cropped JPEG that replaces the profile image on saving.
  Uint8List? _avatar;
  String? _avatarError;
  _AvatarStep _avatarStep = _AvatarStep.idle;

  bool get _global => widget.presets.addresses.where((address) => address.id == _address).firstOrNull?.isGlobal ?? false;

  bool get _dirty {
    if (_saved) return false;
    final profile = widget.detail.profile;
    return _avatar != null ||
        _name.text != widget.detail.user.name ||
        _website.text != (profile.webpage ?? '') ||
        _twitter.text != (profile.twitterAccount ?? '') ||
        _bio.text != (widget.detail.user.comment ?? '') ||
        _gender != _Gender.of(profile.gender) ||
        _birthday != profile.birth ||
        _address != profile.addressId ||
        _country != profile.countryCode ||
        _job != profile.jobId;
  }

  @override
  void dispose() {
    _form.dispose();
    _name.dispose();
    _website.dispose();
    _twitter.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  /// Pixiv's lists have no entry for "nothing chosen", yet an account can be
  /// on it: the value it came with stays selectable, under a name.
  List<FrostPickerOption<T>> _presetOptions<T>(T loaded, List<FrostPickerOption<T>> presets) => [
    if (!presets.any((option) => option.value == loaded)) FrostPickerOption(value: loaded, label: context.t.profileEdit.notSet),
    ...presets,
  ];

  static String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Picks an image, asks which part of it to keep and turns that into the
  /// JPEG that is uploaded when the form is saved.
  Future<void> _pickAvatar() async {
    if (_avatarStep != _AvatarStep.idle || _busy) return;
    final t = context.t.profileEdit;
    void step(_AvatarStep next) {
      if (mounted) setState(() => _avatarStep = next);
    }

    step(_AvatarStep.choosing);
    try {
      final PickedProfileImage? picked;
      try {
        picked = await profileImagePicker();
      } catch (_) {
        if (mounted) FrostToast.error(t.avatarUnreadable);
        return;
      }
      if (picked == null || !mounted) return;
      if ((picked.size ?? 0) > profileImageSourceLimit) {
        FrostToast.error(t.avatarTooLarge);
        return;
      }
      step(_AvatarStep.working);
      final Uint8List source;
      try {
        source = await picked.read();
      } catch (_) {
        if (mounted) FrostToast.error(t.avatarUnreadable);
        return;
      }
      if (!mounted) return;
      if (source.length > profileImageSourceLimit) {
        FrostToast.error(t.avatarTooLarge);
        return;
      }
      final image = await decodeProfileImageSource(source).then<ui.Image?>((image) => image, onError: (_) => null);
      if (image == null) {
        if (mounted) FrostToast.error(t.avatarUnreadable);
        return;
      }
      try {
        if (!mounted) return;
        step(_AvatarStep.choosing);
        final crop = await showAvatarCropper(context, image: image);
        if (crop == null || !mounted) return;
        step(_AvatarStep.working);
        final jpeg = await profileImagePreparer(source, crop);
        if (!mounted) return;
        setState(() {
          _avatar = jpeg;
          _avatarError = null;
        });
      } catch (error) {
        if (mounted) toastErrorWithCause(t.avatarPrepareFailed, error);
      } finally {
        image.dispose();
      }
    } finally {
      step(_AvatarStep.idle);
    }
  }

  void _undoAvatar() => setState(() {
    _avatar = null;
    _avatarError = null;
  });

  /// The profile image Pixiv holds now, as the account stores it. Pixiv gives
  /// one size, which serves for each of the account's. Null when it cannot be
  /// read: the old one stays until the account is next signed in.
  Future<LocalUserProfileImageUrls?> _currentAvatarUrls() async {
    try {
      final url = (await pixivApi.getUserDetail(userId: widget.userId)).user.profileImageUrls.medium;
      return url.isEmpty ? null : LocalUserProfileImageUrls(px16X16: url, px50X50: url, px170X170: url);
    } catch (_) {
      return null;
    }
  }

  /// Pixiv's complaint about the uploaded image, if [error] is one.
  Future<String?> _avatarComplaint(Object error) async {
    if (_avatar == null || error is! PixivError) return null;
    try {
      return await error.fieldMessage(field: 'profile_image');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _save() async {
    final t = context.t.profileEdit;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = t.nameRequired);
      return false;
    }
    final avatar = _avatar;
    setState(() {
      _nameError = null;
      _avatarError = null;
      _busy = true;
    });
    try {
      await pixivApi.postUserProfileEdit(
        edit: UserProfileEdit(
          userName: name,
          gender: _gender.name,
          addressId: _address,
          countryCode: _global && _country.isNotEmpty ? _country : null,
          jobId: _job,
          webpage: _website.text.trim(),
          twitter: _twitter.text.trim(),
          comment: _bio.text,
          birthday: _birthday,
          profileImage: avatar == null ? null : ProfileImageUpload(bytes: avatar, fileName: profileImageFileName, mime: profileImageMime),
        ),
      );
      final avatarUrls = avatar == null ? null : await _currentAvatarUrls();
      if (!mounted || pixivAccountNotifier.value?.user.id != _account) return false;
      ref.invalidate(editableUserDetailProvider(widget.userId));
      ref.invalidate(userDetailProvider(UserDetailArgs(userId: widget.userId)));
      // The account card and settings read the stored account, not the profile.
      // From the API's copy: it holds the access token as last refreshed.
      if (pixivApi.account() case final account?) {
        updatePixivAccount(
          account.copyWith(
            user: account.user.copyWith(name: name, profileImageUrls: avatarUrls ?? account.user.profileImageUrls),
          ),
        );
      }
      FrostToast.success(t.saved);
      setState(() => _saved = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(Navigator.of(context).maybePop());
      });
      return true;
    } catch (error) {
      if (mounted && pixivAccountNotifier.value?.user.id == _account) {
        final complaint = await _avatarComplaint(error);
        if (!mounted) return false;
        if (complaint != null) {
          setState(() => _avatarError = complaint);
        } else {
          toastErrorWithCause(t.failed, error);
        }
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.profileEdit;
    final presets = widget.presets;
    return _AccountForm(
      title: t.title,
      dirty: _dirty,
      busy: _busy,
      blocked: _avatarStep == _AvatarStep.working,
      onSave: () => unawaited(_form.submit()),
      fields: FrostForm(
        controller: _form,
        onSubmit: _save,
        children: [
          ProfileAvatarField(
            name: widget.detail.user.name,
            userId: widget.userId,
            imageUrl: widget.detail.user.profileImageUrls.medium,
            replacement: _avatar,
            enabled: !_busy && _avatarStep == _AvatarStep.idle,
            working: _avatarStep == _AvatarStep.working,
            error: _avatarError,
            onPick: () => unawaited(_pickAvatar()),
            onUndo: _undoAvatar,
          ),
          FrostTextField(controller: _name, label: t.name, error: _nameError, onChanged: _changed),
          FrostPicker<_Gender>.menu(
            label: t.gender,
            value: _gender,
            onChanged: (gender) => setState(() => _gender = gender),
            options: [
              FrostPickerOption(value: _Gender.unknown, label: t.genderUnknown),
              FrostPickerOption(value: _Gender.male, label: t.genderMale),
              FrostPickerOption(value: _Gender.female, label: t.genderFemale),
            ],
          ),
          FrostDatePicker(
            label: t.birthday,
            placeholder: t.notSet,
            showsYear: true,
            clearable: true,
            value: DateTime.tryParse(_birthday),
            lastDate: DateTime.now(),
            onChanged: (date) => setState(() => _birthday = date == null ? '' : _dateText(date)),
          ),
          FrostPicker<int>.menu(
            label: t.region,
            value: _address,
            onChanged: (address) => setState(() => _address = address),
            options: _presetOptions(widget.detail.profile.addressId, [
              for (final address in presets.addresses) FrostPickerOption(value: address.id, label: address.name),
            ]),
          ),
          if (_global)
            FrostPicker<String>.menu(
              label: t.country,
              value: _country,
              onChanged: (country) => setState(() => _country = country),
              options: _presetOptions(widget.detail.profile.countryCode, [
                for (final country in presets.countries) FrostPickerOption(value: country.code, label: country.name),
              ]),
            ),
          FrostPicker<int>.menu(
            label: t.job,
            value: _job,
            onChanged: (job) => setState(() => _job = job),
            options: _presetOptions(widget.detail.profile.jobId, [for (final job in presets.jobs) FrostPickerOption(value: job.id, label: job.name)]),
          ),
          FrostTextField(controller: _website, label: t.website, keyboardType: TextInputType.url, onChanged: _changed),
          FrostTextField(controller: _twitter, label: t.twitter, onChanged: _changed),
          FrostTextField(controller: _bio, label: t.bio, minLines: 4, maxLines: 10, onChanged: _changed),
        ],
      ),
    );
  }
}

class WorkspaceEditPage extends ConsumerWidget {
  const WorkspaceEditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.workspaceEdit;
    final userId = _accountUserId;
    if (userId == null) return _AccountFormLoading(title: t.title, signedOut: true);
    final provider = editableUserDetailProvider(userId);
    return switch (ref.watch(provider)) {
      AsyncValue(value: final detail?) => _WorkspaceForm(userId: userId, workspace: detail.workspace),
      AsyncValue(error: final error?) => _AccountFormLoading(title: t.title, error: error, onRetry: () => ref.invalidate(provider)),
      _ => _AccountFormLoading(title: t.title),
    };
  }
}

class _WorkspaceForm extends ConsumerStatefulWidget {
  const _WorkspaceForm({required this.userId, required this.workspace});

  final int userId;
  final UserWorkspace workspace;

  @override
  ConsumerState<_WorkspaceForm> createState() => _WorkspaceFormState();
}

class _WorkspaceFormState extends ConsumerState<_WorkspaceForm> {
  final _form = FrostFormController();
  late final String? _account = pixivAccountNotifier.value?.user.id;
  late final _pc = TextEditingController(text: widget.workspace.pc);
  late final _monitor = TextEditingController(text: widget.workspace.monitor);
  late final _tool = TextEditingController(text: widget.workspace.tool);
  late final _scanner = TextEditingController(text: widget.workspace.scanner);
  late final _tablet = TextEditingController(text: widget.workspace.tablet);
  late final _mouse = TextEditingController(text: widget.workspace.mouse);
  late final _printer = TextEditingController(text: widget.workspace.printer);
  late final _desktop = TextEditingController(text: widget.workspace.desktop);
  late final _music = TextEditingController(text: widget.workspace.music);
  late final _desk = TextEditingController(text: widget.workspace.desk);
  late final _chair = TextEditingController(text: widget.workspace.chair);
  late final _comment = TextEditingController(text: widget.workspace.comment);

  late final _fields = [
    (_pc, widget.workspace.pc),
    (_monitor, widget.workspace.monitor),
    (_tool, widget.workspace.tool),
    (_scanner, widget.workspace.scanner),
    (_tablet, widget.workspace.tablet),
    (_mouse, widget.workspace.mouse),
    (_printer, widget.workspace.printer),
    (_desktop, widget.workspace.desktop),
    (_music, widget.workspace.music),
    (_desk, widget.workspace.desk),
    (_chair, widget.workspace.chair),
    (_comment, widget.workspace.comment),
  ];

  bool _busy = false;
  bool _saved = false;

  bool get _dirty => !_saved && _fields.any((field) => field.$1.text != field.$2);

  @override
  void dispose() {
    _form.dispose();
    for (final field in _fields) {
      field.$1.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    final t = context.t.profileEdit;
    setState(() => _busy = true);
    try {
      await pixivApi.postUserWorkspaceEdit(
        edit: UserWorkspaceEdit(
          pc: _pc.text,
          monitor: _monitor.text,
          tool: _tool.text,
          scanner: _scanner.text,
          tablet: _tablet.text,
          mouse: _mouse.text,
          printer: _printer.text,
          desktop: _desktop.text,
          music: _music.text,
          desk: _desk.text,
          chair: _chair.text,
          comment: _comment.text,
        ),
      );
      if (!mounted || pixivAccountNotifier.value?.user.id != _account) return false;
      ref.invalidate(editableUserDetailProvider(widget.userId));
      ref.invalidate(userDetailProvider(UserDetailArgs(userId: widget.userId)));
      FrostToast.success(t.saved);
      setState(() => _saved = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(Navigator.of(context).maybePop());
      });
      return true;
    } catch (error) {
      if (mounted && pixivAccountNotifier.value?.user.id == _account) toastErrorWithCause(t.failed, error);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.workspaceEdit;
    Widget field(TextEditingController controller, String label) => FrostTextField(controller: controller, label: label, onChanged: (_) => setState(() {}));
    return _AccountForm(
      title: t.title,
      dirty: _dirty,
      busy: _busy,
      onSave: () => unawaited(_form.submit()),
      fields: FrostForm(
        controller: _form,
        onSubmit: _save,
        children: [
          field(_pc, t.pc),
          field(_monitor, t.monitor),
          field(_tool, t.tool),
          field(_scanner, t.scanner),
          field(_tablet, t.tablet),
          field(_mouse, t.mouse),
          field(_printer, t.printer),
          field(_desktop, t.desktop),
          field(_music, t.music),
          field(_desk, t.desk),
          field(_chair, t.chair),
          FrostTextField(controller: _comment, label: t.comment, minLines: 3, maxLines: 8, onChanged: (_) => setState(() {})),
        ],
      ),
    );
  }
}
