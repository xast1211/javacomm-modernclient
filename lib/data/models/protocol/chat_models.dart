import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'message.dart';
import 'usrlogin.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class UserOnline {
  @JsonKey(name: 'USERID', defaultValue: '')
  final String userid;
  @JsonKey(name: 'NICKNAME', defaultValue: 'Unknown')
  final String nickname;
  @JsonKey(name: 'FOREGROUND_COLOR')
  final int? _foregroundColor;
  @JsonKey(name: 'BACKGROUND_COLOR')
  final int? _backgroundColor;
  @JsonKey(name: 'AGENT')
  final Agent? agent;

  UserOnline({
    required this.userid,
    this.nickname = 'Unknown',
    this.agent,
    int? foregroundColor,
    int? backgroundColor,
  }) : _foregroundColor = foregroundColor, _backgroundColor = backgroundColor;

  factory UserOnline.fromJson(Map<String, dynamic> json) => _$UserOnlineFromJson(json);
  Map<String, dynamic> toJson() => _$UserOnlineToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UserOnlineList extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;
  
  UserOnlineList({
    required super.header,
    required super.command,
    required this.dataset,
  });

  factory UserOnlineList.fromJson(Map<String, dynamic> json) => _$UserOnlineListFromJson(json);
  
  @override
  Map<String, dynamic> toJson() => _$UserOnlineListToJson(this);

  // Helper getters
  List<UserOnline>? get userOnline {
      try {
        if (dataset['USERONLINELIST'] != null) {
            final list = dataset['USERONLINELIST'] as List;
            print('UserOnlineList Getter: Found list with ${list.length} items. Header: $header');
            final parsedList = <UserOnline>[];
            for (var e in list) {
               try {
                 print('Parsing raw item: $e');
                 parsedList.add(UserOnline.fromJson(e as Map<String, dynamic>));
               } catch (e) {
                 print('Error parsing single UserOnline item: $e');
               }
            }
            return parsedList;
        } else {
            print('UserOnlineList Getter: DATASET["USERONLINELIST"] is null! Keys: ${dataset.keys}');
        }
      } catch (e) {
          print('Error in UserOnlineList.userOnline getter: $e');
      }
      return null;
  }
}

@JsonSerializable(explicitToJson: true)
class PrivateMessage extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  PrivateMessage({
    required super.header,
    required super.command,
    required this.dataset,
  });

  PrivateMessage copyWith({
    Header? header,
    Command? command,
    Map<String, dynamic>? dataset,
  }) {
    return PrivateMessage(
      header: header ?? this.header,
      command: command ?? this.command,
      dataset: dataset ?? this.dataset,
    );
  }

  factory PrivateMessage.fromJson(Map<String, dynamic> json) => _$PrivateMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PrivateMessageToJson(this);

  // Helper getters
  String get senderUid => dataset['SENDER_UID'] as String? ?? '';
  String? get localSessionId => dataset['LOCAL_SESSIONID'] as String?;
  String? get remoteSessionId => dataset['REMOTE_SESSIONID'] as String?;
  String get messageContent => dataset['MESSAGE'] as String? ?? '';
  int? get datetime => dataset['DATETIME'] as int?;
  
  Map<String, dynamic>? get _chatUser => dataset['CHATUSER'] as Map<String, dynamic>?;
  int? get senderForegroundColor => _chatUser?['FOREGROUND_COLOR'] as int?;
  int? get senderBackgroundColor => _chatUser?['BACKGROUND_COLOR'] as int?;
}

@JsonSerializable(explicitToJson: true)
class CallPrivateChat extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  CallPrivateChat({
    required super.header,
    required super.command,
    required this.dataset,
  });

  factory CallPrivateChat.fromJson(Map<String, dynamic> json) => _$CallPrivateChatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CallPrivateChatToJson(this);

  // Helper getters
  String get senderUid => dataset['SENDER_UID'] as String? ?? '';
  String get recipientUid => dataset['RECIPIENT_UID'] as String? ?? '';
  String get localNickname => dataset['LOCAL_NICKNAME'] as String? ?? '';
  String? get remoteNickname => dataset['REMOTE_NICKNAME'] as String?;
  String get localSessionId => dataset['LOCAL_SESSIONID'] as String? ?? '';
  String? get remoteSessionId => dataset['REMOTE_SESSIONID'] as String?;
}

@JsonSerializable(explicitToJson: true)
class LeavePrivateChat extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  LeavePrivateChat({
    required super.header,
    required super.command,
    required this.dataset,
  });

  factory LeavePrivateChat.fromJson(Map<String, dynamic> json) => _$LeavePrivateChatFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$LeavePrivateChatToJson(this);

  // Helper getters
  String get goneSessionId => dataset['GONE_SESSIONID'] as String? ?? '';
}
