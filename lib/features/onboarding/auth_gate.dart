// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../onboarding/welcome_screen.dart';
import '../../core/navigation/main_shell.dart';

/// Gate widget that determines whether the user should see the onboarding/welcome flow
/// or access the application's authenticated sections.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;
  Session? _session;
  late final dynamic _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _listenToAuthChanges();
  }

  void _checkInitialSession() {
    final currentSession = Supabase.instance.client.auth.currentSession;
    setState(() {
      _session = currentSession;
      _initialized = true;
    });
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _session = data.session;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return _SplashLoadingScreen();
    }

    if (_session != null) {
      return MainShell(initialIndex: 0);
    }

    return WelcomeScreen();
  }
}

class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                PhosphorIcons.globe,
                size: 36,
                color: AppColors.secondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Fulɓe Connect',
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
