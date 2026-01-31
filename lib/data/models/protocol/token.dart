import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';

@JsonSerializable()
class Token {
  @JsonKey(name: 'USERID')
  String? userid;
  @JsonKey(name: 'EMAIL')
  String? email;
  @JsonKey(name: 'PASSWORD')
  String? password;
  @JsonKey(name: 'AES')
  String? aes;
  @JsonKey(name: 'ONETIME')
  String? onetime;

  Token({this.userid, this.email, this.password, this.aes, this.onetime});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
  Map<String, dynamic> toJson() => _$TokenToJson(this);

  @override
  String toString() {
    return jsonEncode(toJson()); 
  }
}
