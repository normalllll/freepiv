// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fanbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FanboxBlock {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FanboxBlock);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FanboxBlock()';
  }
}

/// @nodoc
class $FanboxBlockCopyWith<$Res> {
  $FanboxBlockCopyWith(FanboxBlock _, $Res Function(FanboxBlock) __);
}

/// Adds pattern-matching-related methods to [FanboxBlock].
extension FanboxBlockPatterns on FanboxBlock {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FanboxBlock_Paragraph value)? paragraph,
    TResult Function(FanboxBlock_Heading value)? heading,
    TResult Function(FanboxBlock_Image value)? image,
    TResult Function(FanboxBlock_File value)? file,
    TResult Function(FanboxBlock_Embed value)? embed,
    TResult Function(FanboxBlock_PostLink value)? postLink,
    TResult Function(FanboxBlock_Unknown value)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph() when paragraph != null:
        return paragraph(_that);
      case FanboxBlock_Heading() when heading != null:
        return heading(_that);
      case FanboxBlock_Image() when image != null:
        return image(_that);
      case FanboxBlock_File() when file != null:
        return file(_that);
      case FanboxBlock_Embed() when embed != null:
        return embed(_that);
      case FanboxBlock_PostLink() when postLink != null:
        return postLink(_that);
      case FanboxBlock_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FanboxBlock_Paragraph value) paragraph,
    required TResult Function(FanboxBlock_Heading value) heading,
    required TResult Function(FanboxBlock_Image value) image,
    required TResult Function(FanboxBlock_File value) file,
    required TResult Function(FanboxBlock_Embed value) embed,
    required TResult Function(FanboxBlock_PostLink value) postLink,
    required TResult Function(FanboxBlock_Unknown value) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph():
        return paragraph(_that);
      case FanboxBlock_Heading():
        return heading(_that);
      case FanboxBlock_Image():
        return image(_that);
      case FanboxBlock_File():
        return file(_that);
      case FanboxBlock_Embed():
        return embed(_that);
      case FanboxBlock_PostLink():
        return postLink(_that);
      case FanboxBlock_Unknown():
        return unknown(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FanboxBlock_Paragraph value)? paragraph,
    TResult? Function(FanboxBlock_Heading value)? heading,
    TResult? Function(FanboxBlock_Image value)? image,
    TResult? Function(FanboxBlock_File value)? file,
    TResult? Function(FanboxBlock_Embed value)? embed,
    TResult? Function(FanboxBlock_PostLink value)? postLink,
    TResult? Function(FanboxBlock_Unknown value)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph() when paragraph != null:
        return paragraph(_that);
      case FanboxBlock_Heading() when heading != null:
        return heading(_that);
      case FanboxBlock_Image() when image != null:
        return image(_that);
      case FanboxBlock_File() when file != null:
        return file(_that);
      case FanboxBlock_Embed() when embed != null:
        return embed(_that);
      case FanboxBlock_PostLink() when postLink != null:
        return postLink(_that);
      case FanboxBlock_Unknown() when unknown != null:
        return unknown(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text, List<FanboxTextSpan> spans)? paragraph,
    TResult Function(String text)? heading,
    TResult Function(FanboxImage image)? image,
    TResult Function(FanboxFile file)? file,
    TResult Function(String? url, String? html)? embed,
    TResult Function(String postId, String creatorId, String title)? postLink,
    TResult Function(String text, String rawJson)? unknown,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph() when paragraph != null:
        return paragraph(_that.text, _that.spans);
      case FanboxBlock_Heading() when heading != null:
        return heading(_that.text);
      case FanboxBlock_Image() when image != null:
        return image(_that.image);
      case FanboxBlock_File() when file != null:
        return file(_that.file);
      case FanboxBlock_Embed() when embed != null:
        return embed(_that.url, _that.html);
      case FanboxBlock_PostLink() when postLink != null:
        return postLink(_that.postId, _that.creatorId, _that.title);
      case FanboxBlock_Unknown() when unknown != null:
        return unknown(_that.text, _that.rawJson);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text, List<FanboxTextSpan> spans)
    paragraph,
    required TResult Function(String text) heading,
    required TResult Function(FanboxImage image) image,
    required TResult Function(FanboxFile file) file,
    required TResult Function(String? url, String? html) embed,
    required TResult Function(String postId, String creatorId, String title)
    postLink,
    required TResult Function(String text, String rawJson) unknown,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph():
        return paragraph(_that.text, _that.spans);
      case FanboxBlock_Heading():
        return heading(_that.text);
      case FanboxBlock_Image():
        return image(_that.image);
      case FanboxBlock_File():
        return file(_that.file);
      case FanboxBlock_Embed():
        return embed(_that.url, _that.html);
      case FanboxBlock_PostLink():
        return postLink(_that.postId, _that.creatorId, _that.title);
      case FanboxBlock_Unknown():
        return unknown(_that.text, _that.rawJson);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text, List<FanboxTextSpan> spans)? paragraph,
    TResult? Function(String text)? heading,
    TResult? Function(FanboxImage image)? image,
    TResult? Function(FanboxFile file)? file,
    TResult? Function(String? url, String? html)? embed,
    TResult? Function(String postId, String creatorId, String title)? postLink,
    TResult? Function(String text, String rawJson)? unknown,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxBlock_Paragraph() when paragraph != null:
        return paragraph(_that.text, _that.spans);
      case FanboxBlock_Heading() when heading != null:
        return heading(_that.text);
      case FanboxBlock_Image() when image != null:
        return image(_that.image);
      case FanboxBlock_File() when file != null:
        return file(_that.file);
      case FanboxBlock_Embed() when embed != null:
        return embed(_that.url, _that.html);
      case FanboxBlock_PostLink() when postLink != null:
        return postLink(_that.postId, _that.creatorId, _that.title);
      case FanboxBlock_Unknown() when unknown != null:
        return unknown(_that.text, _that.rawJson);
      case _:
        return null;
    }
  }
}

