// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usrlogin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsrLogin _$UsrLoginFromJson(Map<String, dynamic> json) => UsrLogin(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
      identity: json['IDENTITY'] as String?,
    );

Map<String, dynamic> _$UsrLoginToJson(UsrLogin instance) => <String, dynamic>{
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
      'DATASET': instance.dataset,
      'IDENTITY': instance.identity,
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
  Command.UPDATEUSER: 'UPDATEUSER',
};
