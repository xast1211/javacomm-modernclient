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
  }
  
  Future<void> _onBiometricPress() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final creds = await _biometricService.getCredentials();
      if (creds != null && mounted) {
        final email = creds['email']!;
        final password = creds['password']!;
        
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
    
    // Background Color from Reference (Dark Olive - Adjusted)
    final backgroundColor = const Color(0xFF2E2B11); 
    final textColor = const Color(0xFFF0E6D2); // Light beige/white for contrast

    return Scaffold(
      backgroundColor: backgroundColor,
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
            
            final currentEmail = _emailController.text;
            final currentPass = _passwordController.text;
            
            if (currentEmail.isNotEmpty && currentPass.isNotEmpty) {
                 final storedCreds = await _biometricService.getCredentials();
                 bool shouldSave = true;

                 if (storedCreds != null) {
                     final storedEmail = storedCreds['email'];
                     if (storedEmail != null && storedEmail != currentEmail) {
                         if (context.mounted) {
                             final confirmUrl = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                    title: const Text('Biometrie update'),
                                    content: Text('Es sind Daten für "$storedEmail" gespeichert.\nMöchten Sie diese mit "$currentEmail" überschreiben?'),
                                    actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nein')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ja, überschreiben')),
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

            final userId = state.response.userid ?? l10n.unknownUser;
            final nickname = state.response.nickname ?? l10n.guestUser;
            final sessionId = state.response.sessionId;
            
            context.read<ChatRepository>().initializeUser(userId, nickname, sessionId: sessionId);
            context.read<ThemeCubit>().loadSavedTheme(userId: userId);
            context.read<LanguageCubit>().loadSavedLanguage(userId: userId);
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     // Logo
                     Image.asset(
                       'assets/images/dukeplug.png',
                       height: 120, // Adjust size as needed
                     ),
                     const SizedBox(height: 40),
                     
                     // Language Row
                     _buildInputRow(
                       label: l10n.labelLanguage,
                       textColor: textColor,
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12),
                         decoration: BoxDecoration(
                           color: Colors.white, // Requested white background
                           borderRadius: BorderRadius.circular(4),
                         ),
                         child: BlocBuilder<LanguageCubit, Locale>(
                           builder: (context, locale) {
                             return DropdownButtonHideUnderline(
                               child: DropdownButton<Locale>(
                                 value: locale,
                                 isExpanded: true,
                                 icon: const Icon(Icons.arrow_drop_down, color: Colors.green), // Green arrow like image? Or standard
                                 dropdownColor: Colors.white,
                                 items: [
                                   DropdownMenuItem(value: const Locale('de'), child: Text(l10n.languageDeutsch)),
                                   DropdownMenuItem(value: const Locale('en'), child: Text(l10n.languageEnglish)),
                                   DropdownMenuItem(value: const Locale('es'), child: Text(l10n.languageEspanol)),
                                 ],
                                 onChanged: (Locale? newLocale) {
                                   if (newLocale != null) {
                                     context.read<LanguageCubit>().changeLanguage(newLocale);
                                   }
                                 },
                               ),
                             );
                           },
                         ),
                       ),
                     ),
                     const SizedBox(height: 16),
                     
                     // Email Row
                     _buildInputRow(
                       label: l10n.labelEmailOrUser,
                       textColor: textColor,
                       child: Container(
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: Colors.blueAccent, width: 2), // Blue border like image?
                         ),
                         child: TextFormField(
                           controller: _emailController,
                           decoration: const InputDecoration(
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                             isDense: true,
                           ),
                           style: const TextStyle(color: Colors.black),
                           validator: (value) {
                             if (value == null || value.isEmpty) return l10n.validationEmailRequired;
                             return null;
                           },
                         ),
                       ),
                     ),
                     const SizedBox(height: 16),
                     
                     // Password Row
                     _buildInputRow(
                       label: l10n.labelPassword,
                       textColor: textColor,
                       child: Container(
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(4),
                         ),
                         child: TextFormField(
                           controller: _passwordController,
                           obscureText: true,
                           textInputAction: TextInputAction.done,
                           onFieldSubmitted: (_) => _onLogin(),
                           decoration: const InputDecoration(
                             border: InputBorder.none,
                             contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                             isDense: true,
                             hintText: '********',
                           ),
                           style: const TextStyle(color: Colors.black),
                           validator: (value) {
                             if (value == null || value.isEmpty) return l10n.validationPasswordRequired;
                             return null;
                           },
                         ),
                       ),
                     ),
                     const SizedBox(height: 40),
                     
                     // Confidentiality Note
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text(
                           l10n.confidentialityNote,
                           style: TextStyle(color: textColor, fontSize: 14),
                         ),
                         const SizedBox(width: 8),
                         Image.asset(
                           'assets/images/chip.png',
                           height: 24,
                           width: 24,
                         ),
                       ],
                     ),
                     const SizedBox(height: 30),
                     
                      // Login Button (Thumb Up)
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: _onLogin,
                          icon: Image.asset(
                            'assets/images/thumb_up.png',
                            height: 24,
                            width: 24, 
                          ),
                          label: Text(
                            l10n.loginButton,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: backgroundColor, // Match page background
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Rounded corners
                              side: const BorderSide(color: Colors.white, width: 1), // White border
                            ),
                          ),
                        ),
                      ),
                     
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/register'),
                          icon: const Icon(Icons.person_add, size: 24, color: Colors.white),
                          label: Text(
                            l10n.registerButton,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: backgroundColor, // Match page background
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ),
                      
                      if (_canCheckBiometrics) ...[
                       const SizedBox(height: 20),
                       IconButton(
                         icon: const Icon(Icons.fingerprint, size: 40, color: Colors.white),
                         tooltip: 'Biometric Login',
                         onPressed: _onBiometricPress,
                       )
                     ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow({required String label, required Color textColor, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120, // Fixed width for labels to align
          child: Text(
            label,
            style: TextStyle(color: textColor, fontSize: 16),
          ),
        ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