/// @nodoc

class FanboxBlock_Paragraph extends FanboxBlock {
  const FanboxBlock_Paragraph({
    required this.text,
    required final List<FanboxTextSpan> spans,
  }) : _spans = spans,
       super._();

  final String text;
  final List<FanboxTextSpan> _spans;
  List<FanboxTextSpan> get spans {
    if (_spans is EqualUnmodifiableListView) return _spans;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spans);
  }

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_ParagraphCopyWith<FanboxBlock_Paragraph> get copyWith =>
      _$FanboxBlock_ParagraphCopyWithImpl<FanboxBlock_Paragraph>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_Paragraph &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._spans, _spans));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    text,
    const DeepCollectionEquality().hash(_spans),
  );

  @override
  String toString() {
    return 'FanboxBlock.paragraph(text: $text, spans: $spans)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_ParagraphCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_ParagraphCopyWith(
    FanboxBlock_Paragraph value,
    $Res Function(FanboxBlock_Paragraph) _then,
  ) = _$FanboxBlock_ParagraphCopyWithImpl;
  @useResult
  $Res call({String text, List<FanboxTextSpan> spans});
}

/// @nodoc
class _$FanboxBlock_ParagraphCopyWithImpl<$Res>
    implements $FanboxBlock_ParagraphCopyWith<$Res> {
  _$FanboxBlock_ParagraphCopyWithImpl(this._self, this._then);

  final FanboxBlock_Paragraph _self;
  final $Res Function(FanboxBlock_Paragraph) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? text = null, Object? spans = null}) {
    return _then(
      FanboxBlock_Paragraph(
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        spans: null == spans
            ? _self._spans
            : spans // ignore: cast_nullable_to_non_nullable
                  as List<FanboxTextSpan>,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_Heading extends FanboxBlock {
  const FanboxBlock_Heading({required this.text}) : super._();

  final String text;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_HeadingCopyWith<FanboxBlock_Heading> get copyWith =>
      _$FanboxBlock_HeadingCopyWithImpl<FanboxBlock_Heading>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_Heading &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() {
    return 'FanboxBlock.heading(text: $text)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_HeadingCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_HeadingCopyWith(
    FanboxBlock_Heading value,
    $Res Function(FanboxBlock_Heading) _then,
  ) = _$FanboxBlock_HeadingCopyWithImpl;
  @useResult
  $Res call({String text});
}

/// @nodoc
class _$FanboxBlock_HeadingCopyWithImpl<$Res>
    implements $FanboxBlock_HeadingCopyWith<$Res> {
  _$FanboxBlock_HeadingCopyWithImpl(this._self, this._then);

  final FanboxBlock_Heading _self;
  final $Res Function(FanboxBlock_Heading) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? text = null}) {
    return _then(
      FanboxBlock_Heading(
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_Image extends FanboxBlock {
  const FanboxBlock_Image({required this.image}) : super._();

  final FanboxImage image;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_ImageCopyWith<FanboxBlock_Image> get copyWith =>
      _$FanboxBlock_ImageCopyWithImpl<FanboxBlock_Image>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_Image &&
            (identical(other.image, image) || other.image == image));
  }

  @override
  int get hashCode => Object.hash(runtimeType, image);

  @override
  String toString() {
    return 'FanboxBlock.image(image: $image)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_ImageCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_ImageCopyWith(
    FanboxBlock_Image value,
    $Res Function(FanboxBlock_Image) _then,
  ) = _$FanboxBlock_ImageCopyWithImpl;
  @useResult
  $Res call({FanboxImage image});
}

/// @nodoc
class _$FanboxBlock_ImageCopyWithImpl<$Res>
    implements $FanboxBlock_ImageCopyWith<$Res> {
  _$FanboxBlock_ImageCopyWithImpl(this._self, this._then);

  final FanboxBlock_Image _self;
  final $Res Function(FanboxBlock_Image) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? image = null}) {
    return _then(
      FanboxBlock_Image(
        image: null == image
            ? _self.image
            : image // ignore: cast_nullable_to_non_nullable
                  as FanboxImage,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_File extends FanboxBlock {
  const FanboxBlock_File({required this.file}) : super._();

  final FanboxFile file;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_FileCopyWith<FanboxBlock_File> get copyWith =>
      _$FanboxBlock_FileCopyWithImpl<FanboxBlock_File>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_File &&
            (identical(other.file, file) || other.file == file));
  }

  @override
  int get hashCode => Object.hash(runtimeType, file);

  @override
  String toString() {
    return 'FanboxBlock.file(file: $file)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_FileCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_FileCopyWith(
    FanboxBlock_File value,
    $Res Function(FanboxBlock_File) _then,
  ) = _$FanboxBlock_FileCopyWithImpl;
  @useResult
  $Res call({FanboxFile file});
}

/// @nodoc
class _$FanboxBlock_FileCopyWithImpl<$Res>
    implements $FanboxBlock_FileCopyWith<$Res> {
  _$FanboxBlock_FileCopyWithImpl(this._self, this._then);

  final FanboxBlock_File _self;
  final $Res Function(FanboxBlock_File) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? file = null}) {
    return _then(
      FanboxBlock_File(
        file: null == file
            ? _self.file
            : file // ignore: cast_nullable_to_non_nullable
                  as FanboxFile,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_Embed extends FanboxBlock {
  const FanboxBlock_Embed({this.url, this.html}) : super._();

  final String? url;
  final String? html;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_EmbedCopyWith<FanboxBlock_Embed> get copyWith =>
      _$FanboxBlock_EmbedCopyWithImpl<FanboxBlock_Embed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_Embed &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.html, html) || other.html == html));
  }

  @override
  int get hashCode => Object.hash(runtimeType, url, html);

  @override
  String toString() {
    return 'FanboxBlock.embed(url: $url, html: $html)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_EmbedCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_EmbedCopyWith(
    FanboxBlock_Embed value,
    $Res Function(FanboxBlock_Embed) _then,
  ) = _$FanboxBlock_EmbedCopyWithImpl;
  @useResult
  $Res call({String? url, String? html});
}

/// @nodoc
class _$FanboxBlock_EmbedCopyWithImpl<$Res>
    implements $FanboxBlock_EmbedCopyWith<$Res> {
  _$FanboxBlock_EmbedCopyWithImpl(this._self, this._then);

  final FanboxBlock_Embed _self;
  final $Res Function(FanboxBlock_Embed) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? url = freezed, Object? html = freezed}) {
    return _then(
      FanboxBlock_Embed(
        url: freezed == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
        html: freezed == html
            ? _self.html
            : html // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_PostLink extends FanboxBlock {
  const FanboxBlock_PostLink({
    required this.postId,
    required this.creatorId,
    required this.title,
  }) : super._();

  final String postId;
  final String creatorId;
  final String title;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_PostLinkCopyWith<FanboxBlock_PostLink> get copyWith =>
      _$FanboxBlock_PostLinkCopyWithImpl<FanboxBlock_PostLink>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_PostLink &&
            (identical(other.postId, postId) || other.postId == postId) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.title, title) || other.title == title));
  }

  @override
  int get hashCode => Object.hash(runtimeType, postId, creatorId, title);

  @override
  String toString() {
    return 'FanboxBlock.postLink(postId: $postId, creatorId: $creatorId, title: $title)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_PostLinkCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_PostLinkCopyWith(
    FanboxBlock_PostLink value,
    $Res Function(FanboxBlock_PostLink) _then,
  ) = _$FanboxBlock_PostLinkCopyWithImpl;
  @useResult
  $Res call({String postId, String creatorId, String title});
}

