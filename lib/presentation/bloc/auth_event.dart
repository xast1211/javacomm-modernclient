import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  final String lang;

  const SignInRequested({required this.email, required this.password, required this.lang});

  @override
  List<Object> get props => [email, password, lang];
}

class UpdateLocalProfile extends AuthEvent {
  final String? nickname;
  final String? email;
  final int? foregroundColor;
  final int? backgroundColor;

  const UpdateLocalProfile({
    this.nickname, 
    this.email,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  List<Object> get props => [
    if (nickname != null) nickname!, 
    if (email != null) email!,
    if (foregroundColor != null) foregroundColor!,
    if (backgroundColor != null) backgroundColor!,
  ];
}
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthUserUpdated extends AuthEvent {
  final dynamic response; // Using dynamic or SignInResponse if imported
  // Ideally import SignInResponse in auth_event.dart or keep it loose.
  // Using dynamic to avoid circular dep if models depend on bloc (unlikely).
  // Better: import '../item_that_has_response.dart'
  // But strictly: AuthEvent needs to know about SignInResponse.
  const AuthUserUpdated(this.response);
  
  @override
  List<Object> get props => [response];
}
