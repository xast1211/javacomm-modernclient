// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
      userid: json['USERID'] as String?,
      email: json['EMAIL'] as String?,
      password: json['PASSWORD'] as String?,
      aes: json['AES'] as String?,
      onetime: json['ONETIME'] as String?,
    );

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
      'USERID': instance.userid,
      'EMAIL': instance.email,
      'PASSWORD': instance.password,
      'AES': instance.aes,
      'ONETIME': instance.onetime,
    };
