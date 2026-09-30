import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/audio_play_button.dart';
import 'flashcard_illustration.dart';

Color _paletteFromHex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length != 6) return AppColors.primary;
  try {
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

String _str(dynamic v) => (v ?? '').toString();

/// Fields of one generated flashcard (server or picture-library payload).
class _CardData {
  final Map<String, dynamic> card;
  final String languageMode;
  _CardData(this.card, this.languageMode);

  Map get _visual => card['visual'] is Map ? card['visual'] as Map : const {};
  String get image => _str(_visual['image']);
  String get labelImage => _str(_visual['label_image']);
  String get hindi => _str(card['hindi']);
  String get english => _str(card['english']);
  String get santali => _str(card['santali']);
  String get topic => _str(card['concept']);
  String get number => _str(card['number']);

  /// Hindi for hi_sat / hi_en_sat, English for en_sat.
  String? get primary {
    final p = languageMode == 'en_sat' ? english : hindi;
    return p.isEmpty ? null : p;
  }

  /// English as the second line in the trilingual mode only.
  String? get secondary =>
      languageMode == 'hi_en_sat' && english.isNotEmpty ? english : null;

  Widget picture(double height) {
    final art = _str(_visual['art']);
    final illustration = FlashcardIllustration(
      art: art.isNotEmpty ? art : 'emblem',
      palette: _paletteFromHex(_str(_visual['palette'])),
      count: (_visual['count'] as num?)?.toInt(),
      swatch: _str(_visual['swatch']),
      height: height,
    );
    if (image.isEmpty) return illustration;
    // Picture-library cards carry a real bundled picture.
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: AppRadius.radiusMd,
        child: Image.asset(
          image,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => illustration,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color border = AppColors.primary}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: AppRadius.radiusLg,
      border: Border.all(color: border, width: 1.5),
      boxShadow: const [
        BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 4)),
      ],
    );

/// One designed flashcard face with everything on it: visual-first, then
/// the language hierarchy (primary large, secondary smaller, Santali
/// distinct). Used for the full-set grid; long text wraps, never overflows.
class GeneratedFlashcardFace extends StatelessWidget {
  final Map<String, dynamic> card;
  final String languageMode;
  final bool compact;

  const GeneratedFlashcardFace({
    super.key,
    required this.card,
    required this.languageMode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = _CardData(card, languageMode);
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 18),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (d.topic.isNotEmpty)
              Text(d.topic.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 9 : 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            SizedBox(height: compact ? 4 : 8),
            d.picture(compact ? 86 : 160),
            SizedBox(height: compact ? 4 : 10),
            if (d.primary != null)
              Text(d.primary!,
                  style: AppTypography.screenTitle.copyWith(
                      fontSize: compact ? 17 : 26, color: AppColors.primaryDark),
                  textAlign: TextAlign.center),
            if (d.secondary != null)
              Text(d.secondary!,
                  style: AppTypography.cardTitle.copyWith(
                      fontSize: compact ? 13 : 19, color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
            if (d.santali.isNotEmpty)
              Text(d.santali,
                  style: AppTypography.cardTitle.copyWith(
                      fontSize: compact ? 14 : 21, color: AppColors.primary),
                  textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// A flashcard that flips on tap: the front shows the picture and the
/// primary word, the back shows the Santali word (plus the printed label
/// crop and pronunciation buttons when enabled).
class FlippableGeneratedFlashcard extends StatelessWidget {
  final Map<String, dynamic> card;
  final String languageMode;
  final bool showBack;
  final bool showPronunciation;
  final VoidCallback onFlip;

  const FlippableGeneratedFlashcard({
    super.key,
    required this.card,
    required this.languageMode,
    required this.showBack,
    required this.onFlip,
    this.showPronunciation = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFlip,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showBack ? 1 : 0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final angle = t * math.pi;
          final back = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: back
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _back(),
                  )
                : _front(),
          );
        },
      ),
    );
  }

  Widget _front() {
    final d = _CardData(card, languageMode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (d.topic.isNotEmpty)
            Text(d.topic.toUpperCase(),
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => Center(child: d.picture(c.maxHeight)),
            ),
          ),
          const SizedBox(height: 12),
          if (d.primary != null)
            Text(d.primary!,
                style: AppTypography.screenTitle
                    .copyWith(fontSize: 30, color: AppColors.primaryDark),
                textAlign: TextAlign.center),
          if (d.secondary != null)
            Text(d.secondary!,
                style: AppTypography.cardTitle
                    .copyWith(fontSize: 20, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          const SizedBox(height: 10),
          _hint(Icons.touch_app_rounded, 'Tap to flip for Santali'),
        ],
      ),
    );
  }

  Widget _back() {
    final d = _CardData(card, languageMode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(color: AppColors.greenSurface),
      // Scale down (never overflow) when the card is shorter than its content.
      child: LayoutBuilder(
        builder: (_, c) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: c.maxWidth,
              child: _backContent(d),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backContent(_CardData d) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SANTALI',
              style: AppTypography.caption.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(d.santali.isNotEmpty ? d.santali : '—',
              style: AppTypography.screenTitle
                  .copyWith(fontSize: 34, color: AppColors.primary),
              textAlign: TextAlign.center),
          if (d.labelImage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Image.asset(
              d.labelImage,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(height: 90, child: d.picture(90)),
          const SizedBox(height: 14),
          if (d.hindi.isNotEmpty)
            Text(d.hindi,
                style: AppTypography.cardTitle
                    .copyWith(fontSize: 20, color: AppColors.primaryDark),
                textAlign: TextAlign.center),
          if (d.english.isNotEmpty)
            Text(d.english,
                style: AppTypography.bodySmall.copyWith(fontSize: 16),
                textAlign: TextAlign.center),
          if (showPronunciation) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (d.hindi.isNotEmpty)
                  const AudioPlayButton(label: 'Hindi', compact: true),
                if (d.english.isNotEmpty)
                  const AudioPlayButton(label: 'English', compact: true),
                if (d.santali.isNotEmpty)
                  const AudioPlayButton(label: 'Santali', compact: true),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _hint(Icons.flip_rounded, 'Tap to flip back'),
          if (d.number.isNotEmpty)
            Text(d.number, style: AppTypography.caption),
        ],
    );
  }

  Widget _hint(IconData icon, String text) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.caption),
        ],
      );
}
