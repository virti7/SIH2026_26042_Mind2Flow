import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/di/injection.dart';
import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../repositories/app_repositories.dart';
import 'badges.dart';

/// Persistent Tablet & Desktop navigation sidebar following Reference B specifications.
class TabletSidebar extends StatelessWidget {
  const TabletSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      currentPath = '';
    }

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top NIPUN Bharat Branding
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(color: AppColors.greenBorder, width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NipunBadge(),
                      const SizedBox(height: 2),
                      Text(
                        'Maatribhasha FLN',
                        style: AppTypography.cardTitleSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              children: [
                _buildNavItem(
                  context,
                  title: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: currentPath == AppRoutes.home,
                  onTap: () => context.go(AppRoutes.home),
                ),
                _buildNavItem(
                  context,
                  title: 'Teach',
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  isActive: currentPath.startsWith('/teach') || currentPath.startsWith('/literacy') || currentPath.startsWith('/numeracy'),
                  onTap: () => context.go(AppRoutes.teach),
                ),
                _buildNavItem(
                  context,
                  title: 'Classes',
                  icon: Icons.class_outlined,
                  activeIcon: Icons.class_rounded,
                  isActive: currentPath.contains('/teach/class'),
                  onTap: () => context.push('/teach/class/2'),
                ),
                _buildNavItem(
                  context,
                  title: 'Students',
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  isActive: currentPath == AppRoutes.studentList || currentPath.contains('/progress/student/'),
                  onTap: () => context.push(AppRoutes.studentList),
                ),
                _buildNavItem(
                  context,
                  title: 'Resources',
                  icon: Icons.auto_stories_outlined,
                  activeIcon: Icons.auto_stories_rounded,
                  isActive: currentPath.startsWith('/resources'),
                  onTap: () => context.push(AppRoutes.activityLibrary),
                ),
                _buildNavItem(
                  context,
                  title: 'Offline Center',
                  icon: Icons.cloud_off_rounded,
                  activeIcon: Icons.cloud_off_rounded,
                  isActive: currentPath.startsWith('/offline'),
                  onTap: () => context.push(AppRoutes.offlineStatus),
                ),
                _buildNavItem(
                  context,
                  title: 'Progress',
                  icon: Icons.trending_up_rounded,
                  activeIcon: Icons.trending_up_rounded,
                  isActive: currentPath == AppRoutes.progress,
                  onTap: () => context.go(AppRoutes.progress),
                ),
                _buildNavItem(
                  context,
                  title: 'Profile',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isActive: currentPath.startsWith('/profile'),
                  onTap: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),

          // Bottom Teacher Status Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.greenLight,
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  // Keyed by authenticated user: a new account never sees
                  // the previous teacher's name while loading.
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final userId = authState is Authenticated
                          ? authState.user.id
                          : 'signed-out';
                      return FutureBuilder(
                        key: ValueKey(userId),
                        future: getIt<TeacherRepository>().getProfile(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Teacher',
                                  style: AppTypography.cardTitleSmall
                                      .copyWith(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Loading…',
                                  style: AppTypography.captionSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          }
                          final name = (snapshot.data?.name ?? '').trim();
                          final school = (snapshot.data?.school ?? '').trim();
                          final district =
                              (snapshot.data?.district ?? '').trim();
                          final schoolShort = school.isEmpty
                              ? (district.isEmpty
                                  ? 'Teacher profile'
                                  : district)
                              : school.length > 18
                                  ? school.substring(0, 18)
                                  : school;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name.isEmpty ? 'Teacher' : name,
                                style: AppTypography.cardTitleSmall
                                    .copyWith(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                schoolShort,
                                style: AppTypography.captionSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? AppColors.greenLight : Colors.transparent,
              borderRadius: AppRadius.radiusMd,
              border: isActive
                  ? Border.all(color: AppColors.greenBorder.withValues(alpha: 0.8), width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
