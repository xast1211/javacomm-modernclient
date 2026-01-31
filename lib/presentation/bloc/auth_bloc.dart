import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final ChatRepository chatRepository;

  AuthBloc({
    required this.authRepository, 
    required this.chatRepository
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.signIn(event.email, event.password, event.lang);
      // Logic from JChat:
      // If header == CONFIRM -> New User, requires confirmation?
      // If header == ERROR -> Show error message
      // If header == RESPONSE -> Request new password?
      // For now, we just emit Success and let UI handle the response types.
      
      if (response.header == 'ERROR') {
         emit(AuthFailure(response.text ?? 'Unknown error'));
      } else {
         // CRITICAL Fix: Initialize ChatRepository with the logged-in user
         chatRepository.initializeUser(
            response.userid ?? response.email ?? 'Unknown', 
            response.nickname ?? response.userid ?? response.email ?? 'Unknown', // Nickname fallback
            sessionId: response.sessionId
         );
         emit(SignInSuccess(response));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
