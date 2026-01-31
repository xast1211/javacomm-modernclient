// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_remote_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallRemoteUser _$CallRemoteUserFromJson(Map<String, dynamic> json) =>
    CallRemoteUser(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CallRemoteUserToJson(CallRemoteUser instance) =>
    <String, dynamic>{
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
      'DATASET': instance.dataset,
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
  Command.KEEPALIVE: 'KEEPALIVE',
  Command.USERONLINELIST: 'USERONLINELIST',
  Command.PRIVATEMESSAGE: 'PRIVATEMESSAGE',
  Command.CALLPRIVATECHAT: 'CALLPRIVATECHAT',
  Command.CALLREMOTEUSER: 'CALLREMOTEUSER',
  Command.CHATONLINELIST: 'CHATONLINELIST',
  Command.ROOMLIST: 'ROOMLIST',
  Command.LEAVEPRIVATECHAT: 'LEAVEPRIVATECHAT',
};
