import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import '../../domain/repositories/auth_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // State
  bool _changePassword = false;
  bool _initialized = false;
  
  // Colors (int values like 0xFFRRGGBB)
  int _fgColor = 0xFF000000;
  int _bgColor = 0xFFFFFFFF;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      final authState = context.read<AuthBloc>().state;
      
      if (authState is SignInSuccess) {
        _nicknameController = TextEditingController(text: authState.nickname ?? '');
        _emailController = TextEditingController(text: authState.email ?? '');
        _fgColor = authState.foregroundColor ?? 0xFF000000;
        _bgColor = authState.backgroundColor ?? 0xFFFFFFFF;
      } else {
        _nicknameController = TextEditingController();
        _emailController = TextEditingController();
      }
      
      _passwordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSave(String userId) {
      if (_formKey.currentState!.validate()) {
          context.read<SettingsBloc>().add(
            UpdateProfile(
               userId: userId,
               nickname: _nicknameController.text,
               email: _emailController.text,
               password: _changePassword ? _passwordController.text : null,
               foregroundColor: _fgColor,
               backgroundColor: _bgColor,
            )
          );
      }
  }

  Widget _buildRGBPicker(String label, int colorValue, ValueChanged<int> onChanged) {
    Color c = Color(colorValue);
    int r = c.red;
    int g = c.green;
    int b = c.blue;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSlider(AppLocalizations.of(context)!.colorRed, r, Colors.red, (val) {
               onChanged(Color.fromARGB(255, val, g, b).value);
            }),
            _buildSlider(AppLocalizations.of(context)!.colorGreen, g, Colors.green, (val) {
               onChanged(Color.fromARGB(255, r, val, b).value);
            }),
            _buildSlider(AppLocalizations.of(context)!.colorBlue, b, Colors.blue, (val) {
               onChanged(Color.fromARGB(255, r, g, val).value);
            }),
            const SizedBox(height: 8),
            // Hex Input
            Row(
               children: [
                  Text(AppLocalizations.of(context)!.hexColorLabel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 30, // smaller input
                      child: TextField(
                        controller: TextEditingController(text: colorValue.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)),
                        decoration: const InputDecoration(
                           contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                           border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontFamily: 'monospace'),
                        onSubmitted: (val) {
                           // Parse Hex
                           try {
                              int parsed = int.parse('0xFF$val');
                              onChanged(parsed);
                           } catch (e) {
                              // ignore invalid hex
                           }
                        },
                      ),
                    ),
                  ),
               ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, int value, Color activeColor, ValueChanged<int> onChanged) {
     return Row(
        children: [
           SizedBox(width: 50, child: Text(label)),
           Expanded(
              child: Slider(
                 value: value.toDouble(),
                 min: 0,
                 max: 255,
                 activeColor: activeColor,
                 onChanged: (double v) => onChanged(v.toInt()),
              ),
           ),
           SizedBox(width: 35, child: Text('${value}')),
        ],
     );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    
    // Only proceed if user is signed in
    if (authState is! SignInSuccess) {
        return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.errorNotLoggedIn)));
    }
    
    final userId = authState.userId;

    if (userId == null) {
        return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.errorUserIdMissing)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountSettingsTitle),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
             builder: (context, state) {
                 if (state is SettingsLoading) {
                     return const Padding(
                       padding: EdgeInsets.symmetric(vertical: 8.0),
                       child: Center(child: CircularProgressIndicator()),
                     );
                 }
                 return ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16), // Comfortable padding
                     ),
                     onPressed: () => _onSave(userId), 
                     child: Text(AppLocalizations.of(context)!.saveChangesButton, style: const TextStyle(fontSize: 18)),
                 );
             },
          ),
        ),
      ),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
           if (state is SettingsSuccess) {
               context.read<AuthBloc>().add(UpdateLocalProfile(
                  nickname: _nicknameController.text,
                  email: _emailController.text,
                  foregroundColor: _fgColor,
                  backgroundColor: _bgColor,
               ));
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccess)),
               );
               context.pop();
           } else if (state is SettingsFailure) {
               final l10n = AppLocalizations.of(context)!;
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(l10n.updateFailedPrefix.replaceAll('{error}', state.error))),
               );
           }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
               TextFormField(
                   initialValue: userId,
                   decoration: InputDecoration(
                     labelText: AppLocalizations.of(context)!.userIdLabel,
                     prefixIcon: const Icon(Icons.person),
                     floatingLabelBehavior: FloatingLabelBehavior.always,
                   ),
                   readOnly: true,
               ),
               const SizedBox(height: 16),
               
               TextFormField(
                   controller: _nicknameController,
                   decoration: InputDecoration(labelText: AppLocalizations.of(context)!.nicknameLabel, prefixIcon: const Icon(Icons.badge)),
                   validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.validationRequired : null,
               ),
               const SizedBox(height: 16),
               
               TextFormField(
                   controller: _emailController,
                   decoration: InputDecoration(labelText: AppLocalizations.of(context)!.emailLabel, prefixIcon: const Icon(Icons.email)),
                   validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.validationRequired : null,
               ),
               const SizedBox(height: 24),

               _buildRGBPicker(AppLocalizations.of(context)!.textColorLabel, _fgColor, (val) => setState(() => _fgColor = val)),
               const SizedBox(height: 16),
               _buildRGBPicker(AppLocalizations.of(context)!.backgroundColorLabel, _bgColor, (val) => setState(() => _bgColor = val)),
               const SizedBox(height: 24),
               
               CheckboxListTile(
                   title: Text(AppLocalizations.of(context)!.changePasswordLabel),
                   value: _changePassword,
                   onChanged: (val) {
                       setState(() {
                           _changePassword = val ?? false;
                       });
                   },
               ),
               if (_changePassword) ...[
                   TextFormField(
                       controller: _passwordController,
                       decoration: InputDecoration(labelText: AppLocalizations.of(context)!.newPasswordLabel, prefixIcon: const Icon(Icons.lock)),
                       obscureText: true,
                       validator: (value) => (_changePassword && (value == null || value.isEmpty)) ? AppLocalizations.of(context)!.validationRequired : null,
                   ),
                   const SizedBox(height: 16),
                   TextFormField(
                       controller: _confirmPasswordController,
                       decoration: InputDecoration(labelText: AppLocalizations.of(context)!.confirmPasswordLabel, prefixIcon: const Icon(Icons.lock_clock)),
                       obscureText: true,
                       validator: (value) {
                           if (_changePassword && value != _passwordController.text) return AppLocalizations.of(context)!.validationPasswordMismatch;
                           return null;
                       },
                   ),
               ],
               const SizedBox(height: 20),
            
            
            ], // Close children list
          ),
        ),
      ),
    );
  }
}