/// @nodoc
class _$FanboxBlock_PostLinkCopyWithImpl<$Res>
    implements $FanboxBlock_PostLinkCopyWith<$Res> {
  _$FanboxBlock_PostLinkCopyWithImpl(this._self, this._then);

  final FanboxBlock_PostLink _self;
  final $Res Function(FanboxBlock_PostLink) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? postId = null,
    Object? creatorId = null,
    Object? title = null,
  }) {
    return _then(
      FanboxBlock_PostLink(
        postId: null == postId
            ? _self.postId
            : postId // ignore: cast_nullable_to_non_nullable
                  as String,
        creatorId: null == creatorId
            ? _self.creatorId
            : creatorId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class FanboxBlock_Unknown extends FanboxBlock {
  const FanboxBlock_Unknown({required this.text, required this.rawJson})
    : super._();

  final String text;
  final String rawJson;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxBlock_UnknownCopyWith<FanboxBlock_Unknown> get copyWith =>
      _$FanboxBlock_UnknownCopyWithImpl<FanboxBlock_Unknown>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxBlock_Unknown &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.rawJson, rawJson) || other.rawJson == rawJson));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, rawJson);

  @override
  String toString() {
    return 'FanboxBlock.unknown(text: $text, rawJson: $rawJson)';
  }
}

