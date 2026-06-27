// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_logic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchDraftState {

 String get text; SearchType get type;
/// Create a copy of SearchDraftState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchDraftStateCopyWith<SearchDraftState> get copyWith => _$SearchDraftStateCopyWithImpl<SearchDraftState>(this as SearchDraftState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchDraftState&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,text,type);

@override
String toString() {
  return 'SearchDraftState(text: $text, type: $type)';
}


}

/// @nodoc
abstract mixin class $SearchDraftStateCopyWith<$Res>  {
  factory $SearchDraftStateCopyWith(SearchDraftState value, $Res Function(SearchDraftState) _then) = _$SearchDraftStateCopyWithImpl;
@useResult
$Res call({
 String text, SearchType type
});




}
/// @nodoc
class _$SearchDraftStateCopyWithImpl<$Res>
    implements $SearchDraftStateCopyWith<$Res> {
  _$SearchDraftStateCopyWithImpl(this._self, this._then);

  final SearchDraftState _self;
  final $Res Function(SearchDraftState) _then;

/// Create a copy of SearchDraftState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? type = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchType,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchDraftState].
extension SearchDraftStatePatterns on SearchDraftState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchDraftState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchDraftState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchDraftState value)  $default,){
final _that = this;
switch (_that) {
case _SearchDraftState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchDraftState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchDraftState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  SearchType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchDraftState() when $default != null:
return $default(_that.text,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  SearchType type)  $default,) {final _that = this;
switch (_that) {
case _SearchDraftState():
return $default(_that.text,_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  SearchType type)?  $default,) {final _that = this;
switch (_that) {
case _SearchDraftState() when $default != null:
return $default(_that.text,_that.type);case _:
  return null;

}
}

}

/// @nodoc


class _SearchDraftState implements SearchDraftState {
  const _SearchDraftState({this.text = '', this.type = SearchType.illust});
  

@override@JsonKey() final  String text;
@override@JsonKey() final  SearchType type;

/// Create a copy of SearchDraftState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchDraftStateCopyWith<_SearchDraftState> get copyWith => __$SearchDraftStateCopyWithImpl<_SearchDraftState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchDraftState&&(identical(other.text, text) || other.text == text)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,text,type);

@override
String toString() {
  return 'SearchDraftState(text: $text, type: $type)';
}


}

/// @nodoc
abstract mixin class _$SearchDraftStateCopyWith<$Res> implements $SearchDraftStateCopyWith<$Res> {
  factory _$SearchDraftStateCopyWith(_SearchDraftState value, $Res Function(_SearchDraftState) _then) = __$SearchDraftStateCopyWithImpl;
@override @useResult
$Res call({
 String text, SearchType type
});




}
/// @nodoc
class __$SearchDraftStateCopyWithImpl<$Res>
    implements _$SearchDraftStateCopyWith<$Res> {
  __$SearchDraftStateCopyWithImpl(this._self, this._then);

  final _SearchDraftState _self;
  final $Res Function(_SearchDraftState) _then;

/// Create a copy of SearchDraftState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? type = null,}) {
  return _then(_SearchDraftState(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SearchType,
  ));
}


}

/// @nodoc
mixin _$SearchFiltersState {

 SearchFilterState get illust; SearchFilterState get novel;
/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFiltersStateCopyWith<SearchFiltersState> get copyWith => _$SearchFiltersStateCopyWithImpl<SearchFiltersState>(this as SearchFiltersState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFiltersState&&(identical(other.illust, illust) || other.illust == illust)&&(identical(other.novel, novel) || other.novel == novel));
}


@override
int get hashCode => Object.hash(runtimeType,illust,novel);

@override
String toString() {
  return 'SearchFiltersState(illust: $illust, novel: $novel)';
}


}

