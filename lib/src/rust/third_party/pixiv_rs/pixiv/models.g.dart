// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalUser _$LocalUserFromJson(Map<String, dynamic> json) => _LocalUser(
  profileImageUrls: LocalUserProfileImageUrls.fromJson(
    json['profileImageUrls'] as Map<String, dynamic>,
  ),
  id: json['id'] as String,
  name: json['name'] as String,
  account: json['account'] as String,
  mailAddress: json['mailAddress'] as String,
  isPremium: json['isPremium'] as bool,
  xRestrict: (json['xRestrict'] as num).toInt(),
  isMailAuthorized: json['isMailAuthorized'] as bool,
  requirePolicyAgreement: json['requirePolicyAgreement'] as bool,
);

Map<String, dynamic> _$LocalUserToJson(_LocalUser instance) =>
    <String, dynamic>{
      'profileImageUrls': instance.profileImageUrls,
      'id': instance.id,
      'name': instance.name,
      'account': instance.account,
      'mailAddress': instance.mailAddress,
      'isPremium': instance.isPremium,
      'xRestrict': instance.xRestrict,
      'isMailAuthorized': instance.isMailAuthorized,
      'requirePolicyAgreement': instance.requirePolicyAgreement,
    };

_LocalUserProfileImageUrls _$LocalUserProfileImageUrlsFromJson(
  Map<String, dynamic> json,
) => _LocalUserProfileImageUrls(
  px16X16: json['px16X16'] as String,
  px50X50: json['px50X50'] as String,
  px170X170: json['px170X170'] as String,
);

Map<String, dynamic> _$LocalUserProfileImageUrlsToJson(
  _LocalUserProfileImageUrls instance,
) => <String, dynamic>{
  'px16X16': instance.px16X16,
  'px50X50': instance.px50X50,
  'px170X170': instance.px170X170,
};
