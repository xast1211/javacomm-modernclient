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
      if (instance.userid case final value?) 'USERID': value,
      if (instance.email case final value?) 'EMAIL': value,
      if (instance.password case final value?) 'PASSWORD': value,
      if (instance.aes case final value?) 'AES': value,
      if (instance.onetime case final value?) 'ONETIME': value,
    };
