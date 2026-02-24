// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUser _$UpdateUserFromJson(Map<String, dynamic> json) => UpdateUser(
      dataset: json['DATASET'] == null
          ? null
          : UpdateUserDataset.fromJson(json['DATASET'] as Map<String, dynamic>),
      header: $enumDecodeNullable(_$HeaderEnumMap, json['HEADER']) ??
          Header.REQUEST,
      command: $enumDecodeNullable(_$CommandEnumMap, json['COMMAND']) ??
          Command.UPDATEUSER,
    );

Map<String, dynamic> _$UpdateUserToJson(UpdateUser instance) =>
    <String, dynamic>{
      if (instance.dataset?.toJson() case final value?) 'DATASET': value,
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
    };

const _$HeaderEnumMap = {
  Header.REQUEST: 'REQUEST',
  Header.RESPONSE: 'RESPONSE',
  Header.CONFIRM: 'CONFIRM',
  Header.ERROR: 'ERROR',
  Header.PONG: 'PONG',
  Header.PING: 'PING',
};

const _$CommandEnumMap = {
  Command.USRLOGIN: 'USRLOGIN',
  Command.CHATMESSAGE: 'CHATMESSAGE',
  Command.USERONLINELIST: 'USERONLINELIST',
  Command.PRIVATEMESSAGE: 'PRIVATEMESSAGE',
  Command.CALLPRIVATECHAT: 'CALLPRIVATECHAT',
  Command.CALLREMOTEUSER: 'CALLREMOTEUSER',
  Command.CHATONLINELIST: 'CHATONLINELIST',
  Command.ROOMLIST: 'ROOMLIST',
  Command.LEAVEPRIVATECHAT: 'LEAVEPRIVATECHAT',
  Command.UPDATEUSER: 'UPDATEUSER',
};

UpdateUserDataset _$UpdateUserDatasetFromJson(Map<String, dynamic> json) =>
    UpdateUserDataset(
      identity: json['IDENTITY'] as String,
      nickname: json['NICKNAME'] as String?,
      foregroundColor: (json['FOREGROUND_COLOR'] as num?)?.toInt(),
      backgroundColor: (json['BACKGROUND_COLOR'] as num?)?.toInt(),
      language: json['LANGUAGE'] as String?,
    );

Map<String, dynamic> _$UpdateUserDatasetToJson(UpdateUserDataset instance) =>
    <String, dynamic>{
      'IDENTITY': instance.identity,
      if (instance.nickname case final value?) 'NICKNAME': value,
      if (instance.foregroundColor case final value?) 'FOREGROUND_COLOR': value,
      if (instance.backgroundColor case final value?) 'BACKGROUND_COLOR': value,
      if (instance.language case final value?) 'LANGUAGE': value,
    };
