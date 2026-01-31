import 'package:json_annotation/json_annotation.dart';
import 'message.dart';
import 'enums.dart';

part 'update_user.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UpdateUser extends Message {
  @JsonKey(name: 'DATASET')
  final UpdateUserDataset? dataset;
  
  @override
  @JsonKey(name: 'HEADER')
  final Header header;

  @override
  @JsonKey(name: 'COMMAND')
  final Command command;

  UpdateUser({
    this.dataset,
    this.header = Header.REQUEST,
    this.command = Command.UPDATEUSER,
  }) : super(
          header: header,
          command: command,
        );

  factory UpdateUser.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    // Auto-generated method doesn't include base class fields
    // Order matters: HEADER, COMMAND, DATASET (same as JChat)
    final json = <String, dynamic>{};
    json['HEADER'] = 'REQUEST';
    json['COMMAND'] = 'UPDATEUSER';
    if (dataset != null) {
      json['DATASET'] = dataset!.toJson();
    }
    return json;
  }
}

@JsonSerializable(includeIfNull: false)
class UpdateUserDataset {
  @JsonKey(name: 'IDENTITY')
  final String identity;
  
  @JsonKey(name: 'NICKNAME')
  final String? nickname;
  
  @JsonKey(name: 'FOREGROUND_COLOR')
  final int? foregroundColor;
  
  @JsonKey(name: 'BACKGROUND_COLOR')
  final int? backgroundColor;

  UpdateUserDataset({
    required this.identity,
    this.nickname,
    this.foregroundColor,
    this.backgroundColor,
  });

  factory UpdateUserDataset.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserDatasetFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserDatasetToJson(this);
}
