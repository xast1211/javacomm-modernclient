// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
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
  Command.KEEPALIVE: 'KEEPALIVE',
  Command.USERONLINELIST: 'USERONLINELIST',
  Command.PRIVATEMESSAGE: 'PRIVATEMESSAGE',
  Command.CALLPRIVATECHAT: 'CALLPRIVATECHAT',
  Command.CALLREMOTEUSER: 'CALLREMOTEUSER',
  Command.CHATONLINELIST: 'CHATONLINELIST',
  Command.ROOMLIST: 'ROOMLIST',
  Command.LEAVEPRIVATECHAT: 'LEAVEPRIVATECHAT',
};
