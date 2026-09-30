import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'app_header_banner.dart';
import 'responsive_container.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? breadcrumb;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? headerTrailing;
  final bool showHeader;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? bottomActionBar;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool isScrollable;
  final EdgeInsetsGeometry contentPadding;
  final bool showSidebarOnTablet;
  final Widget? heroBanner;

  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.breadcrumb,
    this.showBackButton = true,
    this.onBack,
    this.headerTrailing,
    this.showHeader = true,
    required this.body,
    this.bottomNavigationBar,
    this.bottomActionBar,
    this.backgroundColor = AppColors.background,
    this.resizeToAvoidBottomInset = true,
    this.isScrollable = false,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.showSidebarOnTablet = true,
    this.heroBanner,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    Widget mainBody = body;
    if (heroBanner != null) {
      mainBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heroBanner!,
          const SizedBox(height: 16),
          body,
        ],
      );
    }

    Widget content;
    if (isScrollable) {
      content = SingleChildScrollView(
        padding: contentPadding,
        child: ResponsiveContainer(
          maxWidth: isTablet ? 1200 : 960,
          padding: EdgeInsets.zero,
          child: mainBody,
        ),
      );
    } else {
      content = ResponsiveContainer(
        maxWidth: isTablet ? 1200 : 960,
        padding: contentPadding,
        child: mainBody,
      );
    }

    // Wide screens: same phone-style column layout, centered content.
    // Bottom navigation always stays BELOW content (provided by the router
    // shell) — never a side sidebar on any screen size.
    if (isTablet && showSidebarOnTablet) {
      return Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Column(
          children: [
            if (showHeader && title != null)
              AppHeaderBanner(
                title: title!,
                subtitle: subtitle,
                breadcrumb: breadcrumb,
                showBackButton: showBackButton,
                onBack: onBack,
                trailing: headerTrailing,
                showNipunBadge: false,
                compact: true,
              ),
            Expanded(child: content),
            if (bottomActionBar != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.cardBorder, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: ResponsiveContainer(
                    maxWidth: 1200,
                    padding: EdgeInsets.zero,
                    child: bottomActionBar!,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    // Mobile Layout: Top Header + Content + Mobile Bottom Navigation
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Column(
        children: [
          if (showHeader && title != null)
            AppHeaderBanner(
              title: title!,
              subtitle: subtitle,
              breadcrumb: breadcrumb,
              showBackButton: showBackButton,
              onBack: onBack,
              trailing: headerTrailing,
            ),
          Expanded(child: content),
          if (bottomActionBar != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ResponsiveContainer(
                  padding: EdgeInsets.zero,
                  child: bottomActionBar!,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
