import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/badges.dart';

import '../../../../core/auth/domain/repositories/auth_repository.dart';
import '../../../../app/di/injection.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      // Race guard: the auth redirect may already have moved away from
      // splash (e.g. session restore completing mid-timer). Never issue a
      // second navigation when this screen is no longer the location —
      // overlapping go() + redirect evaluations duplicate Navigator pages.
      String location = AppRoutes.splash;
      try {
        location = GoRouterState.of(context).matchedLocation;
      } catch (_) {}
      if (location != AppRoutes.splash) return;
      // Session restoration belongs to Supabase Auth only: a valid
      // Supabase session restores to Home without requiring FastAPI.
      final authRepo = getIt.isRegistered<AuthRepository>() ? getIt<AuthRepository>() : null;
      if (authRepo != null && authRepo.isAuthenticated) {
        debugPrint('[Auth] Session restored');
        context.go(AppRoutes.home);
      } else {
        debugPrint('[Auth] No Supabase session to restore');
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // App Emblem
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_library_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appHindiName,
                    style: AppTypography.devanagariHeading.copyWith(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.appTagline,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const NipunBadge(),
                  const Spacer(),
                  // Bottom indicator — clean, teacher-friendly only.
                  const OfflineBadge(),
                  const SizedBox(height: 12),
                  Text(
                    'Same Learning. In Every Child\u2019s Language.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
