import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text;
      final l10n = AppLocalizations.of(context)!;

      try {
        await context.read<AuthRepository>().register(email);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.registerSuccess)),
          );
          // Go back to login after success
          context.pop(); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Background Color from Reference (Dark Olive - Adjusted) matches Login Page
    final backgroundColor = const Color(0xFF2E2B11); 
    final textColor = const Color(0xFFF0E6D2); // Light beige/white for contrast

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
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
                   height: 100, 
                 ),
                 const SizedBox(height: 30),
                 
                 Text(
                   l10n.registerTitle,
                   style: TextStyle(
                     color: textColor,
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 10),
                 Text(
                   l10n.registerEmailNote,
                   style: TextStyle(color: textColor.withOpacity(0.8)),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 40),
                 
                 // Email Row
                 _buildInputRow(
                   label: l10n.emailLabel,
                   textColor: textColor,
                   child: Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(4),
                       border: Border.all(color: Colors.blueAccent, width: 2),
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
                         if (!value.contains('@')) return 'Invalid Email';
                         return null;
                       },
                     ),
                   ),
                 ),
                 const SizedBox(height: 40),
                 
                 // Register Button
                 _isLoading 
                   ? const CircularProgressIndicator()
                   : ElevatedButton.icon(
                       onPressed: _onRegister,
                       icon: const Icon(Icons.person_add, color: Colors.black),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
