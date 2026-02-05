import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/language_cubit.dart';
import 'core/constants/api_constants.dart';
import 'core/network/websocket_service.dart';
import 'core/utils/go_router_refresh_stream.dart'; // Add import

import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/theme_repository.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/chat_repository.dart';

import 'presentation/bloc/auth_bloc.dart';
import 'presentation/bloc/auth_state.dart';
import 'presentation/bloc/user_list_bloc.dart';
import 'presentation/bloc/chat_bloc.dart';
import 'presentation/bloc/settings_bloc.dart';

import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/chat_page.dart';
import 'presentation/pages/settings_page.dart';

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

// Router needs to be created after AuthBloc is available
GoRouter _createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(context.read<AuthBloc>().stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is SignInSuccess;
      final isGoingToLogin = state.matchedLocation == '/';

      final isGoingToRegister = state.matchedLocation == '/register';

      // If not logged in...
      if (!isLoggedIn) {
        // Allow access to login and register pages
        if (isGoingToLogin || isGoingToRegister) {
            return null;
        }
        // Otherwise redirect to login
        return '/';
      }

      // If logged in and on login/register page, redirect to home
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
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
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

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
          ),
          BlocProvider(
             create: (context) => SettingsBloc(authRepository: _authRepository),
          ),
          BlocProvider(
             create: (context) => ThemeCubit(),
          ),
          BlocProvider(
             create: (context) => LanguageCubit(
                themeRepository: ThemeRepository(),
             )..loadSavedLanguage(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                return MaterialApp.router(
                  title: 'Javacomm Client',
                  theme: themeState.themeData,
                  locale: locale, // Dynamic Locale
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('de'), // German (Default)
                    Locale('en'), // English
                    Locale('es'), // Spanish
                  ],
                  routerConfig: _createRouter(context),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