/// @nodoc
abstract mixin class $SearchFiltersStateCopyWith<$Res>  {
  factory $SearchFiltersStateCopyWith(SearchFiltersState value, $Res Function(SearchFiltersState) _then) = _$SearchFiltersStateCopyWithImpl;
@useResult
$Res call({
 SearchFilterState illust, SearchFilterState novel
});


$SearchFilterStateCopyWith<$Res> get illust;$SearchFilterStateCopyWith<$Res> get novel;

}
/// @nodoc
class _$SearchFiltersStateCopyWithImpl<$Res>
    implements $SearchFiltersStateCopyWith<$Res> {
  _$SearchFiltersStateCopyWithImpl(this._self, this._then);

  final SearchFiltersState _self;
  final $Res Function(SearchFiltersState) _then;

/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? illust = null,Object? novel = null,}) {
  return _then(_self.copyWith(
illust: null == illust ? _self.illust : illust // ignore: cast_nullable_to_non_nullable
as SearchFilterState,novel: null == novel ? _self.novel : novel // ignore: cast_nullable_to_non_nullable
as SearchFilterState,
  ));
}
/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get illust {
  
  return $SearchFilterStateCopyWith<$Res>(_self.illust, (value) {
    return _then(_self.copyWith(illust: value));
  });
}/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get novel {
  
  return $SearchFilterStateCopyWith<$Res>(_self.novel, (value) {
    return _then(_self.copyWith(novel: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchFiltersState].
extension SearchFiltersStatePatterns on SearchFiltersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFiltersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFiltersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFiltersState value)  $default,){
final _that = this;
switch (_that) {
case _SearchFiltersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFiltersState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFiltersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchFilterState illust,  SearchFilterState novel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFiltersState() when $default != null:
return $default(_that.illust,_that.novel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchFilterState illust,  SearchFilterState novel)  $default,) {final _that = this;
switch (_that) {
case _SearchFiltersState():
return $default(_that.illust,_that.novel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchFilterState illust,  SearchFilterState novel)?  $default,) {final _that = this;
switch (_that) {
case _SearchFiltersState() when $default != null:
return $default(_that.illust,_that.novel);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFiltersState implements SearchFiltersState {
  const _SearchFiltersState({this.illust = const SearchFilterState(), this.novel = const SearchFilterState()});
  

@override@JsonKey() final  SearchFilterState illust;
@override@JsonKey() final  SearchFilterState novel;

/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFiltersStateCopyWith<_SearchFiltersState> get copyWith => __$SearchFiltersStateCopyWithImpl<_SearchFiltersState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFiltersState&&(identical(other.illust, illust) || other.illust == illust)&&(identical(other.novel, novel) || other.novel == novel));
}


@override
int get hashCode => Object.hash(runtimeType,illust,novel);

@override
String toString() {
  return 'SearchFiltersState(illust: $illust, novel: $novel)';
}


}

/// @nodoc
abstract mixin class _$SearchFiltersStateCopyWith<$Res> implements $SearchFiltersStateCopyWith<$Res> {
  factory _$SearchFiltersStateCopyWith(_SearchFiltersState value, $Res Function(_SearchFiltersState) _then) = __$SearchFiltersStateCopyWithImpl;
@override @useResult
$Res call({
 SearchFilterState illust, SearchFilterState novel
});


@override $SearchFilterStateCopyWith<$Res> get illust;@override $SearchFilterStateCopyWith<$Res> get novel;

}
/// @nodoc
class __$SearchFiltersStateCopyWithImpl<$Res>
    implements _$SearchFiltersStateCopyWith<$Res> {
  __$SearchFiltersStateCopyWithImpl(this._self, this._then);

  final _SearchFiltersState _self;
  final $Res Function(_SearchFiltersState) _then;

/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? illust = null,Object? novel = null,}) {
  return _then(_SearchFiltersState(
illust: null == illust ? _self.illust : illust // ignore: cast_nullable_to_non_nullable
as SearchFilterState,novel: null == novel ? _self.novel : novel // ignore: cast_nullable_to_non_nullable
as SearchFilterState,
  ));
}

/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get illust {
  
  return $SearchFilterStateCopyWith<$Res>(_self.illust, (value) {
    return _then(_self.copyWith(illust: value));
  });
}/// Create a copy of SearchFiltersState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get novel {
  
  return $SearchFilterStateCopyWith<$Res>(_self.novel, (value) {
    return _then(_self.copyWith(novel: value));
  });
}
}

/// @nodoc
mixin _$SearchFilterState {

 SearchSort get sort; SearchTarget get target; SearchDatePreset get datePreset; DateTime? get customStart; DateTime? get customEnd; int? get bookmarkTotal;
/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<SearchFilterState> get copyWith => _$SearchFilterStateCopyWithImpl<SearchFilterState>(this as SearchFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilterState&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.target, target) || other.target == target)&&(identical(other.datePreset, datePreset) || other.datePreset == datePreset)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.bookmarkTotal, bookmarkTotal) || other.bookmarkTotal == bookmarkTotal));
}


