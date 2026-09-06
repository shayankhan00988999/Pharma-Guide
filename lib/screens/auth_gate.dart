import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/animated_gradient_background.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Checked once at app launch. If a session token is already saved in
/// secure storage, the student skips straight to the folder browser —
/// this is what gives the "never auto logout" behavior, since nothing
/// here ever clears or expires that token on its own.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: AnimatedGradientBackground(
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        return snapshot.data == true ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
