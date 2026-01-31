import 'package:json_annotation/json_annotation.dart';

enum Header {
  @JsonValue('REQUEST')
  REQUEST,
  @JsonValue('RESPONSE')
  RESPONSE,
  @JsonValue('CONFIRM')
  CONFIRM,
  @JsonValue('ERROR')
  ERROR,
  @JsonValue('PONG')
  PONG, 
  @JsonValue('PING')
  PING// Add others as needed
}

enum Command {
  @JsonValue('USRLOGIN')
  USRLOGIN,
  @JsonValue('CHATMESSAGE')
  CHATMESSAGE,
  @JsonValue('KEEPALIVE')
  KEEPALIVE,
  @JsonValue('USERONLINELIST')
  USERONLINELIST,
  @JsonValue('PRIVATEMESSAGE')
  PRIVATEMESSAGE,
  @JsonValue('CALLPRIVATECHAT')
  CALLPRIVATECHAT,
  @JsonValue('CALLREMOTEUSER')
  CALLREMOTEUSER,
  @JsonValue('CHATONLINELIST')
  CHATONLINELIST,
  @JsonValue('ROOMLIST')
  ROOMLIST,
  @JsonValue('LEAVEPRIVATECHAT')
  LEAVEPRIVATECHAT,
  @JsonValue('UPDATEUSER')
  UPDATEUSER,
  // Add others as needed
}

enum Agent {
  @JsonValue('Desktop')
  Desktop,
  @JsonValue('Android')
  Android,
  @JsonValue('iOS')
  iOS,
  @JsonValue('Web')
  Web,
  @JsonValue('Browser')
  Browser
}