@override
int get hashCode => Object.hash(runtimeType,sort,target,datePreset,customStart,customEnd,bookmarkTotal);

@override
String toString() {
  return 'SearchFilterState(sort: $sort, target: $target, datePreset: $datePreset, customStart: $customStart, customEnd: $customEnd, bookmarkTotal: $bookmarkTotal)';
}


}

/// @nodoc
abstract mixin class $SearchFilterStateCopyWith<$Res>  {
  factory $SearchFilterStateCopyWith(SearchFilterState value, $Res Function(SearchFilterState) _then) = _$SearchFilterStateCopyWithImpl;
@useResult
$Res call({
 SearchSort sort, SearchTarget target, SearchDatePreset datePreset, DateTime? customStart, DateTime? customEnd, int? bookmarkTotal
});




}
/// @nodoc
class _$SearchFilterStateCopyWithImpl<$Res>
    implements $SearchFilterStateCopyWith<$Res> {
  _$SearchFilterStateCopyWithImpl(this._self, this._then);

  final SearchFilterState _self;
  final $Res Function(SearchFilterState) _then;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sort = null,Object? target = null,Object? datePreset = null,Object? customStart = freezed,Object? customEnd = freezed,Object? bookmarkTotal = freezed,}) {
  return _then(_self.copyWith(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SearchSort,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as SearchTarget,datePreset: null == datePreset ? _self.datePreset : datePreset // ignore: cast_nullable_to_non_nullable
as SearchDatePreset,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,bookmarkTotal: freezed == bookmarkTotal ? _self.bookmarkTotal : bookmarkTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilterState].
extension SearchFilterStatePatterns on SearchFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilterState value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SearchSort sort,  SearchTarget target,  SearchDatePreset datePreset,  DateTime? customStart,  DateTime? customEnd,  int? bookmarkTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
return $default(_that.sort,_that.target,_that.datePreset,_that.customStart,_that.customEnd,_that.bookmarkTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SearchSort sort,  SearchTarget target,  SearchDatePreset datePreset,  DateTime? customStart,  DateTime? customEnd,  int? bookmarkTotal)  $default,) {final _that = this;
switch (_that) {
case _SearchFilterState():
return $default(_that.sort,_that.target,_that.datePreset,_that.customStart,_that.customEnd,_that.bookmarkTotal);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SearchSort sort,  SearchTarget target,  SearchDatePreset datePreset,  DateTime? customStart,  DateTime? customEnd,  int? bookmarkTotal)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilterState() when $default != null:
return $default(_that.sort,_that.target,_that.datePreset,_that.customStart,_that.customEnd,_that.bookmarkTotal);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFilterState extends SearchFilterState {
  const _SearchFilterState({this.sort = SearchSort.dateDesc, this.target = SearchTarget.partialMatchForTags, this.datePreset = SearchDatePreset.any, this.customStart, this.customEnd, this.bookmarkTotal}): super._();
  

@override@JsonKey() final  SearchSort sort;
@override@JsonKey() final  SearchTarget target;
@override@JsonKey() final  SearchDatePreset datePreset;
@override final  DateTime? customStart;
@override final  DateTime? customEnd;
@override final  int? bookmarkTotal;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFilterStateCopyWith<_SearchFilterState> get copyWith => __$SearchFilterStateCopyWithImpl<_SearchFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilterState&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.target, target) || other.target == target)&&(identical(other.datePreset, datePreset) || other.datePreset == datePreset)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.bookmarkTotal, bookmarkTotal) || other.bookmarkTotal == bookmarkTotal));
}


@override
int get hashCode => Object.hash(runtimeType,sort,target,datePreset,customStart,customEnd,bookmarkTotal);

@override
String toString() {
  return 'SearchFilterState(sort: $sort, target: $target, datePreset: $datePreset, customStart: $customStart, customEnd: $customEnd, bookmarkTotal: $bookmarkTotal)';
}


}

