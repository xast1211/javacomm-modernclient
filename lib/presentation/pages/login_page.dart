import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/theme/language_cubit.dart';
import '../../core/auth/biometric_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _formKey = GlobalKey<FormState>();
  final _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _tryBiometricLogin();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricAvailable;
    final creds = await _biometricService.getCredentials();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = available && creds != null;
      });
    }
  }
  
  Future<void> _tryBiometricLogin({bool auto = false}) async {
    if (!_canCheckBiometrics && auto) return;
    
    // Only auto-login if explicitly requested or maybe just show button?
    // User requested "can I unlock with...?" so existing users expect a button or prompt.
  }
  
  Future<void> _onBiometricPress() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final creds = await _biometricService.getCredentials();
      if (creds != null && mounted) {
        final email = creds['email']!;
        final password = creds['password']!;
        
        // Populate controllers so listener logic works correctly
        _emailController.text = email;
        _passwordController.text = password;
        
        final lang = AppLocalizations.of(context)?.localeName.split('_').first ?? 'en';
        context.read<AuthBloc>().add(SignInRequested(email: email, password: password, lang: lang));
      }
    }
  }

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
      final lang = AppLocalizations.of(context)?.localeName.split('_').first ?? 'en';
      
      context.read<AuthBloc>().add(SignInRequested(email: email, password: password, lang: lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        actions: [
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                tooltip: l10n.languageTooltip,
                onSelected: (Locale result) {
                  context.read<LanguageCubit>().changeLanguage(result);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('de'),
                    checked: locale.languageCode == 'de',
                    child: Text(l10n.languageDeutsch),
                  ),
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('en'),
                    checked: locale.languageCode == 'en',
                    child: Text(l10n.languageEnglish),
                  ),
                  CheckedPopupMenuItem<Locale>(
                    value: const Locale('es'),
                    checked: locale.languageCode == 'es',
                    child: Text(l10n.languageEspanol),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is SignInSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(l10n.signInSuccessful)),
            );
            
            // Check if we need to update/overwrite biometric credentials
            final currentEmail = _emailController.text;
            final currentPass = _passwordController.text;
            
            if (currentEmail.isNotEmpty && currentPass.isNotEmpty) {
                 final storedCreds = await _biometricService.getCredentials();
                 bool shouldSave = true;

                 if (storedCreds != null) {
                     final storedEmail = storedCreds['email'];
                     if (storedEmail != null && storedEmail != currentEmail) {
                         // Different user! Prompt overwrite.
                         if (context.mounted) {
                             final confirmUrl = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                    title: const Text('Biometrie update'),
                                    content: Text('Es sind Daten für "$storedEmail" gespeichert.\nMöchten Sie diese mit "$currentEmail" überschreiben?'),
                                    actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Nein'),
                                        ),
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Ja, überschreiben'),
                                        ),
                                    ],
                                ),
                             );
                             shouldSave = confirmUrl ?? false;
                         }
                     }
                 }
                 
                 if (shouldSave) {
                     await _biometricService.saveCredentials(currentEmail, currentPass);
                 }
            }
            
            if (!context.mounted) return;

            // Initialize Chat Repos
            final userId = state.response.userid ?? l10n.unknownUser;
            final nickname = state.response.nickname ?? l10n.guestUser;
            final sessionId = state.response.sessionId;
            
            context.read<ChatRepository>().initializeUser(userId, nickname, sessionId: sessionId);
            
            // Load Saved Theme
            context.read<ThemeCubit>().loadSavedTheme(userId: userId);
            
            // Load Saved Language
            context.read<LanguageCubit>().loadSavedLanguage(userId: userId);

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
                       hintText: l10n.emailHintExample,
                     ),
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return l10n.validationEmailRequired;
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
                         return l10n.validationPasswordRequired;
                       }
                       return null;
                     },
                   ),
                   const SizedBox(height: 24),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       ElevatedButton(
                         onPressed: _onLogin,
                         child: Text(l10n.loginButton),
                       ),
                       if (_canCheckBiometrics) ...[
                         const SizedBox(width: 16),
                         IconButton(
                           icon: const Icon(Icons.fingerprint, size: 32),
                           tooltip: 'Biometric Login',
                           onPressed: _onBiometricPress,
                         )
                       ]
                     ],
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
