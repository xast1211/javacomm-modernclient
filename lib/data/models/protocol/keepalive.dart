
import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'message.dart';

part 'keepalive.g.dart';

@JsonSerializable(explicitToJson: true)
class KeepAlive extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  KeepAlive({
    required super.header,
    required super.command,
    required this.dataset,
  });

  factory KeepAlive.fromJson(Map<String, dynamic> json) => _$KeepAliveFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$KeepAliveToJson(this);
}
