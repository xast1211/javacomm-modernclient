import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'message.dart';

part 'call_remote_user.g.dart';

@JsonSerializable(explicitToJson: true)
class CallRemoteUser extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  CallRemoteUser({
    required super.header,
    required super.command,
    required this.dataset,
  });

  factory CallRemoteUser.fromJson(Map<String, dynamic> json) => _$CallRemoteUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CallRemoteUserToJson(this);

  // Helper getters
  // "Remote" in a Request usually refers to the Caller (Them)
  // "Local" in a Request usually refers to the Callee (Us)
  
  String get senderUid => dataset['SENDER_UID'] as String? ?? '';
  String get recipientUid => dataset['RECIPIENT_UID'] as String? ?? '';
  
  String get remoteNickname => dataset['REMOTE_NICKNAME'] as String? ?? '';
  String get localNickname => dataset['LOCAL_NICKNAME'] as String? ?? '';
  
  String get remoteSessionId => dataset['REMOTE_SESSIONID'] as String? ?? '';
  String get localSessionId => dataset['LOCAL_SESSIONID'] as String? ?? '';
}
