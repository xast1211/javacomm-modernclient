import 'package:json_annotation/json_annotation.dart';

part 'signin_response.g.dart';

@JsonSerializable()
class SignInResponse {
  final String header; // CONFIRM, ERROR, RESPONSE
  final String? userid;
  final String? email;
  final String? nickname;
  final String? password; // Encrypted or new?
  final String? foregroundColor;
  final String? backgroundColor;
  final String? multilingualkey;
  final String? text;
  final String? errorCode;
  final String? sessionId;

  SignInResponse({
    required this.header,
    this.userid,
    this.email,
    this.nickname,
    this.password,
    this.foregroundColor,
    this.backgroundColor,
    this.multilingualkey,
    this.text,
    this.errorCode,
    this.sessionId,
  });

  factory SignInResponse.fromJson(Map<String, dynamic> json) => _$SignInResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignInResponseToJson(this);
}
