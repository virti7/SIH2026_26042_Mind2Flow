import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/di/injection.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../repositories/app_repositories.dart';
import 'badges.dart';

/// Top bar in tablet layout following Reference B specifications:
/// NIPUN Bharat branding, notification icon, class selector, teacher profile.
/// Fully responsive across all tablet/desktop widths with overflow prevention.
class TabletHeader extends StatelessWidget {
  final String? breadcrumb;

  const TabletHeader({
    super.key,
    this.breadcrumb,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 240; // width minus 240px sidebar
    final showFullTitle = contentWidth >= 850;
    final showClassSelector = contentWidth >= 580;
    final showTeacherDetails = contentWidth >= 680;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // NIPUN Bharat logo & optional Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NipunBadge(),
              if (showFullTitle) ...[
                const SizedBox(width: 8),
                Text(
                  'Jharkhand Shiksha',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),

          const Spacer(),

          // Class Selector Pill (hidden on very narrow tablet viewports)
          if (showClassSelector) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: AppRadius.radiusPill,
                border: Border.all(color: AppColors.greenBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.class_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    'Class 2 · A',
                    style: AppTypography.cardTitleSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Notification Bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 20),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('NIPUN FLN Sync: All offline records up-to-date.')),
              );
            },
          ),

          const SizedBox(width: 6),

          // Teacher Avatar & Name
          InkWell(
            onTap: () => context.push(AppRoutes.profile),
            borderRadius: AppRadius.radiusPill,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.greenLight,
                    child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                  ),
                  if (showTeacherDetails) ...[
                    const SizedBox(width: 6),
                    // Reactive central profile state when loaded; otherwise
                    // the same local-Drift read as before (offline-first).
                    // Constrained width + ellipsis so long names/schools
                    // truncate gracefully on small screens.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      // Keyed by authenticated user so a new account never
                      // flashes the previous teacher's name/school while its
                      // profile loads. Unloaded state shows neutral loading.
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          final userId = authState is Authenticated
                              ? authState.user.id
                              : null;
                          if (userId == null) {
                            return const _TeacherIdentity(
                                name: '', school: '', loading: true);
                          }
                          return BlocBuilder<TeacherProfileBloc,
                              TeacherProfileState>(
                            builder: (context, state) {
                              if (state is TeacherProfileLoaded) {
                                return _TeacherIdentity(
                                  key: ValueKey(userId),
                                  name: state.profile.name,
                                  school: state.profile.school,
                                );
                              }
                              if (state is TeacherProfileLoading ||
                                  state is TeacherProfileInitial) {
                                return const _TeacherIdentity(
                                    name: '', school: '', loading: true);
                              }
                              return FutureBuilder(
                                key: ValueKey(userId),
                                future:
                                    getIt<TeacherRepository>().getProfile(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const _TeacherIdentity(
                                        name: '',
                                        school: '',
                                        loading: true);
                                  }
                                  final profile = snapshot.data;
                                  return _TeacherIdentity(
                                    key: ValueKey(userId),
                                    name: profile?.name ?? '',
                                    school: profile?.school ?? '',
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Teacher name (prominent) + school name (secondary) identity block.
/// Shows a neutral 'Teacher' label only when no name exists at all —
/// never invents a name or school.
class _TeacherIdentity extends StatelessWidget {
  final String name;
  final String school;
  final bool loading;

  const _TeacherIdentity(
      {super.key, required this.name, required this.school, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 90,
              height: 12,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 4),
          Container(
              width: 120,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(5))),
        ],
      );
    }
    final trimmedName = name.trim();
    final trimmedSchool = school.trim();
    final shortName = trimmedName.isEmpty
        ? 'Teacher'
        : (trimmedName.length > 10
            ? '${trimmedName.substring(0, 10)}.'
            : trimmedName);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shortName,
          style: AppTypography.cardTitleSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          trimmedSchool.isEmpty ? 'Profile' : trimmedSchool,
          style: AppTypography.captionSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
