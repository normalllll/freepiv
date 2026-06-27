// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalUser {

 LocalUserProfileImageUrls get profileImageUrls; String get id; String get name; String get account; String get mailAddress; bool get isPremium; int get xRestrict; bool get isMailAuthorized; bool get requirePolicyAgreement;
/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalUserCopyWith<LocalUser> get copyWith => _$LocalUserCopyWithImpl<LocalUser>(this as LocalUser, _$identity);

  /// Serializes this LocalUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalUser&&(identical(other.profileImageUrls, profileImageUrls) || other.profileImageUrls == profileImageUrls)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.account, account) || other.account == account)&&(identical(other.mailAddress, mailAddress) || other.mailAddress == mailAddress)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.xRestrict, xRestrict) || other.xRestrict == xRestrict)&&(identical(other.isMailAuthorized, isMailAuthorized) || other.isMailAuthorized == isMailAuthorized)&&(identical(other.requirePolicyAgreement, requirePolicyAgreement) || other.requirePolicyAgreement == requirePolicyAgreement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileImageUrls,id,name,account,mailAddress,isPremium,xRestrict,isMailAuthorized,requirePolicyAgreement);

@override
String toString() {
  return 'LocalUser(profileImageUrls: $profileImageUrls, id: $id, name: $name, account: $account, mailAddress: $mailAddress, isPremium: $isPremium, xRestrict: $xRestrict, isMailAuthorized: $isMailAuthorized, requirePolicyAgreement: $requirePolicyAgreement)';
}


}

