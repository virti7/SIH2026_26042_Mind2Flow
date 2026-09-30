import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

class AudioPlayButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPlay;
  final bool compact;

  const AudioPlayButton({
    super.key,
    this.label = 'Play Audio',
    this.onPlay,
    this.compact = false,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  bool _isPlaying = false;

  void _handleTap() {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    widget.onPlay?.call();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isPlaying ? AppColors.primary : AppColors.greenSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenBorder, width: 1),
          ),
          child: Icon(
            _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
            size: 16,
            color: _isPlaying ? Colors.white : AppColors.primary,
          ),
        ),
      );
    }

    return InkWell(
      onTap: _handleTap,
      borderRadius: AppRadius.radiusPill,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isPlaying ? AppColors.primary : AppColors.greenSurface,
          borderRadius: AppRadius.radiusPill,
          border: Border.all(
            color: _isPlaying ? AppColors.primary : AppColors.greenBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              size: 16,
              color: _isPlaying ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              _isPlaying ? 'Playing...' : widget.label,
              style: AppTypography.caption.copyWith(
                color: _isPlaying ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
