import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../app/di/injection.dart';
import '../../../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          try {
            context.go(AppRoutes.home);
          } catch (_) {}
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static bool _isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty || v.length > 254 || v.contains(' ')) return false;
    final parts = v.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty || parts[1].isEmpty) return false;
    return parts[1].contains('.');
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(AuthSignInEvent(
          email: email,
          password: password,
          rememberMe: _rememberMe,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Non-blocking backend notice (e.g. server unreachable after a
            // successful Supabase login): the session stays valid and the
            // teacher still lands on Home for offline-capable use.
            if (state.backendNotice != null &&
                state.backendNotice!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.backendNotice!),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            try {
              if (state.profileNeedsCompletion) {
                // Existing account without a name/school on record: complete
                // the profile instead of landing on Home with a blank header.
                context.go(AppRoutes.teacherSetup,
                    extra: const {'completion': true});
              } else {
                context.read<TeacherProfileBloc>().add(LoadTeacherProfile());
                context.go(AppRoutes.home);
              }
            } catch (_) {}
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.accentRed,
              ),
            );
          } else if (state is Unauthenticated && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_library_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 26,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teacher Login (शिक्षक लॉगिन)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access your classroom resources',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Form Card
                      CustomCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Email ID
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: 'Email ID (ईमेल)',
                                  hintText: 'Enter your email (e.g. teacher@school.edu.in)',
                                  helperText: 'Registered email address',
                                  helperStyle: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email address.';
                                  }
                                  if (!_isValidEmail(val)) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 2. Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(context),
                                decoration: InputDecoration(
                                  labelText: 'Password (पासवर्ड)',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter your password.';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // 3. Remember Me Checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: isLoading
                                        ? null
                                        : (val) {
                                            setState(() {
                                              _rememberMe = val ?? false;
                                            });
                                          },
                                  ),
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                    child: Text(
                                      'Remember me',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Primary Button: Login
                              PrimaryButton(
                                label: isLoading ? 'Logging in...' : 'Login (लॉगिन करें)',
                                icon: Icons.login_rounded,
                                onPressed: isLoading ? null : () => _submit(context),
                              ),
                              const SizedBox(height: 16),

                              // Link to Sign Up
                              Center(
                                child: TextButton(
                                  onPressed: isLoading ? null : () => context.go(AppRoutes.signup),
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Offline Mode bypass
                      OutlinedButton.icon(
                        icon: const Icon(Icons.offline_pin_rounded, color: AppColors.primary),
                        label: const Text('Continue Offline / बिना लॉगिन जारी रखें'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
                        ),
                        onPressed: () {
                          final authRepo = getIt.isRegistered<AuthRepository>()
                              ? getIt<AuthRepository>()
                              : null;
                          final isProvisioned = authRepo != null &&
                              (authRepo.isAuthenticated || authRepo.currentUser != null);
                          if (isProvisioned) {
                            context.go(AppRoutes.home);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No offline account found on this device. Please log in online first.',
                                ),
                                backgroundColor: AppColors.accentRed,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
