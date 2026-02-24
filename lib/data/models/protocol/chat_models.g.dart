// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOnline _$UserOnlineFromJson(Map<String, dynamic> json) => UserOnline(
      userid: json['USERID'] as String? ?? '',
      nickname: json['NICKNAME'] as String? ?? 'Unknown',
      agent: $enumDecodeNullable(_$AgentEnumMap, json['AGENT']),
    );

Map<String, dynamic> _$UserOnlineToJson(UserOnline instance) =>
    <String, dynamic>{
      'USERID': instance.userid,
      'NICKNAME': instance.nickname,
      'AGENT': _$AgentEnumMap[instance.agent],
    };

const _$AgentEnumMap = {
  Agent.Desktop: 'Desktop',
  Agent.Android: 'Android',
  Agent.iOS: 'iOS',
  Agent.Web: 'Web',
  Agent.Browser: 'Browser',
};

UserOnlineList _$UserOnlineListFromJson(Map<String, dynamic> json) =>
    UserOnlineList(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$UserOnlineListToJson(UserOnlineList instance) =>
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
  Command.UPDATEUSER: 'UPDATEUSER',
};

PrivateMessage _$PrivateMessageFromJson(Map<String, dynamic> json) =>
    PrivateMessage(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PrivateMessageToJson(PrivateMessage instance) =>
    <String, dynamic>{
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
      'DATASET': instance.dataset,
    };

CallPrivateChat _$CallPrivateChatFromJson(Map<String, dynamic> json) =>
    CallPrivateChat(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CallPrivateChatToJson(CallPrivateChat instance) =>
    <String, dynamic>{
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
      'DATASET': instance.dataset,
    };

LeavePrivateChat _$LeavePrivateChatFromJson(Map<String, dynamic> json) =>
    LeavePrivateChat(
      header: $enumDecode(_$HeaderEnumMap, json['HEADER']),
      command: $enumDecode(_$CommandEnumMap, json['COMMAND']),
      dataset: json['DATASET'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LeavePrivateChatToJson(LeavePrivateChat instance) =>
    <String, dynamic>{
      'HEADER': _$HeaderEnumMap[instance.header]!,
      'COMMAND': _$CommandEnumMap[instance.command]!,
      'DATASET': instance.dataset,
    };
