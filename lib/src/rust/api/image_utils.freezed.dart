// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_utils.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileImageError {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProfileImageError()';
}


}

/// @nodoc
class $ProfileImageErrorCopyWith<$Res>  {
$ProfileImageErrorCopyWith(ProfileImageError _, $Res Function(ProfileImageError) __);
}


/// Adds pattern-matching-related methods to [ProfileImageError].
extension ProfileImageErrorPatterns on ProfileImageError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProfileImageError_Decode value)?  decode,TResult Function( ProfileImageError_SourceTooLarge value)?  sourceTooLarge,TResult Function( ProfileImageError_EmptyCrop value)?  emptyCrop,TResult Function( ProfileImageError_Encode value)?  encode,TResult Function( ProfileImageError_OutputTooLarge value)?  outputTooLarge,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProfileImageError_Decode() when decode != null:
return decode(_that);case ProfileImageError_SourceTooLarge() when sourceTooLarge != null:
return sourceTooLarge(_that);case ProfileImageError_EmptyCrop() when emptyCrop != null:
return emptyCrop(_that);case ProfileImageError_Encode() when encode != null:
return encode(_that);case ProfileImageError_OutputTooLarge() when outputTooLarge != null:
return outputTooLarge(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProfileImageError_Decode value)  decode,required TResult Function( ProfileImageError_SourceTooLarge value)  sourceTooLarge,required TResult Function( ProfileImageError_EmptyCrop value)  emptyCrop,required TResult Function( ProfileImageError_Encode value)  encode,required TResult Function( ProfileImageError_OutputTooLarge value)  outputTooLarge,}){
final _that = this;
switch (_that) {
case ProfileImageError_Decode():
return decode(_that);case ProfileImageError_SourceTooLarge():
return sourceTooLarge(_that);case ProfileImageError_EmptyCrop():
return emptyCrop(_that);case ProfileImageError_Encode():
return encode(_that);case ProfileImageError_OutputTooLarge():
return outputTooLarge(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProfileImageError_Decode value)?  decode,TResult? Function( ProfileImageError_SourceTooLarge value)?  sourceTooLarge,TResult? Function( ProfileImageError_EmptyCrop value)?  emptyCrop,TResult? Function( ProfileImageError_Encode value)?  encode,TResult? Function( ProfileImageError_OutputTooLarge value)?  outputTooLarge,}){
final _that = this;
switch (_that) {
case ProfileImageError_Decode() when decode != null:
return decode(_that);case ProfileImageError_SourceTooLarge() when sourceTooLarge != null:
return sourceTooLarge(_that);case ProfileImageError_EmptyCrop() when emptyCrop != null:
return emptyCrop(_that);case ProfileImageError_Encode() when encode != null:
return encode(_that);case ProfileImageError_OutputTooLarge() when outputTooLarge != null:
return outputTooLarge(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  decode,TResult Function( int width,  int height)?  sourceTooLarge,TResult Function()?  emptyCrop,TResult Function( String message)?  encode,TResult Function( int size,  int limit)?  outputTooLarge,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProfileImageError_Decode() when decode != null:
return decode(_that.message);case ProfileImageError_SourceTooLarge() when sourceTooLarge != null:
return sourceTooLarge(_that.width,_that.height);case ProfileImageError_EmptyCrop() when emptyCrop != null:
return emptyCrop();case ProfileImageError_Encode() when encode != null:
return encode(_that.message);case ProfileImageError_OutputTooLarge() when outputTooLarge != null:
return outputTooLarge(_that.size,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  decode,required TResult Function( int width,  int height)  sourceTooLarge,required TResult Function()  emptyCrop,required TResult Function( String message)  encode,required TResult Function( int size,  int limit)  outputTooLarge,}) {final _that = this;
switch (_that) {
case ProfileImageError_Decode():
return decode(_that.message);case ProfileImageError_SourceTooLarge():
return sourceTooLarge(_that.width,_that.height);case ProfileImageError_EmptyCrop():
return emptyCrop();case ProfileImageError_Encode():
return encode(_that.message);case ProfileImageError_OutputTooLarge():
return outputTooLarge(_that.size,_that.limit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  decode,TResult? Function( int width,  int height)?  sourceTooLarge,TResult? Function()?  emptyCrop,TResult? Function( String message)?  encode,TResult? Function( int size,  int limit)?  outputTooLarge,}) {final _that = this;
switch (_that) {
case ProfileImageError_Decode() when decode != null:
return decode(_that.message);case ProfileImageError_SourceTooLarge() when sourceTooLarge != null:
return sourceTooLarge(_that.width,_that.height);case ProfileImageError_EmptyCrop() when emptyCrop != null:
return emptyCrop();case ProfileImageError_Encode() when encode != null:
return encode(_that.message);case ProfileImageError_OutputTooLarge() when outputTooLarge != null:
return outputTooLarge(_that.size,_that.limit);case _:
  return null;

}
}

}

/// @nodoc


class ProfileImageError_Decode extends ProfileImageError {
  const ProfileImageError_Decode({required this.message}): super._();
  

 final  String message;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileImageError_DecodeCopyWith<ProfileImageError_Decode> get copyWith => _$ProfileImageError_DecodeCopyWithImpl<ProfileImageError_Decode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError_Decode&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ProfileImageError.decode(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProfileImageError_DecodeCopyWith<$Res> implements $ProfileImageErrorCopyWith<$Res> {
  factory $ProfileImageError_DecodeCopyWith(ProfileImageError_Decode value, $Res Function(ProfileImageError_Decode) _then) = _$ProfileImageError_DecodeCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProfileImageError_DecodeCopyWithImpl<$Res>
    implements $ProfileImageError_DecodeCopyWith<$Res> {
  _$ProfileImageError_DecodeCopyWithImpl(this._self, this._then);

  final ProfileImageError_Decode _self;
  final $Res Function(ProfileImageError_Decode) _then;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProfileImageError_Decode(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProfileImageError_SourceTooLarge extends ProfileImageError {
  const ProfileImageError_SourceTooLarge({required this.width, required this.height}): super._();
  

 final  int width;
 final  int height;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileImageError_SourceTooLargeCopyWith<ProfileImageError_SourceTooLarge> get copyWith => _$ProfileImageError_SourceTooLargeCopyWithImpl<ProfileImageError_SourceTooLarge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError_SourceTooLarge&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode {
    return Object.hash(runtimeType,width,height);
}

@override
String toString() {
    return 'ProfileImageError.sourceTooLarge(width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $ProfileImageError_SourceTooLargeCopyWith<$Res> implements $ProfileImageErrorCopyWith<$Res> {
  factory $ProfileImageError_SourceTooLargeCopyWith(ProfileImageError_SourceTooLarge value, $Res Function(ProfileImageError_SourceTooLarge) _then) = _$ProfileImageError_SourceTooLargeCopyWithImpl;
@useResult
$Res call({
 int width, int height
});




}
/// @nodoc
class _$ProfileImageError_SourceTooLargeCopyWithImpl<$Res>
    implements $ProfileImageError_SourceTooLargeCopyWith<$Res> {
  _$ProfileImageError_SourceTooLargeCopyWithImpl(this._self, this._then);

  final ProfileImageError_SourceTooLarge _self;
  final $Res Function(ProfileImageError_SourceTooLarge) _then;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? width = null,Object? height = null,}) {
  return _then(ProfileImageError_SourceTooLarge(
width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ProfileImageError_EmptyCrop extends ProfileImageError {
  const ProfileImageError_EmptyCrop(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError_EmptyCrop);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ProfileImageError.emptyCrop()';
}


}




/// @nodoc


class ProfileImageError_Encode extends ProfileImageError {
  const ProfileImageError_Encode({required this.message}): super._();
  

 final  String message;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileImageError_EncodeCopyWith<ProfileImageError_Encode> get copyWith => _$ProfileImageError_EncodeCopyWithImpl<ProfileImageError_Encode>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError_Encode&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'ProfileImageError.encode(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProfileImageError_EncodeCopyWith<$Res> implements $ProfileImageErrorCopyWith<$Res> {
  factory $ProfileImageError_EncodeCopyWith(ProfileImageError_Encode value, $Res Function(ProfileImageError_Encode) _then) = _$ProfileImageError_EncodeCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProfileImageError_EncodeCopyWithImpl<$Res>
    implements $ProfileImageError_EncodeCopyWith<$Res> {
  _$ProfileImageError_EncodeCopyWithImpl(this._self, this._then);

  final ProfileImageError_Encode _self;
  final $Res Function(ProfileImageError_Encode) _then;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProfileImageError_Encode(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProfileImageError_OutputTooLarge extends ProfileImageError {
  const ProfileImageError_OutputTooLarge({required this.size, required this.limit}): super._();
  

 final  int size;
 final  int limit;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileImageError_OutputTooLargeCopyWith<ProfileImageError_OutputTooLarge> get copyWith => _$ProfileImageError_OutputTooLargeCopyWithImpl<ProfileImageError_OutputTooLarge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileImageError_OutputTooLarge&&(identical(other.size, size) || other.size == size)&&(identical(other.limit, limit) || other.limit == limit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,size,limit);
}

@override
String toString() {
    return 'ProfileImageError.outputTooLarge(size: $size, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $ProfileImageError_OutputTooLargeCopyWith<$Res> implements $ProfileImageErrorCopyWith<$Res> {
  factory $ProfileImageError_OutputTooLargeCopyWith(ProfileImageError_OutputTooLarge value, $Res Function(ProfileImageError_OutputTooLarge) _then) = _$ProfileImageError_OutputTooLargeCopyWithImpl;
@useResult
$Res call({
 int size, int limit
});




}
/// @nodoc
class _$ProfileImageError_OutputTooLargeCopyWithImpl<$Res>
    implements $ProfileImageError_OutputTooLargeCopyWith<$Res> {
  _$ProfileImageError_OutputTooLargeCopyWithImpl(this._self, this._then);

  final ProfileImageError_OutputTooLarge _self;
  final $Res Function(ProfileImageError_OutputTooLarge) _then;

/// Create a copy of ProfileImageError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? size = null,Object? limit = null,}) {
  return _then(ProfileImageError_OutputTooLarge(
size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
