import 'package:flutter/material.dart';
import 'config.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ShayanPharmaGuideApp());
}

class ShayanPharmaGuideApp extends StatelessWidget {
  const ShayanPharmaGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
