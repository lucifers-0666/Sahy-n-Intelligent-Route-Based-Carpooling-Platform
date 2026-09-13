import 'package:flutter/material.dart';
import 'package:sahyan/features/auth/presentation/screens/auth_decision_screen.dart';

/// Welcome / Auth Gateway Screen for Sahyān
/// Exposes the luxury Bento Auth Decision screen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthDecisionScreen();
  }
}
