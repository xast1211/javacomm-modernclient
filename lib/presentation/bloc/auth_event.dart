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
