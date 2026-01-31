import 'package:equatable/equatable.dart';
import '../../data/models/signin_response.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class SignInSuccess extends AuthState {
  final SignInResponse response;

  const SignInSuccess(this.response);
  
  String? get userId => response.userid;
  String? get nickname => response.nickname;
  String? get email => response.email;
  int? get foregroundColor => response.foregroundColor;
  int? get backgroundColor => response.backgroundColor;

  @override
  List<Object?> get props => [response];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
