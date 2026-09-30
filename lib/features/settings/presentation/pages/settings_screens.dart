import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/profile/presentation/bloc/teacher_profile_bloc.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/repositories/app_repositories.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/custom_card.dart';

// SCREEN 56: Initial Provisioning / Setup & Sync
class InitialProvisioningScreen extends StatelessWidget {
  const InitialProvisioningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Initial Setup & Sync',
      subtitle: 'Your device arrives ready with lessons, languages and audio. New content syncs when you are online.',
      breadcrumb: 'Device Provisioning',
      isScrollable: true,
      bottomActionBar: PrimaryButton(
        label: 'Continue Setup',
        trailingIcon: Icons.arrow_forward_rounded,
        onPressed: () => context.go(AppRoutes.home),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Everything you need is already on this device. No downloads needed before your first class.',
                    style: AppTypography.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Setup Progress
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('Setup Progress', style: AppTypography.cardTitle.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('Setting up... 68%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: const LinearProgressIndicator(
                    value: 0.68,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildStepRow(Icons.menu_book_rounded, 'Lessons & Stories', 'Classes 1–5 teaching resources', true),
                _buildStepRow(Icons.language_rounded, 'Language Packs', 'Ho, Mundari, Santali — on this device', false, inProgress: true),
                _buildStepRow(Icons.school_rounded, 'Selected Classes', 'Setting up your classroom', false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content Summary
          Text('Content Summary', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSummaryBox('Lessons', 'Ready', 'Works offline')),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryBox('Languages', '3 packs', 'Ho • Mundari • Santali')),
              const SizedBox(width: 8),
              Expanded(child: _buildSummaryBox('Audio', 'Ready', 'Classroom speaker')),
            ],
          ),
          const SizedBox(height: 20),

          // Offline Guarantee Card
          CustomCard(
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('After setup, teaching works offline.', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      Text('Lessons, classroom audio and your teaching records need no internet.', style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String title, String sub, bool done, {bool inProgress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: done ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text(sub, style: AppTypography.caption),
              ],
            ),
          ),
          if (done)
            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.statusAchieved)
          else if (inProgress)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else
            const Text('Pending', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String size, String note) {
    return CustomCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(size, style: AppTypography.cardTitle.copyWith(fontSize: 16, color: AppColors.primary)),
          Text(note, style: AppTypography.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// Consolidated Settings — ONE screen containing every setting group inline:
// Provisioning/Sync, Language Packs, Content Packs, Sync & Updates,
// Offline Storage, Language Settings, Audio Settings, Classroom Settings,
// About & Help. Detail routes remain registered for deep links, but everything
// a teacher needs is adjustable right here without leaving this page.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Set<String> _expanded = {'device'};
  String _interfaceLanguage = 'Hindi';
  bool _ho = true;
  bool _mundari = true;
  bool _santali = true;
  bool _autoSync = true;
  bool _speakerBoost = true;
  double _volume = 0.8;
  String _speed = 'Normal';
  String _voice = 'Female';
  final Set<int> _classes = {1, 2, 3};
  String _defaultLanguage = 'Hindi';

  void _toggle(String key) {
    setState(() {
      if (_expanded.contains(key)) {
        _expanded.remove(key);
      } else {
        _expanded.add(key);
      }
    });
  }

  void _saved(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what saved on this device.')),
    );
  }

  /// Confirms, then signs out through [AuthBloc] (supabase.auth.signOut).
  /// Offline application data in SQLite/Drift is preserved.
  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentRed,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<AuthBloc>().add(const AuthSignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully.'),
              duration: Duration(seconds: 2),
            ),
          );
          context.go(AppRoutes.login);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      },
      child: AppScaffold(
      title: 'Settings',
      subtitle: 'Device, languages, content and classroom — all in one place.',
      breadcrumb: 'Settings',
      showBackButton: false,
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher identity card — white, accent in the avatar wash
          CustomCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greenBorder, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                // Reactive central profile state when loaded; otherwise the
                // same local-Drift read as before (offline-first).
                Expanded(
                  child: BlocBuilder<TeacherProfileBloc, TeacherProfileState>(
                    builder: (context, profileState) {
                      if (profileState is TeacherProfileLoaded) {
                        return _settingsIdentity(
                          name: profileState.profile.name,
                          school: profileState.profile.school,
                          district: profileState.profile.district,
                        );
                      }
                      return FutureBuilder(
                        future: getIt<TeacherRepository>().getProfile(),
                        builder: (context, snapshot) {
                          return _settingsIdentity(
                            name: snapshot.data?.name ?? '',
                            school: snapshot.data?.school ?? '',
                            district: snapshot.data?.district ?? '',
                          );
                        },
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.profile),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(spacing: 8, runSpacing: 8, children: [OfflineBadge(), NipunBadge()]),
          const SizedBox(height: 16),

          _sectionCard(
            keyName: 'device',
            icon: Icons.offline_pin_rounded,
            title: 'Initial Provisioning / Sync',
            subtitle: 'Ready • Works offline',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: const LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Lessons, classroom audio and languages are on this device. New content syncs when you are online.',
                    style: AppTypography.caption),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Sync Now',
                        icon: Icons.sync_rounded,
                        height: 44,
                        onPressed: () => _saved('Sync started — will complete when online'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Last sync: today morning • Sync when online', style: AppTypography.caption),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'packs',
            icon: Icons.language_rounded,
            title: 'Language Pack Manager',
            subtitle: '3 languages • Installed',
            iconColor: AppColors.accentPurple,
            iconBg: AppColors.accentPurpleLight,
            child: Column(
              children: [
                _statusRow('Ho', 'वारंग क्षिति', true),
                _statusRow('Mundari', 'मुंडारी बनी', true),
                _statusRow('Santali', 'ओल चिकी', true),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'content',
            icon: Icons.folder_special_outlined,
            title: 'Content Pack Manager',
            subtitle: 'Classes 1–3 • Downloaded',
            iconColor: AppColors.accentBlue,
            iconBg: AppColors.accentBlueLight,
            child: Column(
              children: [
                _statusRow('Class 1', 'Stories, rhymes & worksheets', true),
                _statusRow('Class 2', 'Lessons, worksheets & flashcards', true),
                _statusRow('Class 3', 'Reading & math practice', true),
                _statusRow('Class 4', 'Available when online', false),
                _statusRow('Class 5', 'Available when online', false),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'sync',
            icon: Icons.sync_rounded,
            title: 'Sync & Updates',
            subtitle: 'Last sync today',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Auto-sync when online', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  subtitle: Text('Teaching records sync quietly in the background', style: AppTypography.caption),
                  value: _autoSync,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _autoSync = v),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Check for Updates',
                        icon: Icons.cloud_download_outlined,
                        height: 44,
                        onPressed: () => _saved('Everything is up to date'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'storage',
            icon: Icons.pie_chart_outline_rounded,
            title: 'Offline Storage',
            subtitle: 'Plenty of space available',
            iconColor: AppColors.accentOrange,
            iconBg: AppColors.accentOrangeLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: const LinearProgressIndicator(
                    value: 0.15,
                    minHeight: 10,
                    backgroundColor: AppColors.cardBorder,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Lessons & stories • Available offline', style: AppTypography.bodySmall),
                Text('Classroom audio • Available offline', style: AppTypography.bodySmall),
                Text('Teaching records • On this device', style: AppTypography.bodySmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Free Up Space',
                        icon: Icons.cleaning_services_rounded,
                        height: 44,
                        onPressed: () => _saved('Extra space freed up'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'language',
            icon: Icons.translate_rounded,
            title: 'Language Settings',
            subtitle: 'Hindi + Ho • Mundari • Santali',
            iconColor: AppColors.accentRed,
            iconBg: AppColors.accentRedLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App language', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Hindi', 'English'].map((l) {
                    final sel = _interfaceLanguage == l;
                    return ChoiceChip(
                      label: Text(l),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.navy, fontSize: 12),
                      onSelected: (_) => setState(() => _interfaceLanguage = l),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Classroom languages', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Ho'),
                  value: _ho,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _ho = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Mundari'),
                  value: _mundari,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _mundari = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Santali'),
                  value: _santali,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _santali = v),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save Languages',
                        height: 44,
                        onPressed: () => _saved('Language preferences'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'audio',
            icon: Icons.volume_up_outlined,
            title: 'Audio Settings',
            subtitle: 'Normal speed • Classroom speaker',
            iconColor: AppColors.accentPurple,
            iconBg: AppColors.accentPurpleLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volume', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                Slider(
                  value: _volume,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _volume = v),
                ),
                Text('Playback speed', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Slow', 'Normal', 'Fast'].map((s) {
                    final sel = _speed == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.navy, fontSize: 12),
                      onSelected: (_) => setState(() => _speed = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Classroom voice', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Female', 'Male'].map((v) {
                    final sel = _voice == v;
                    return ChoiceChip(
                      label: Text(v),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.navy, fontSize: 12),
                      onSelected: (_) => setState(() => _voice = v),
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Classroom speaker boost', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  subtitle: Text('Children in the back row hear clearly', style: AppTypography.caption),
                  value: _speakerBoost,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _speakerBoost = v),
                ),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Play Test Audio',
                        icon: Icons.play_arrow_rounded,
                        height: 44,
                        onPressed: () => _saved('Test audio played'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'classroom',
            icon: Icons.class_outlined,
            title: 'Classroom Settings',
            subtitle: 'Classes 1–3 • Hindi medium',
            iconColor: AppColors.accentBlue,
            iconBg: AppColors.accentBlueLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Classes you teach', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 2, 3, 4, 5].map((c) {
                    final sel = _classes.contains(c);
                    return FilterChip(
                      label: Text('Class $c'),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.navy, fontSize: 12),
                      onSelected: (_) => setState(() {
                        if (sel) {
                          _classes.remove(c);
                        } else {
                          _classes.add(c);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Teaching language', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Hindi', 'English'].map((l) {
                    final sel = _defaultLanguage == l;
                    return ChoiceChip(
                      label: Text(l),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.navy, fontSize: 12),
                      onSelected: (_) => setState(() => _defaultLanguage = l),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save Classroom',
                        height: 44,
                        onPressed: () => _saved('Classroom settings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _sectionCard(
            keyName: 'about',
            icon: Icons.info_outline_rounded,
            title: 'About & Help',
            subtitle: 'How to use the app',
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.surfaceSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _helpRow('Teach', 'Pick a class, subject and outcome. Follow Explain → Demonstrate → Ask → Activity → Practice → Check.'),
                _helpRow('Translate', 'Speak Hindi into the mic. Play the Ho, Mundari or Santali audio for your class.'),
                _helpRow('Progress', 'See the lessons you taught, assessments you conducted and resources you created.'),
                const SizedBox(height: 8),
                Text('Maatribhasha • Mother-Tongue Teaching Assistant • ${AppConstants.appVersion}',
                    style: AppTypography.caption),
              ],
            ),
          ),
          // Log out — ends the Supabase session only. Downloaded lessons,
          // offline content, teaching records and the sync queue stay on
          // this device.
          const Divider(height: 32),
          Semantics(
            button: true,
            label: 'Log Out',
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _confirmAndLogout(context),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.accentRed,
                ),
                label: Text(
                  'Log Out',
                  style: AppTypography.buttonText.copyWith(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.accentRed,
                  side: const BorderSide(
                    color: AppColors.accentRed,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusMd,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _sectionCard({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Color iconColor = AppColors.primary,
    Color iconBg = AppColors.greenLight,
  }) {
    final open = _expanded.contains(keyName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggle(keyName),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Icon(
                      open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (open) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: child,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String title, String subtitle, bool ready) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.cloud_download_outlined,
            color: ready ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ready ? AppColors.greenLight : AppColors.pastelBlue,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: ready ? AppColors.greenBorder : AppColors.cardBorder),
            ),
            child: Text(
              ready ? 'Installed' : 'Sync when online',
              style: AppTypography.caption.copyWith(
                color: ready ? AppColors.primaryDark : AppColors.accentBlue,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Teacher identity lines for the Settings header card. Shows the real
  /// local profile values; 'Teacher' appears only when no name exists.
  Widget _settingsIdentity({
    required String name,
    required String school,
    required String district,
  }) {
    final subtitle = school.isEmpty && district.isEmpty
        ? 'Complete your teacher profile to get started'
        : '$school • $district';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Teacher' : name,
          style: AppTypography.cardTitle.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _helpRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 13)),
                Text(desc, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SCREEN 64: About & Help
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About & Pedagogical Guide',
      subtitle: 'Understanding the NIPUN Bharat framework, MTB-MLE pedagogical foundations, and credits.',
      breadcrumb: 'Settings > About',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCard(
            color: AppColors.greenSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppConstants.appName, style: AppTypography.cardTitle.copyWith(fontSize: 18)),
                          Text(AppConstants.appTagline, style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appPromise,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 6),
                Text('Version: ${AppConstants.appVersion}', style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('How to Use the Application', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          _buildHelpCard(
            '1. Teach Tab',
            'Select Class -> Subject -> NIPUN Outcome. Follow the 6-stage delivery cycle (Explain, Demonstrate, Ask, Activity, Practice, Check).',
          ),
          const SizedBox(height: 10),
          _buildHelpCard(
            '2. Translate Tab',
            'Use live microphone for two-way voice-to-voice communication. Context Engine uses NIPUN target and lesson topic to avoid literal mistranslation.',
          ),
          const SizedBox(height: 10),
          _buildHelpCard(
            '3. Progress Tab',
            'Inspect individual child outcomes. When a learning gap is detected, run the recommended remedial activity and re-assess on tablet.',
          ),
          const SizedBox(height: 16),

          Text('Official Frameworks & Standards', style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          const CustomCard(
            child: Text(
              '• NIPUN Bharat Foundational Literacy & Numeracy guidelines\n• Mother-tongue based teaching in the foundational stage\n• Lessons, worksheets and audio that work fully offline',
              style: TextStyle(height: 1.6, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHelpCard(String title, String desc) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
