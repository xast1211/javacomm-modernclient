import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'core/constants/api_constants.dart';
import 'core/network/websocket_service.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/chat_repository.dart';

import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/user_list_bloc.dart';
import 'presentation/bloc/chat_bloc.dart';

import 'presentation/pages/login_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/chat_page.dart';

void main() {
  runApp(const MyApp());
}

// Service & Repository DI setup
final _httpClient = http.Client();
final _webSocketService = WebSocketService();

final _authDataSource = AuthRemoteDataSourceImpl(client: _httpClient);

final _authRepository = AuthRepositoryImpl(
  remoteDataSource: _authDataSource,
  webSocketService: _webSocketService,
);

final _chatRepository = ChatRepositoryImpl(
  webSocketService: _webSocketService,
);

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return ChatPage(
          recipientUid: extras['uid'], 
          recipientNickname: extras['nick']
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ChatRepository>.value(value: _chatRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: _authRepository,
              chatRepository: _chatRepository,
            ),
          ),
          BlocProvider(
            create: (context) => UserListBloc(chatRepository: _chatRepository),
          ),
          BlocProvider(
             create: (context) => ChatBloc(chatRepository: _chatRepository),
          )
        ],
        child: MaterialApp.router(
          title: 'Javacomm Client',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('de'), // German
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
