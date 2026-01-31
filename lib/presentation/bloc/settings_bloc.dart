import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';

// States
abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsSuccess extends SettingsState {}
class SettingsFailure extends SettingsState {
  final String error;
  const SettingsFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class UpdateProfile extends SettingsEvent {
  final String userId;
  final String? nickname;
  final String? email;
  final String? password;
  final int? foregroundColor;
  final int? backgroundColor;

  const UpdateProfile({
    required this.userId,
    this.nickname,
    this.email,
    this.password,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  List<Object?> get props => [userId, nickname, email, password, foregroundColor, backgroundColor];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final AuthRepository authRepository;

  SettingsBloc({required this.authRepository}) : super(SettingsInitial()) {
    on<UpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      await authRepository.updateProfile(
        event.userId,
        nickname: event.nickname,
        email: event.email,
        password: event.password,
        foregroundColor: event.foregroundColor,
        backgroundColor: event.backgroundColor,
      );
      // Assuming success if no error thrown immediately.
      // Ideally we should wait for server confirmation, but for now we follow 'fire and forget' or assume optimistic success.
      emit(SettingsSuccess());
    } catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }
}
