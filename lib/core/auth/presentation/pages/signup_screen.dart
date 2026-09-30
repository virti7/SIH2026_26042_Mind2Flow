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
import '../../../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../bloc/auth_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          context.go(AppRoutes.home);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final school = _schoolController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(AuthSignUpEvent(
          name: name,
          schoolName: school,
          email: email,
          password: password,
          role: 'teacher',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Non-blocking backend notice after a successful Supabase
            // signup: the session stays valid; the teacher lands on Home.
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
            if (state.profileNeedsCompletion) {
              context.go(AppRoutes.teacherSetup,
                  extra: const {'completion': true});
            } else {
              context.read<TeacherProfileBloc>().add(LoadTeacherProfile());
              context.go(AppRoutes.home);
            }
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
                duration: const Duration(seconds: 4),
              ),
            );
            context.go(AppRoutes.login);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo & Header
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create Teacher Account',
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 24,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'शिक्षक पंजीकरण — ${AppConstants.appName}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Form Fields Card
                        CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Teacher Name
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Teacher Name (पूरा नाम)',
                                  hintText: 'e.g. Rameshwar Soren',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Teacher name is required.';
                                  }
                                  if (val.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 2. School Name
                              TextFormField(
                                controller: _schoolController,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'School Name (स्कूल का नाम)',
                                  hintText: 'e.g. Govt. Primary School, Torpa',
                                  prefixIcon: const Icon(
                                    Icons.school_outlined,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'School name is required.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 3. Email Address
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email Address (ईमेल)',
                                  hintText: 'teacher@school.edu.in',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  final clean = val.trim();
                                  if (!clean.contains('@') || !clean.contains('.')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 4. Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Password (पासवर्ड)',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 5. Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(context),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password (पासवर्ड की पुष्टि करें)',
                                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(borderRadius: AppRadius.radiusMd),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (val != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              PrimaryButton(
                                label: isLoading ? 'Creating Account...' : 'Create Account (खाता बनाएं)',
                                icon: Icons.person_add_rounded,
                                onPressed: isLoading ? null : () => _submit(context),
                              ),
                              const SizedBox(height: 16),

                              // Link to Login
                              Center(
                                child: TextButton(
                                  onPressed: isLoading ? null : () => context.go(AppRoutes.login),
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Login',
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
                      ],
                    ),
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
