import 'package:flutter/material.dart';
import 'welcome_screen.dart';

/// Legacy auth entry point forwarded to the redesigned 2026 WelcomeScreen
class AuthDecisionScreen extends StatelessWidget {
  const AuthDecisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
