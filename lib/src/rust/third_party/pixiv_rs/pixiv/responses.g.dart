// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserAccountResult _$UserAccountResultFromJson(Map<String, dynamic> json) =>
    _UserAccountResult(
      accessToken: json['accessToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      tokenType: json['tokenType'] as String,
      scope: json['scope'] as String,
      refreshToken: json['refreshToken'] as String,
      user: LocalUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserAccountResultToJson(_UserAccountResult instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'expiresIn': instance.expiresIn,
      'tokenType': instance.tokenType,
      'scope': instance.scope,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
