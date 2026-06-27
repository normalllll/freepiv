// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'responses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserAccountResult {

 String get accessToken; int get expiresIn; String get tokenType; String get scope; String get refreshToken; LocalUser get user;
/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserAccountResultCopyWith<UserAccountResult> get copyWith => _$UserAccountResultCopyWithImpl<UserAccountResult>(this as UserAccountResult, _$identity);

  /// Serializes this UserAccountResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserAccountResult&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,expiresIn,tokenType,scope,refreshToken,user);

@override
String toString() {
  return 'UserAccountResult(accessToken: $accessToken, expiresIn: $expiresIn, tokenType: $tokenType, scope: $scope, refreshToken: $refreshToken, user: $user)';
}


}

/// @nodoc
abstract mixin class $UserAccountResultCopyWith<$Res>  {
  factory $UserAccountResultCopyWith(UserAccountResult value, $Res Function(UserAccountResult) _then) = _$UserAccountResultCopyWithImpl;
@useResult
$Res call({
 String accessToken, int expiresIn, String tokenType, String scope, String refreshToken, LocalUser user
});


$LocalUserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserAccountResultCopyWithImpl<$Res>
    implements $UserAccountResultCopyWith<$Res> {
  _$UserAccountResultCopyWithImpl(this._self, this._then);

  final UserAccountResult _self;
  final $Res Function(UserAccountResult) _then;

/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? expiresIn = null,Object? tokenType = null,Object? scope = null,Object? refreshToken = null,Object? user = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as LocalUser,
  ));
}
/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalUserCopyWith<$Res> get user {
  
  return $LocalUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserAccountResult].
extension UserAccountResultPatterns on UserAccountResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserAccountResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserAccountResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserAccountResult value)  $default,){
final _that = this;
switch (_that) {
case _UserAccountResult():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserAccountResult value)?  $default,){
final _that = this;
switch (_that) {
case _UserAccountResult() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  int expiresIn,  String tokenType,  String scope,  String refreshToken,  LocalUser user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserAccountResult() when $default != null:
return $default(_that.accessToken,_that.expiresIn,_that.tokenType,_that.scope,_that.refreshToken,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  int expiresIn,  String tokenType,  String scope,  String refreshToken,  LocalUser user)  $default,) {final _that = this;
switch (_that) {
case _UserAccountResult():
return $default(_that.accessToken,_that.expiresIn,_that.tokenType,_that.scope,_that.refreshToken,_that.user);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  int expiresIn,  String tokenType,  String scope,  String refreshToken,  LocalUser user)?  $default,) {final _that = this;
switch (_that) {
case _UserAccountResult() when $default != null:
return $default(_that.accessToken,_that.expiresIn,_that.tokenType,_that.scope,_that.refreshToken,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserAccountResult implements UserAccountResult {
  const _UserAccountResult({required this.accessToken, required this.expiresIn, required this.tokenType, required this.scope, required this.refreshToken, required this.user});
  factory _UserAccountResult.fromJson(Map<String, dynamic> json) => _$UserAccountResultFromJson(json);

@override final  String accessToken;
@override final  int expiresIn;
@override final  String tokenType;
@override final  String scope;
@override final  String refreshToken;
@override final  LocalUser user;

/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserAccountResultCopyWith<_UserAccountResult> get copyWith => __$UserAccountResultCopyWithImpl<_UserAccountResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserAccountResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserAccountResult&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,expiresIn,tokenType,scope,refreshToken,user);

@override
String toString() {
  return 'UserAccountResult(accessToken: $accessToken, expiresIn: $expiresIn, tokenType: $tokenType, scope: $scope, refreshToken: $refreshToken, user: $user)';
}


}

/// @nodoc
abstract mixin class _$UserAccountResultCopyWith<$Res> implements $UserAccountResultCopyWith<$Res> {
  factory _$UserAccountResultCopyWith(_UserAccountResult value, $Res Function(_UserAccountResult) _then) = __$UserAccountResultCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, int expiresIn, String tokenType, String scope, String refreshToken, LocalUser user
});


@override $LocalUserCopyWith<$Res> get user;

}
/// @nodoc
class __$UserAccountResultCopyWithImpl<$Res>
    implements _$UserAccountResultCopyWith<$Res> {
  __$UserAccountResultCopyWithImpl(this._self, this._then);

  final _UserAccountResult _self;
  final $Res Function(_UserAccountResult) _then;

/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? expiresIn = null,Object? tokenType = null,Object? scope = null,Object? refreshToken = null,Object? user = null,}) {
  return _then(_UserAccountResult(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as LocalUser,
  ));
}

/// Create a copy of UserAccountResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalUserCopyWith<$Res> get user {
  
  return $LocalUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
