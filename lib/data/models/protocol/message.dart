import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';

part 'message.g.dart';

@JsonSerializable(explicitToJson: true)
class Message {
  @JsonKey(name: 'HEADER')
  final Header header;
  @JsonKey(name: 'COMMAND')
  final Command command;

  Message({required this.header, required this.command});

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
