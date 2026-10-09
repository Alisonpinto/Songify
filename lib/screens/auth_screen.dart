import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate all visible fields before hitting the network.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rawName = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        // After signup, we need to create the user profile if they registered successfully.
        // We will insert into the users table using their new auth.uid.
        // Issue #3: this upsert is wrapped independently so that a transient
        // failure (network error, RLS timing) does not abort the auth flow.
        // If it fails, _recoverMissingProfile in AppState.loadSavedTracks will
        // recreate the row idempotently on the next session load.
        if (response.user != null) {
          final userId = response.user!.id;
          final handle = normaliseHandle(rawName.replaceAll(' ', '').toLowerCase());

          try {
            await Supabase.instance.client.from('users').upsert({
              'id': userId,
              'name': rawName,
              'handle': handle,
              'email': email,
            });
          } catch (profileError) {
            // Non-fatal: the auth account exists; profile will be recovered on
            // next load.  Log for debugging without surfacing to the user.
            debugPrint('Warning: profile creation failed after signup: $profileError');
          }
        }

        if (response.session == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created! Please check your email to confirm, OR if you disabled confirmations, make sure you clicked Save in Supabase.')),
            );
          }
          return; // Stop execution so it doesn't pop or load tracks as guest
        }
      }
      if (mounted) {
        await Provider.of<AppState>(context, listen: false).loadSavedTracks();
        if (mounted) {
          Navigator.pop(context); // Go back after success
        }
      }
    } on AuthException catch (e) {
      // Surface Supabase Auth errors with a friendlier message where possible.
      if (mounted) {
        final message = _mapAuthError(e.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Maps common Supabase Auth error messages to user-facing strings.
  String _mapAuthError(String supabaseMessage) {
    final msg = supabaseMessage.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return 'An account with this email already exists. Try logging in instead.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    if (msg.contains('password')) {
      return 'Password does not meet requirements. Use at least 6 characters.';
    }
    return supabaseMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Log in to save your playlists' : 'Sign up to build your library',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (!_isLogin) ...[
                  _buildFormField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline_rounded,
                    validator: (value) => validateName(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildFormField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => validateEmail(value ?? ''),
                ),
                const SizedBox(height: 16),

                _buildFormField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (value) => validatePassword(value ?? ''),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 2),
                        )
                      : Text(
                          _isLogin ? 'Log In' : 'Sign Up',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      // Clear validation errors when switching modes.
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(
                    _isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Log In',
                    style: const TextStyle(
                      color: AppTheme.primaryYellow,
                      fontSize: 16,
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator != null ? (value) => validator(value ?? '') : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
    );
  }
}
