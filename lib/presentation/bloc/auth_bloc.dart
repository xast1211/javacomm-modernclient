import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/signin_response.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final ChatRepository chatRepository;

  AuthBloc({
    required this.authRepository, 
    required this.chatRepository
  }) : super(AuthInitial()) {
    on<UpdateLocalProfile>(_onUpdateLocalProfile);
    on<SignInRequested>(_onSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Disconnect WebSocket
    await authRepository.disconnect();
    
    // 2. Clear Session Data in Repositories if needed
    // (ChatRepository might need a clear method, but initializedUser overwrites anyway)
    
    // 3. Emit Initial State to trigger Router Redirect
    emit(AuthInitial());
  }

  void _onUpdateLocalProfile(
    UpdateLocalProfile event,
    Emitter<AuthState> emit,
  ) {
    if (state is SignInSuccess) {
      final currentResponse = (state as SignInSuccess).response;
      // Define a copyWith method on SignInResponse or create new instance manually
      // Since SignInResponse fields are final, we create a new one updating only fields that are provided
      
      final updatedResponse = SignInResponse(
        header: currentResponse.header,
        userid: currentResponse.userid,
        email: event.email ?? currentResponse.email,
        nickname: event.nickname ?? currentResponse.nickname,
        password: currentResponse.password, // Keep password (encrypted or whatever)
        foregroundColor: event.foregroundColor ?? currentResponse.foregroundColor,
        backgroundColor: event.backgroundColor ?? currentResponse.backgroundColor,
        multilingualkey: currentResponse.multilingualkey,
        text: currentResponse.text,
        errorCode: currentResponse.errorCode,
        sessionId: currentResponse.sessionId,
      );
      
      // Update Chat Repository with new details
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
