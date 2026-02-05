import 'package:json_annotation/json_annotation.dart';

part 'signin_response.g.dart';

@JsonSerializable()
class SignInResponse {
  final String header; // CONFIRM, ERROR, RESPONSE
  final String? userid;
  final String? email;
  final String? nickname;
  final String? password; // Encrypted or new?
  final int? foregroundColor;
  final int? backgroundColor;
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

  SignInResponse copyWith({
    String? header,
    String? userid,
    String? email,
    String? nickname,
    String? password,
    int? foregroundColor,
    int? backgroundColor,
    String? multilingualkey,
    String? text,
    String? errorCode,
    String? sessionId,
  }) {
    return SignInResponse(
      header: header ?? this.header,
      userid: userid ?? this.userid,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      password: password ?? this.password,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      multilingualkey: multilingualkey ?? this.multilingualkey,
      text: text ?? this.text,
      errorCode: errorCode ?? this.errorCode,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  factory SignInResponse.fromJson(Map<String, dynamic> json) => _$SignInResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignInResponseToJson(this);
}