/// @nodoc
abstract mixin class _$SearchFilterStateCopyWith<$Res> implements $SearchFilterStateCopyWith<$Res> {
  factory _$SearchFilterStateCopyWith(_SearchFilterState value, $Res Function(_SearchFilterState) _then) = __$SearchFilterStateCopyWithImpl;
@override @useResult
$Res call({
 SearchSort sort, SearchTarget target, SearchDatePreset datePreset, DateTime? customStart, DateTime? customEnd, int? bookmarkTotal
});




}
/// @nodoc
class __$SearchFilterStateCopyWithImpl<$Res>
    implements _$SearchFilterStateCopyWith<$Res> {
  __$SearchFilterStateCopyWithImpl(this._self, this._then);

  final _SearchFilterState _self;
  final $Res Function(_SearchFilterState) _then;

/// Create a copy of SearchFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sort = null,Object? target = null,Object? datePreset = null,Object? customStart = freezed,Object? customEnd = freezed,Object? bookmarkTotal = freezed,}) {
  return _then(_SearchFilterState(
sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SearchSort,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as SearchTarget,datePreset: null == datePreset ? _self.datePreset : datePreset // ignore: cast_nullable_to_non_nullable
as SearchDatePreset,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,bookmarkTotal: freezed == bookmarkTotal ? _self.bookmarkTotal : bookmarkTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$SearchResultRequest {

 String get keyword; SearchFilterState get filter;
/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultRequestCopyWith<SearchResultRequest> get copyWith => _$SearchResultRequestCopyWithImpl<SearchResultRequest>(this as SearchResultRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultRequest&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,keyword,filter);

@override
String toString() {
  return 'SearchResultRequest(keyword: $keyword, filter: $filter)';
}


}

/// @nodoc
abstract mixin class $SearchResultRequestCopyWith<$Res>  {
  factory $SearchResultRequestCopyWith(SearchResultRequest value, $Res Function(SearchResultRequest) _then) = _$SearchResultRequestCopyWithImpl;
@useResult
$Res call({
 String keyword, SearchFilterState filter
});


$SearchFilterStateCopyWith<$Res> get filter;

}
/// @nodoc
class _$SearchResultRequestCopyWithImpl<$Res>
    implements $SearchResultRequestCopyWith<$Res> {
  _$SearchResultRequestCopyWithImpl(this._self, this._then);

  final SearchResultRequest _self;
  final $Res Function(SearchResultRequest) _then;

/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyword = null,Object? filter = null,}) {
  return _then(_self.copyWith(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as SearchFilterState,
  ));
}
/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get filter {
  
  return $SearchFilterStateCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResultRequest].
extension SearchResultRequestPatterns on SearchResultRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultRequest value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String keyword,  SearchFilterState filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultRequest() when $default != null:
return $default(_that.keyword,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String keyword,  SearchFilterState filter)  $default,) {final _that = this;
switch (_that) {
case _SearchResultRequest():
return $default(_that.keyword,_that.filter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String keyword,  SearchFilterState filter)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultRequest() when $default != null:
return $default(_that.keyword,_that.filter);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResultRequest implements SearchResultRequest {
  const _SearchResultRequest({required this.keyword, required this.filter});
  

@override final  String keyword;
@override final  SearchFilterState filter;

/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultRequestCopyWith<_SearchResultRequest> get copyWith => __$SearchResultRequestCopyWithImpl<_SearchResultRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultRequest&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.filter, filter) || other.filter == filter));
}


@override
int get hashCode => Object.hash(runtimeType,keyword,filter);

@override
String toString() {
  return 'SearchResultRequest(keyword: $keyword, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$SearchResultRequestCopyWith<$Res> implements $SearchResultRequestCopyWith<$Res> {
  factory _$SearchResultRequestCopyWith(_SearchResultRequest value, $Res Function(_SearchResultRequest) _then) = __$SearchResultRequestCopyWithImpl;
@override @useResult
$Res call({
 String keyword, SearchFilterState filter
});


@override $SearchFilterStateCopyWith<$Res> get filter;

}
/// @nodoc
class __$SearchResultRequestCopyWithImpl<$Res>
    implements _$SearchResultRequestCopyWith<$Res> {
  __$SearchResultRequestCopyWithImpl(this._self, this._then);

  final _SearchResultRequest _self;
  final $Res Function(_SearchResultRequest) _then;

/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyword = null,Object? filter = null,}) {
  return _then(_SearchResultRequest(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as SearchFilterState,
  ));
}

/// Create a copy of SearchResultRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchFilterStateCopyWith<$Res> get filter {
  
  return $SearchFilterStateCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
