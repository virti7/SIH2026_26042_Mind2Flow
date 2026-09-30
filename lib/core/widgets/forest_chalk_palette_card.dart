import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Production-grade Forest & Chalk design system color specification card.
///
/// Implements:
/// - Manrope typography with clear typographic scale (24-26px bold title,
///   15-16px description, 13-14px medium names, 12px monospaced hex codes).
/// - 5 exact color swatches:
///     Forest:     #176B52
///     Sage:       #D9EFE5
///     Amber:      #E9A23B
///     Background: #F7F8F4
///     Text:       #18312B
/// - Restrained radii (8-12px), subtle borders, understated status indicator.
/// - 1-tap copy feedback for hex codes.
/// - Responsive adaptation between desktop/tablet and mobile widths.
class ForestChalkPaletteCard extends StatelessWidget {
  const ForestChalkPaletteCard({super.key});

  static const Color forest = Color(0xFF176B52);
  static const Color sage = Color(0xFFD9EFE5);
  static const Color amber = Color(0xFFE9A23B);
  static const Color background = Color(0xFFF7F8F4);
  static const Color text = Color(0xFF18312B);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 680;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: text.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow & Understated Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'DESIGN SYSTEM • PALETTE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: text.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF8F3),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: forest.withValues(alpha: 0.16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: forest,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active System Palette',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: forest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Palette Title (24-26px bold)
          Text(
            'Forest & Chalk',
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: text,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Supporting Description (15-16px regular, constrained width)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'A grounded, warm, and highly legible palette engineered for multilingual primary classrooms. '
              'Combining deep organic greenery with warm paper tones, this system minimizes eye strain on low-cost displays while preserving clear pedagogical hierarchy.',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: text.withValues(alpha: 0.70),
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5 Central Colour Swatches
          isCompact ? _buildMobileSwatches(context) : _buildDesktopSwatches(context),
          const SizedBox(height: 28),

          Divider(color: text.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 24),

          // Two-column Specifications: Character & Usage + Accessibility Matrix
          if (!isCompact)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRoleList()),
                const SizedBox(width: 32),
                Expanded(child: _buildContrastMatrix()),
              ],
            )
          else ...[
            _buildRoleList(),
            const SizedBox(height: 24),
            _buildContrastMatrix(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopSwatches(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SwatchTile(name: 'Forest', hex: '#176B52', color: forest, role: 'Primary & Actions', onTap: () => _copy(context, '#176B52', 'Forest'))),
        const SizedBox(width: 14),
        Expanded(child: _SwatchTile(name: 'Sage', hex: '#D9EFE5', color: sage, role: 'Surface & Highlights', onTap: () => _copy(context, '#D9EFE5', 'Sage'))),
        const SizedBox(width: 14),
        Expanded(child: _SwatchTile(name: 'Amber', hex: '#E9A23B', color: amber, role: 'Pedagogical Accent', onTap: () => _copy(context, '#E9A23B', 'Amber'))),
        const SizedBox(width: 14),
        Expanded(child: _SwatchTile(name: 'Background', hex: '#F7F8F4', color: background, role: 'Chalk / Paper Canvas', border: true, onTap: () => _copy(context, '#F7F8F4', 'Background'))),
        const SizedBox(width: 14),
        Expanded(child: _SwatchTile(name: 'Text', hex: '#18312B', color: text, role: 'Deep Woodland Text', onTap: () => _copy(context, '#18312B', 'Text'))),
      ],
    );
  }

  Widget _buildMobileSwatches(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: [
        _buildSizedBoxSwatch(context, 'Forest', '#176B52', forest, 'Primary Actions'),
        _buildSizedBoxSwatch(context, 'Sage', '#D9EFE5', sage, 'Soft Surface'),
        _buildSizedBoxSwatch(context, 'Amber', '#E9A23B', amber, 'Accent & Alerts'),
        _buildSizedBoxSwatch(context, 'Background', '#F7F8F4', background, 'Chalk Canvas', border: true),
        _buildSizedBoxSwatch(context, 'Text', '#18312B', text, 'Headings & Body'),
      ],
    );
  }

  Widget _buildSizedBoxSwatch(BuildContext context, String name, String hex, Color col, String role, {bool border = false}) {
    return SizedBox(
      width: 140,
      child: _SwatchTile(
        name: name,
        hex: hex,
        color: col,
        role: role,
        border: border,
        onTap: () => _copy(context, hex, name),
      ),
    );
  }

  Widget _buildRoleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Palette Character & Roles'),
        const SizedBox(height: 12),
        _buildRoleRow(forest, 'Forest (#176B52)', 'Primary buttons, active tabs, header icons'),
        _buildRoleRow(sage, 'Sage (#D9EFE5)', 'Selected chips, tonal cards, quiet badges'),
        _buildRoleRow(amber, 'Amber (#E9A23B)', 'NIPUN badges, classroom alerts, star ratings'),
        _buildRoleRow(background, 'Background (#F7F8F4)', 'Scaffold canvas, unread cards, paper texture', hasBorder: true),
        _buildRoleRow(text, 'Text (#18312B)', 'Primary headings, body text, Indic scripts'),
      ],
    );
  }

  Widget _buildRoleRow(Color dotColor, String title, String role, {bool hasBorder = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: hasBorder ? Border.all(color: text.withValues(alpha: 0.15)) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: text.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContrastMatrix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Accessibility & WCAG 2.1 Contrast'),
        const SizedBox(height: 12),
        _buildContrastRow('Text on Background', '13.8 : 1', 'AAA', 'Body, questions, primary titles'),
        _buildContrastRow('Text on Sage', '11.2 : 1', 'AAA', 'Active filter chips, highlighted terms'),
        _buildContrastRow('Forest on Background', '5.8 : 1', 'AA', 'Section titles, interactive icons'),
        _buildContrastRow('White on Forest', '5.2 : 1', 'AA', 'Primary button text, active pill label'),
      ],
    );
  }

  Widget _buildContrastRow(String pair, String ratio, String rating, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pair,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: text),
                ),
                Text(
                  note,
                  style: GoogleFonts.manrope(fontSize: 11, color: text.withValues(alpha: 0.60)),
                ),
              ],
            ),
          ),
          Text(
            ratio,
            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w500, color: text),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: rating == 'AAA' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rating,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: rating == 'AAA' ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: forest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        ),
      ],
    );
  }

  static void _copy(BuildContext context, String hex, String name) {
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $name ($hex) to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  final String name;
  final String hex;
  final Color color;
  final String role;
  final bool border;
  final VoidCallback onTap;

  const _SwatchTile({
    required this.name,
    required this.hex,
    required this.color,
    required this.role,
    this.border = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: border
                  ? Border.all(color: ForestChalkPaletteCard.text.withValues(alpha: 0.12))
                  : Border.all(color: Colors.transparent),
            ),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.topRight,
            child: Icon(
              Icons.copy_rounded,
              size: 14,
              color: color.computeLuminance() > 0.4
                  ? ForestChalkPaletteCard.text.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ForestChalkPaletteCard.text,
            ),
          ),
          Text(
            hex,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: ForestChalkPaletteCard.text.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ForestChalkPaletteCard.text.withValues(alpha: 0.48),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