/// @nodoc
abstract mixin class $LocalUserCopyWith<$Res>  {
  factory $LocalUserCopyWith(LocalUser value, $Res Function(LocalUser) _then) = _$LocalUserCopyWithImpl;
@useResult
$Res call({
 LocalUserProfileImageUrls profileImageUrls, String id, String name, String account, String mailAddress, bool isPremium, int xRestrict, bool isMailAuthorized, bool requirePolicyAgreement
});


$LocalUserProfileImageUrlsCopyWith<$Res> get profileImageUrls;

}
/// @nodoc
class _$LocalUserCopyWithImpl<$Res>
    implements $LocalUserCopyWith<$Res> {
  _$LocalUserCopyWithImpl(this._self, this._then);

  final LocalUser _self;
  final $Res Function(LocalUser) _then;

/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profileImageUrls = null,Object? id = null,Object? name = null,Object? account = null,Object? mailAddress = null,Object? isPremium = null,Object? xRestrict = null,Object? isMailAuthorized = null,Object? requirePolicyAgreement = null,}) {
  return _then(_self.copyWith(
profileImageUrls: null == profileImageUrls ? _self.profileImageUrls : profileImageUrls // ignore: cast_nullable_to_non_nullable
as LocalUserProfileImageUrls,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,mailAddress: null == mailAddress ? _self.mailAddress : mailAddress // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,xRestrict: null == xRestrict ? _self.xRestrict : xRestrict // ignore: cast_nullable_to_non_nullable
as int,isMailAuthorized: null == isMailAuthorized ? _self.isMailAuthorized : isMailAuthorized // ignore: cast_nullable_to_non_nullable
as bool,requirePolicyAgreement: null == requirePolicyAgreement ? _self.requirePolicyAgreement : requirePolicyAgreement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalUserProfileImageUrlsCopyWith<$Res> get profileImageUrls {
  
  return $LocalUserProfileImageUrlsCopyWith<$Res>(_self.profileImageUrls, (value) {
    return _then(_self.copyWith(profileImageUrls: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalUser].
extension LocalUserPatterns on LocalUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalUser value)  $default,){
final _that = this;
switch (_that) {
case _LocalUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalUser value)?  $default,){
final _that = this;
switch (_that) {
case _LocalUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LocalUserProfileImageUrls profileImageUrls,  String id,  String name,  String account,  String mailAddress,  bool isPremium,  int xRestrict,  bool isMailAuthorized,  bool requirePolicyAgreement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalUser() when $default != null:
return $default(_that.profileImageUrls,_that.id,_that.name,_that.account,_that.mailAddress,_that.isPremium,_that.xRestrict,_that.isMailAuthorized,_that.requirePolicyAgreement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LocalUserProfileImageUrls profileImageUrls,  String id,  String name,  String account,  String mailAddress,  bool isPremium,  int xRestrict,  bool isMailAuthorized,  bool requirePolicyAgreement)  $default,) {final _that = this;
switch (_that) {
case _LocalUser():
return $default(_that.profileImageUrls,_that.id,_that.name,_that.account,_that.mailAddress,_that.isPremium,_that.xRestrict,_that.isMailAuthorized,_that.requirePolicyAgreement);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LocalUserProfileImageUrls profileImageUrls,  String id,  String name,  String account,  String mailAddress,  bool isPremium,  int xRestrict,  bool isMailAuthorized,  bool requirePolicyAgreement)?  $default,) {final _that = this;
switch (_that) {
case _LocalUser() when $default != null:
return $default(_that.profileImageUrls,_that.id,_that.name,_that.account,_that.mailAddress,_that.isPremium,_that.xRestrict,_that.isMailAuthorized,_that.requirePolicyAgreement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalUser implements LocalUser {
  const _LocalUser({required this.profileImageUrls, required this.id, required this.name, required this.account, required this.mailAddress, required this.isPremium, required this.xRestrict, required this.isMailAuthorized, required this.requirePolicyAgreement});
  factory _LocalUser.fromJson(Map<String, dynamic> json) => _$LocalUserFromJson(json);

@override final  LocalUserProfileImageUrls profileImageUrls;
@override final  String id;
@override final  String name;
@override final  String account;
@override final  String mailAddress;
@override final  bool isPremium;
@override final  int xRestrict;
@override final  bool isMailAuthorized;
@override final  bool requirePolicyAgreement;

/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalUserCopyWith<_LocalUser> get copyWith => __$LocalUserCopyWithImpl<_LocalUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalUser&&(identical(other.profileImageUrls, profileImageUrls) || other.profileImageUrls == profileImageUrls)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.account, account) || other.account == account)&&(identical(other.mailAddress, mailAddress) || other.mailAddress == mailAddress)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium)&&(identical(other.xRestrict, xRestrict) || other.xRestrict == xRestrict)&&(identical(other.isMailAuthorized, isMailAuthorized) || other.isMailAuthorized == isMailAuthorized)&&(identical(other.requirePolicyAgreement, requirePolicyAgreement) || other.requirePolicyAgreement == requirePolicyAgreement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileImageUrls,id,name,account,mailAddress,isPremium,xRestrict,isMailAuthorized,requirePolicyAgreement);

@override
String toString() {
  return 'LocalUser(profileImageUrls: $profileImageUrls, id: $id, name: $name, account: $account, mailAddress: $mailAddress, isPremium: $isPremium, xRestrict: $xRestrict, isMailAuthorized: $isMailAuthorized, requirePolicyAgreement: $requirePolicyAgreement)';
}


}

/// @nodoc
abstract mixin class _$LocalUserCopyWith<$Res> implements $LocalUserCopyWith<$Res> {
  factory _$LocalUserCopyWith(_LocalUser value, $Res Function(_LocalUser) _then) = __$LocalUserCopyWithImpl;
@override @useResult
$Res call({
 LocalUserProfileImageUrls profileImageUrls, String id, String name, String account, String mailAddress, bool isPremium, int xRestrict, bool isMailAuthorized, bool requirePolicyAgreement
});


@override $LocalUserProfileImageUrlsCopyWith<$Res> get profileImageUrls;

}
/// @nodoc
class __$LocalUserCopyWithImpl<$Res>
    implements _$LocalUserCopyWith<$Res> {
  __$LocalUserCopyWithImpl(this._self, this._then);

  final _LocalUser _self;
  final $Res Function(_LocalUser) _then;

/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profileImageUrls = null,Object? id = null,Object? name = null,Object? account = null,Object? mailAddress = null,Object? isPremium = null,Object? xRestrict = null,Object? isMailAuthorized = null,Object? requirePolicyAgreement = null,}) {
  return _then(_LocalUser(
profileImageUrls: null == profileImageUrls ? _self.profileImageUrls : profileImageUrls // ignore: cast_nullable_to_non_nullable
as LocalUserProfileImageUrls,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,mailAddress: null == mailAddress ? _self.mailAddress : mailAddress // ignore: cast_nullable_to_non_nullable
as String,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,xRestrict: null == xRestrict ? _self.xRestrict : xRestrict // ignore: cast_nullable_to_non_nullable
as int,isMailAuthorized: null == isMailAuthorized ? _self.isMailAuthorized : isMailAuthorized // ignore: cast_nullable_to_non_nullable
as bool,requirePolicyAgreement: null == requirePolicyAgreement ? _self.requirePolicyAgreement : requirePolicyAgreement // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of LocalUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalUserProfileImageUrlsCopyWith<$Res> get profileImageUrls {
  
  return $LocalUserProfileImageUrlsCopyWith<$Res>(_self.profileImageUrls, (value) {
    return _then(_self.copyWith(profileImageUrls: value));
  });
}
}


/// @nodoc
mixin _$LocalUserProfileImageUrls {

 String get px16X16; String get px50X50; String get px170X170;
/// Create a copy of LocalUserProfileImageUrls
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalUserProfileImageUrlsCopyWith<LocalUserProfileImageUrls> get copyWith => _$LocalUserProfileImageUrlsCopyWithImpl<LocalUserProfileImageUrls>(this as LocalUserProfileImageUrls, _$identity);

  /// Serializes this LocalUserProfileImageUrls to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalUserProfileImageUrls&&(identical(other.px16X16, px16X16) || other.px16X16 == px16X16)&&(identical(other.px50X50, px50X50) || other.px50X50 == px50X50)&&(identical(other.px170X170, px170X170) || other.px170X170 == px170X170));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,px16X16,px50X50,px170X170);

@override
String toString() {
  return 'LocalUserProfileImageUrls(px16X16: $px16X16, px50X50: $px50X50, px170X170: $px170X170)';
}


}

/// @nodoc
abstract mixin class $LocalUserProfileImageUrlsCopyWith<$Res>  {
  factory $LocalUserProfileImageUrlsCopyWith(LocalUserProfileImageUrls value, $Res Function(LocalUserProfileImageUrls) _then) = _$LocalUserProfileImageUrlsCopyWithImpl;
@useResult
$Res call({
 String px16X16, String px50X50, String px170X170
});




}
/// @nodoc
class _$LocalUserProfileImageUrlsCopyWithImpl<$Res>
    implements $LocalUserProfileImageUrlsCopyWith<$Res> {
  _$LocalUserProfileImageUrlsCopyWithImpl(this._self, this._then);

  final LocalUserProfileImageUrls _self;
  final $Res Function(LocalUserProfileImageUrls) _then;

/// Create a copy of LocalUserProfileImageUrls
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? px16X16 = null,Object? px50X50 = null,Object? px170X170 = null,}) {
  return _then(_self.copyWith(
px16X16: null == px16X16 ? _self.px16X16 : px16X16 // ignore: cast_nullable_to_non_nullable
as String,px50X50: null == px50X50 ? _self.px50X50 : px50X50 // ignore: cast_nullable_to_non_nullable
as String,px170X170: null == px170X170 ? _self.px170X170 : px170X170 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalUserProfileImageUrls].
extension LocalUserProfileImageUrlsPatterns on LocalUserProfileImageUrls {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalUserProfileImageUrls value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalUserProfileImageUrls value)  $default,){
final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalUserProfileImageUrls value)?  $default,){
final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String px16X16,  String px50X50,  String px170X170)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls() when $default != null:
return $default(_that.px16X16,_that.px50X50,_that.px170X170);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String px16X16,  String px50X50,  String px170X170)  $default,) {final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls():
return $default(_that.px16X16,_that.px50X50,_that.px170X170);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String px16X16,  String px50X50,  String px170X170)?  $default,) {final _that = this;
switch (_that) {
case _LocalUserProfileImageUrls() when $default != null:
return $default(_that.px16X16,_that.px50X50,_that.px170X170);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalUserProfileImageUrls implements LocalUserProfileImageUrls {
  const _LocalUserProfileImageUrls({required this.px16X16, required this.px50X50, required this.px170X170});
  factory _LocalUserProfileImageUrls.fromJson(Map<String, dynamic> json) => _$LocalUserProfileImageUrlsFromJson(json);

@override final  String px16X16;
@override final  String px50X50;
@override final  String px170X170;

/// Create a copy of LocalUserProfileImageUrls
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalUserProfileImageUrlsCopyWith<_LocalUserProfileImageUrls> get copyWith => __$LocalUserProfileImageUrlsCopyWithImpl<_LocalUserProfileImageUrls>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalUserProfileImageUrlsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalUserProfileImageUrls&&(identical(other.px16X16, px16X16) || other.px16X16 == px16X16)&&(identical(other.px50X50, px50X50) || other.px50X50 == px50X50)&&(identical(other.px170X170, px170X170) || other.px170X170 == px170X170));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,px16X16,px50X50,px170X170);

@override
String toString() {
  return 'LocalUserProfileImageUrls(px16X16: $px16X16, px50X50: $px50X50, px170X170: $px170X170)';
}


}

/// @nodoc
abstract mixin class _$LocalUserProfileImageUrlsCopyWith<$Res> implements $LocalUserProfileImageUrlsCopyWith<$Res> {
  factory _$LocalUserProfileImageUrlsCopyWith(_LocalUserProfileImageUrls value, $Res Function(_LocalUserProfileImageUrls) _then) = __$LocalUserProfileImageUrlsCopyWithImpl;
@override @useResult
$Res call({
 String px16X16, String px50X50, String px170X170
});




}
/// @nodoc
class __$LocalUserProfileImageUrlsCopyWithImpl<$Res>
    implements _$LocalUserProfileImageUrlsCopyWith<$Res> {
  __$LocalUserProfileImageUrlsCopyWithImpl(this._self, this._then);

  final _LocalUserProfileImageUrls _self;
  final $Res Function(_LocalUserProfileImageUrls) _then;

/// Create a copy of LocalUserProfileImageUrls
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? px16X16 = null,Object? px50X50 = null,Object? px170X170 = null,}) {
  return _then(_LocalUserProfileImageUrls(
px16X16: null == px16X16 ? _self.px16X16 : px16X16 // ignore: cast_nullable_to_non_nullable
as String,px50X50: null == px50X50 ? _self.px50X50 : px50X50 // ignore: cast_nullable_to_non_nullable
as String,px170X170: null == px170X170 ? _self.px170X170 : px170X170 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
