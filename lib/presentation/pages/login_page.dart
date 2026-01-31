import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../domain/repositories/chat_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'xast@xast.de');
  final _passwordController = TextEditingController(text: 'LarsBabs');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;
      // Use current locale or allow selection. Default to 'de' if context not available?
      // AppLocalizations.of(context)!.localeName might differ from API expected 'de' or 'en'
      final lang = AppLocalizations.of(context)?.localeName.split('_').first ?? 'en';
      
      context.read<AuthBloc>().add(SignInRequested(email: email, password: password, lang: lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SignInSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Sign In Successful')),
            );
            
            // Initialize Chat Repos
            final userId = state.response.userid ?? 'unknown';
            final nickname = state.response.nickname ?? 'Guest';
            final sessionId = state.response.sessionId;
            
            context.read<ChatRepository>().initializeUser(userId, nickname, sessionId: sessionId);
            
            // Navigate to Home
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   TextFormField(
                     controller: _emailController,
                     decoration: InputDecoration(
                       labelText: l10n.loginUsernameHint, // Or Email hint
                       hintText: 'user@example.com',
                     ),
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please enter email';
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                     controller: _passwordController,
                     decoration: InputDecoration(
                       labelText: l10n.loginPasswordHint,
                       hintText: '********',
                     ),
                     obscureText: true,
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please enter password';
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: _onLogin,
                     child: Text(l10n.loginButton),
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