/// @nodoc
abstract mixin class $FanboxBlock_UnknownCopyWith<$Res>
    implements $FanboxBlockCopyWith<$Res> {
  factory $FanboxBlock_UnknownCopyWith(
    FanboxBlock_Unknown value,
    $Res Function(FanboxBlock_Unknown) _then,
  ) = _$FanboxBlock_UnknownCopyWithImpl;
  @useResult
  $Res call({String text, String rawJson});
}

/// @nodoc
class _$FanboxBlock_UnknownCopyWithImpl<$Res>
    implements $FanboxBlock_UnknownCopyWith<$Res> {
  _$FanboxBlock_UnknownCopyWithImpl(this._self, this._then);

  final FanboxBlock_Unknown _self;
  final $Res Function(FanboxBlock_Unknown) _then;

  /// Create a copy of FanboxBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? text = null, Object? rawJson = null}) {
    return _then(
      FanboxBlock_Unknown(
        text: null == text
            ? _self.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        rawJson: null == rawJson
            ? _self.rawJson
            : rawJson // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$FanboxFeed {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FanboxFeed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FanboxFeed()';
  }
}

/// @nodoc
class $FanboxFeedCopyWith<$Res> {
  $FanboxFeedCopyWith(FanboxFeed _, $Res Function(FanboxFeed) __);
}

/// Adds pattern-matching-related methods to [FanboxFeed].
extension FanboxFeedPatterns on FanboxFeed {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FanboxFeed_Home value)? home,
    TResult Function(FanboxFeed_Supporting value)? supporting,
    TResult Function(FanboxFeed_Creator value)? creator,
    TResult Function(FanboxFeed_Tag value)? tag,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home() when home != null:
        return home(_that);
      case FanboxFeed_Supporting() when supporting != null:
        return supporting(_that);
      case FanboxFeed_Creator() when creator != null:
        return creator(_that);
      case FanboxFeed_Tag() when tag != null:
        return tag(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FanboxFeed_Home value) home,
    required TResult Function(FanboxFeed_Supporting value) supporting,
    required TResult Function(FanboxFeed_Creator value) creator,
    required TResult Function(FanboxFeed_Tag value) tag,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home():
        return home(_that);
      case FanboxFeed_Supporting():
        return supporting(_that);
      case FanboxFeed_Creator():
        return creator(_that);
      case FanboxFeed_Tag():
        return tag(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FanboxFeed_Home value)? home,
    TResult? Function(FanboxFeed_Supporting value)? supporting,
    TResult? Function(FanboxFeed_Creator value)? creator,
    TResult? Function(FanboxFeed_Tag value)? tag,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home() when home != null:
        return home(_that);
      case FanboxFeed_Supporting() when supporting != null:
        return supporting(_that);
      case FanboxFeed_Creator() when creator != null:
        return creator(_that);
      case FanboxFeed_Tag() when tag != null:
        return tag(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? home,
    TResult Function()? supporting,
    TResult Function(String creatorId)? creator,
    TResult Function(String tag, String? creatorId, int page)? tag,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home() when home != null:
        return home();
      case FanboxFeed_Supporting() when supporting != null:
        return supporting();
      case FanboxFeed_Creator() when creator != null:
        return creator(_that.creatorId);
      case FanboxFeed_Tag() when tag != null:
        return tag(_that.tag, _that.creatorId, _that.page);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() home,
    required TResult Function() supporting,
    required TResult Function(String creatorId) creator,
    required TResult Function(String tag, String? creatorId, int page) tag,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home():
        return home();
      case FanboxFeed_Supporting():
        return supporting();
      case FanboxFeed_Creator():
        return creator(_that.creatorId);
      case FanboxFeed_Tag():
        return tag(_that.tag, _that.creatorId, _that.page);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? home,
    TResult? Function()? supporting,
    TResult? Function(String creatorId)? creator,
    TResult? Function(String tag, String? creatorId, int page)? tag,
  }) {
    final _that = this;
    switch (_that) {
      case FanboxFeed_Home() when home != null:
        return home();
      case FanboxFeed_Supporting() when supporting != null:
        return supporting();
      case FanboxFeed_Creator() when creator != null:
        return creator(_that.creatorId);
      case FanboxFeed_Tag() when tag != null:
        return tag(_that.tag, _that.creatorId, _that.page);
      case _:
        return null;
    }
  }
}

