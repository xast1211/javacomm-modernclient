import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'message.dart';

part 'usrlogin.g.dart';

@JsonSerializable(explicitToJson: true)
class UsrLogin extends Message {
  @JsonKey(name: 'DATASET')
  final Map<String, dynamic> dataset;

  @JsonKey(name: 'IDENTITY')
  final String? identity;

  UsrLogin({
    required super.header,
    required super.command,
    required this.dataset,
    this.identity,
  });

  factory UsrLogin.fromJson(Map<String, dynamic> json) => _$UsrLoginFromJson(json);
  
  @override
  Map<String, dynamic> toJson() => _$UsrLoginToJson(this);
  
  // Helper getters for dataset fields
  String? get nickname => dataset['NICKNAME'] as String?;
  int? get foregroundColor => dataset['FOREGROUND_COLOR'] as int?;
  int? get backgroundColor => dataset['BACKGROUND_COLOR'] as int?;
  int? get volume => dataset['VOLUME'] as int?;
  bool? get oncall => dataset['ONCALL'] as bool?;
  String? get session => dataset['SESSION'] as String?;
}
