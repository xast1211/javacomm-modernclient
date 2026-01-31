// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signin_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInResponse _$SignInResponseFromJson(Map<String, dynamic> json) =>
    SignInResponse(
      header: json['header'] as String,
      userid: json['userid'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      password: json['password'] as String?,
      foregroundColor: json['foregroundColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      multilingualkey: json['multilingualkey'] as String?,
      text: json['text'] as String?,
      errorCode: json['errorCode'] as String?,
      sessionId: json['sessionId'] as String?,
    );

Map<String, dynamic> _$SignInResponseToJson(SignInResponse instance) =>
    <String, dynamic>{
      'header': instance.header,
      'userid': instance.userid,
      'email': instance.email,
      'nickname': instance.nickname,
      'password': instance.password,
      'foregroundColor': instance.foregroundColor,
      'backgroundColor': instance.backgroundColor,
      'multilingualkey': instance.multilingualkey,
      'text': instance.text,
      'errorCode': instance.errorCode,
      'sessionId': instance.sessionId,
    };
