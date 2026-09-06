import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

/// Lets a student who forgot their password request a reset by email.
/// The backend (Apps Script) generates a fresh temporary password and
/// emails it to the address on file — this screen just triggers that
/// and shows the result.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;
  bool _sent = false;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _authService.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      setState(() => _sent = true);
    } else {
      setState(() => _error = result.message ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Forgot password',
            style: TextStyle(color: Colors.white)),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeSlideIn(
                  child: GlassCard(
                    child: _sent ? _buildSentState() : _buildFormState(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 52, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            'Enter the email you signed up with. '
            "We'll send a new temporary password to it.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: AppTheme.fieldDecoration(
              label: 'Email',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.coral)),
                  ),
          ),
          const SizedBox(height: 8),
          GradientButton(
            loading: _loading,
            label: 'Send new password',
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 52, color: AppColors.tealLight),
        const SizedBox(height: 16),
        Text(
          'If an account exists for ${_emailController.text.trim()}, '
          'a new password has been sent to it. Check your inbox '
          '(and spam folder), then log in and change it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 24),
        GradientButton(
          loading: false,
          label: 'Back to login',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