/// @nodoc

class FanboxFeed_Home extends FanboxFeed {
  const FanboxFeed_Home() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FanboxFeed_Home);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FanboxFeed.home()';
  }
}

/// @nodoc

class FanboxFeed_Supporting extends FanboxFeed {
  const FanboxFeed_Supporting() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FanboxFeed_Supporting);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FanboxFeed.supporting()';
  }
}

/// @nodoc

class FanboxFeed_Creator extends FanboxFeed {
  const FanboxFeed_Creator({required this.creatorId}) : super._();

  final String creatorId;

  /// Create a copy of FanboxFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxFeed_CreatorCopyWith<FanboxFeed_Creator> get copyWith =>
      _$FanboxFeed_CreatorCopyWithImpl<FanboxFeed_Creator>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxFeed_Creator &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, creatorId);

  @override
  String toString() {
    return 'FanboxFeed.creator(creatorId: $creatorId)';
  }
}

/// @nodoc
abstract mixin class $FanboxFeed_CreatorCopyWith<$Res>
    implements $FanboxFeedCopyWith<$Res> {
  factory $FanboxFeed_CreatorCopyWith(
    FanboxFeed_Creator value,
    $Res Function(FanboxFeed_Creator) _then,
  ) = _$FanboxFeed_CreatorCopyWithImpl;
  @useResult
  $Res call({String creatorId});
}

/// @nodoc
class _$FanboxFeed_CreatorCopyWithImpl<$Res>
    implements $FanboxFeed_CreatorCopyWith<$Res> {
  _$FanboxFeed_CreatorCopyWithImpl(this._self, this._then);

  final FanboxFeed_Creator _self;
  final $Res Function(FanboxFeed_Creator) _then;

  /// Create a copy of FanboxFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? creatorId = null}) {
    return _then(
      FanboxFeed_Creator(
        creatorId: null == creatorId
            ? _self.creatorId
            : creatorId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class FanboxFeed_Tag extends FanboxFeed {
  const FanboxFeed_Tag({required this.tag, this.creatorId, required this.page})
    : super._();

  final String tag;
  final String? creatorId;
  final int page;

  /// Create a copy of FanboxFeed
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FanboxFeed_TagCopyWith<FanboxFeed_Tag> get copyWith =>
      _$FanboxFeed_TagCopyWithImpl<FanboxFeed_Tag>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FanboxFeed_Tag &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId) &&
            (identical(other.page, page) || other.page == page));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tag, creatorId, page);

  @override
  String toString() {
    return 'FanboxFeed.tag(tag: $tag, creatorId: $creatorId, page: $page)';
  }
}

/// @nodoc
abstract mixin class $FanboxFeed_TagCopyWith<$Res>
    implements $FanboxFeedCopyWith<$Res> {
  factory $FanboxFeed_TagCopyWith(
    FanboxFeed_Tag value,
    $Res Function(FanboxFeed_Tag) _then,
  ) = _$FanboxFeed_TagCopyWithImpl;
  @useResult
  $Res call({String tag, String? creatorId, int page});
}

/// @nodoc
class _$FanboxFeed_TagCopyWithImpl<$Res>
    implements $FanboxFeed_TagCopyWith<$Res> {
  _$FanboxFeed_TagCopyWithImpl(this._self, this._then);

  final FanboxFeed_Tag _self;
  final $Res Function(FanboxFeed_Tag) _then;

  /// Create a copy of FanboxFeed
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tag = null,
    Object? creatorId = freezed,
    Object? page = null,
  }) {
    return _then(
      FanboxFeed_Tag(
        tag: null == tag
            ? _self.tag
            : tag // ignore: cast_nullable_to_non_nullable
                  as String,
        creatorId: freezed == creatorId
            ? _self.creatorId
            : creatorId // ignore: cast_nullable_to_non_nullable
                  as String?,
        page: null == page
            ? _self.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
