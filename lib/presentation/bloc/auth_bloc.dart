import 'dart:async'; // Required for StreamSubscription
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/signin_response.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final ChatRepository chatRepository;

  StreamSubscription<SignInResponse>? _userSubscription;

  AuthBloc({
    required this.authRepository, 
    required this.chatRepository
  }) : super(AuthInitial()) {
    // on<UpdateLocalProfile>(_onUpdateLocalProfile); // Removed legacy handler
    on<SignInRequested>(_onSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);
    
    _userSubscription = authRepository.userUpdates.listen((user) {
      add(AuthUserUpdated(user));
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Disconnect WebSocket
    await authRepository.disconnect();
    
    // 2. Clear Session Data in Repositories
    chatRepository.disconnect();
    
    // 3. Emit Initial State to trigger Router Redirect
    emit(AuthInitial());
  }

  void _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state is SignInSuccess) {
      final currentResponse = (state as SignInSuccess).response;
      
      // Merge updates: Event response might have nulls for unchanged fields
      final newResponse = event.response;
      
      final updatedResponse = currentResponse.copyWith(
        email: newResponse.email, 
        nickname: newResponse.nickname,
        foregroundColor: newResponse.foregroundColor,
        backgroundColor: newResponse.backgroundColor,
        // language: newResponse.language // If we supported language in model
      );
      
      // Update Chat Repository
      chatRepository.initializeUser(
        updatedResponse.userid ?? 'Unknown',
        updatedResponse.nickname ?? 'Unknown',
        sessionId: updatedResponse.sessionId,
        foregroundColor: updatedResponse.foregroundColor,
        backgroundColor: updatedResponse.backgroundColor,
      );
      
      emit(SignInSuccess(updatedResponse));
    }
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
            sessionId: response.sessionId,
            foregroundColor: response.foregroundColor,
            backgroundColor: response.backgroundColor,
         );
         emit(SignInSuccess(response));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
