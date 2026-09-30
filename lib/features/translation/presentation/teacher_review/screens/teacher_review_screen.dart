import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/review/review_models.dart';
import '../models/teacher_review.dart';
import '../services/teacher_review_repository.dart'
    show TeacherReviewRepository;
import '../data/teacher_review_demo_data.dart';
import '../widgets/teacher_review_card.dart';
import '../widgets/review_summary_card.dart';
import 'teacher_review_detail_screen.dart';

/// Review - Main List Screen (teacher-facing, read-only).
/// Shows Total / Pending / Resolved tabs over the static local dataset.
/// Correction, verification, approval and resolution live in the
/// separate expert app and never appear here.
class TeacherReviewScreen extends StatefulWidget {
  const TeacherReviewScreen({super.key});

  static const String routeName = '/teacher-review';

  @override
  State<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends State<TeacherReviewScreen>
    with SingleTickerProviderStateMixin {
  late final TeacherReviewRepository _repository;
  late TabController _tabController;
  int _selectedTab = 0; // 0 = Total, 1 = Pending, 2 = Resolved

  // Filter state
  ReviewPriority? _selectedPriority;
  ReviewDirection? _selectedDirection;
  ReviewItemStatus? _selectedStatus;
  // Date filter: null = All, 'today' = Today, 'earlier' = Earlier.
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _repository = TeacherReviewRepository();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          // Reset status filter when tab changes
          if (_selectedTab == 1) {
            _selectedStatus = ReviewItemStatus.pending;
          } else if (_selectedTab == 2) {
            _selectedStatus = ReviewItemStatus.resolved;
          } else {
            _selectedStatus = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TeacherReview> get _baseReviews {
    switch (_selectedTab) {
      case 0:
        return _repository.getReviewsForTeacher();
      case 1:
        return _repository.getPendingReviews();
      case 2:
        return _repository.getResolvedReviews();
      default:
        return _repository.getReviewsForTeacher();
    }
  }

  List<TeacherReview> get _filteredReviews {
    var reviews = List<TeacherReview>.from(_baseReviews);

    // Apply priority filter
    if (_selectedPriority != null) {
      reviews = reviews.where((r) => r.priority == _selectedPriority).toList();
    }

    // Apply direction filter
    if (_selectedDirection != null) {
      reviews = reviews.where((r) => r.direction == _selectedDirection).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      reviews = reviews.where((r) => r.status == _selectedStatus).toList();
    }

    // Apply date filter (Today / Earlier, relative to device date).
    if (_selectedDateFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      reviews = reviews.where((r) {
        final reviewDay = DateTime(
          r.createdAt.year,
          r.createdAt.month,
          r.createdAt.day,
        );
        if (_selectedDateFilter == 'today') {
          return reviewDay.isAtSameMomentAs(today);
        }
        return reviewDay.isBefore(today);
      }).toList();
    }

    // Sort by timestamp: newest first
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reviews;
  }

  Map<String, int> get _counts => _repository.getCounts();

  @override
  Widget build(BuildContext context) {
    // Tablet-friendly horizontal padding; compact on narrow screens.
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth >= 1100
        ? 40.0
        : screenWidth >= 800
            ? 32.0
            : 16.0;
    return AppScaffold(
      title: 'Review',
      breadcrumb: 'Translate > Review',
      showBackButton: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      body: Column(
        children: [
          // Teacher/Classroom Context Header
          _buildContextHeader(),
          const SizedBox(height: 16),

          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 16),

          // Tab Bar
          _buildTabBar(),
          const SizedBox(height: 12),

          // Filter Bar
          _buildFilterBar(),
          const SizedBox(height: 12),

          // Review List
          Expanded(child: _buildReviewList()),
        ],
      ),
    );
  }

  Widget _buildContextHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.strandBlueBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentBlueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.school,
              color: AppColors.accentBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TeacherReviewDemoData.currentTeacherName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TeacherReviewDemoData.currentClassroomName} \u2022 Govt. Primary School, Ranchi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          ReviewSummaryCard(
            title: 'Total Reviews',
            count: _counts['total'] ?? 0,
            icon: Icons.assignment,
            color: AppColors.accentBlue,
            backgroundColor: AppColors.accentBlueLight,
            onTap: () => _tabController.animateTo(0),
          ),
          const SizedBox(width: 12),
          ReviewSummaryCard(
            title: 'Pending',
            count: _counts['pending'] ?? 0,
            icon: Icons.pending_actions,
            color: AppColors.statusDeveloping,
            backgroundColor: AppColors.statusDevelopingBg,
            onTap: () => _tabController.animateTo(1),
          ),
          const SizedBox(width: 12),
          ReviewSummaryCard(
            title: 'Resolved',
            count: _counts['resolved'] ?? 0,
            icon: Icons.check_circle,
            color: AppColors.statusAchieved,
            backgroundColor: AppColors.statusAchievedBg,
            onTap: () => _tabController.animateTo(2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelColor: AppColors.textLight,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: [
          Tab(text: 'Total Reviews (${_counts['total'] ?? 0})'),
          Tab(text: 'Pending (${_counts['pending'] ?? 0})'),
          Tab(text: 'Resolved (${_counts['resolved'] ?? 0})'),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter label + clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.clear_all, size: 16, color: AppColors.textMuted),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Priority Filter
              _buildFilterChip(
                label: _selectedPriority?.shortLabel ?? 'Priority',
                isSelected: _selectedPriority != null,
                onTap: () => _showPriorityFilter(),
                icon: Icons.flag,
              ),

              // Status Filter
              _buildFilterChip(
                label: _getStatusFilterLabel(),
                isSelected: _selectedStatus != null && _selectedTab == 0,
                onTap: _selectedTab == 0 ? () => _showStatusFilter() : null,
                icon: Icons.filter_list,
                disabled: _selectedTab != 0,
              ),

              // Direction Filter
              _buildFilterChip(
                label: _selectedDirection?.name.split('.').last == 'hindiToSantali'
                    ? 'Hindi \u2192 Santali'
                    : _selectedDirection?.name.split('.').last == 'santaliToHindi'
                        ? 'Santali \u2192 Hindi'
                        : 'Direction',
                isSelected: _selectedDirection != null,
                onTap: () => _showDirectionFilter(),
                icon: Icons.translate,
              ),

              // Date Filter
              _buildFilterChip(
                label: _selectedDateFilter == 'today'
                    ? 'Today'
                    : _selectedDateFilter == 'earlier'
                        ? 'Earlier'
                        : 'Date',
                isSelected: _selectedDateFilter != null,
                onTap: () => _showDateFilter(),
                icon: Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedPriority != null ||
      _selectedDirection != null ||
      (_selectedStatus != null && _selectedTab == 0) ||
      _selectedDateFilter != null;

  String _getStatusFilterLabel() {
    if (_selectedStatus == ReviewItemStatus.pending) return 'Pending';
    if (_selectedStatus == ReviewItemStatus.resolved) return 'Resolved';
    return 'Status';
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    required IconData icon,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.backgroundSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.primary
                  : disabled
                      ? AppColors.textMuted
                      : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: disabled
                    ? AppColors.textMuted
                    : isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: disabled ? null : () {
                  setState(() {
                    // Clear specific filter based on label
                    if (label.contains('High') || label.contains('Medium') || label.contains('Low')) {
                      _selectedPriority = null;
                    } else if (label == 'Pending' || label == 'Resolved') {
                      _selectedStatus = null;
                    } else if (label.contains('\u2192')) {
                      _selectedDirection = null;
                    } else if (label == 'Today' || label == 'Earlier') {
                      _selectedDateFilter = null;
                    }
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: disabled
                      ? AppColors.textMuted
                      : isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'Filter by Priority',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            _buildFilterOption(
              'All',
              isSelected: _selectedPriority == null,
              onTap: () {
                setState(() => _selectedPriority = null);
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              'High',
              isSelected: _selectedPriority == ReviewPriority.high,
              onTap: () {
                setState(() => _selectedPriority = ReviewPriority.high);
                Navigator.pop(context);
              },
              color: AppColors.statusNeedsSupport,
            ),
            _buildFilterOption(
              'Medium',
              isSelected: _selectedPriority == ReviewPriority.medium,
              onTap: () {
                setState(() => _selectedPriority = ReviewPriority.medium);
                Navigator.pop(context);
              },
              color: AppColors.statusDeveloping,
            ),
            _buildFilterOption(
              'Low',
              isSelected: _selectedPriority == ReviewPriority.low,
              onTap: () {
                setState(() => _selectedPriority = ReviewPriority.low);
                Navigator.pop(context);
              },
              color: AppColors.statusAchieved,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'Filter by Status',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            _buildFilterOption(
              'All',
              isSelected: _selectedStatus == null,
              onTap: () {
                setState(() => _selectedStatus = null);
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              'Pending',
              isSelected: _selectedStatus == ReviewItemStatus.pending,
              onTap: () {
                setState(() => _selectedStatus = ReviewItemStatus.pending);
                Navigator.pop(context);
              },
              color: AppColors.statusDeveloping,
            ),
            _buildFilterOption(
              'Resolved',
              isSelected: _selectedStatus == ReviewItemStatus.resolved,
              onTap: () {
                setState(() => _selectedStatus = ReviewItemStatus.resolved);
                Navigator.pop(context);
              },
              color: AppColors.statusAchieved,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDirectionFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'Filter by Direction',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            _buildFilterOption(
              'All',
              isSelected: _selectedDirection == null,
              onTap: () {
                setState(() => _selectedDirection = null);
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              'Hindi \u2192 Santali',
              isSelected: _selectedDirection == ReviewDirection.hindiToSantali,
              onTap: () {
                setState(() => _selectedDirection = ReviewDirection.hindiToSantali);
                Navigator.pop(context);
              },
              color: AppColors.primary,
            ),
            _buildFilterOption(
              'Santali \u2192 Hindi',
              isSelected: _selectedDirection == ReviewDirection.santaliToHindi,
              onTap: () {
                setState(() => _selectedDirection = ReviewDirection.santaliToHindi);
                Navigator.pop(context);
              },
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'Filter by Date',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
            _buildFilterOption(
              'All',
              isSelected: _selectedDateFilter == null,
              onTap: () {
                setState(() => _selectedDateFilter = null);
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              'Today',
              isSelected: _selectedDateFilter == 'today',
              onTap: () {
                setState(() => _selectedDateFilter = 'today');
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              'Earlier',
              isSelected: _selectedDateFilter == 'earlier',
              onTap: () {
                setState(() => _selectedDateFilter = 'earlier');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: color ?? (isSelected ? AppColors.primary : AppColors.navy),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: color ?? AppColors.primary, size: 24)
          : null,
      onTap: onTap,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedPriority = null;
      _selectedDirection = null;
      _selectedStatus = null;
      _selectedDateFilter = null;
    });
  }

  Widget _buildReviewList() {
    final reviews = _filteredReviews;

    if (reviews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return TeacherReviewCard(
          review: review,
          onTap: () => _openReviewDetail(review),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedTab) {
      case 0:
        message = 'No reviews available';
        icon = Icons.assignment_outlined;
        break;
      case 1:
        message = 'No pending reviews';
        icon = Icons.pending_actions;
        break;
      case 2:
        message = 'No resolved reviews';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No reviews';
        icon = Icons.assignment_outlined;
    }

    // Add filter context if filters are active
    if (_hasActiveFilters) {
      message = 'No reviews match current filters';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.clear, size: 16, color: AppColors.primary),
              label: Text(
                'Clear Filters',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Translations from your classroom will appear here',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _openReviewDetail(TeacherReview review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherReviewDetailScreen(review: review),
      ),
    ).then((_) {
      // Refresh counts when returning from detail screen
      setState(() {});
    });
  }
}