import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_typography.dart';

class MicRecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onToggle;
  final String label;

  const MicRecordButton({
    super.key,
    required this.isRecording,
    required this.onToggle,
    this.label = 'Tap to Speak',
  });

  @override
  State<MicRecordButton> createState() => _MicRecordButtonState();
}

class _MicRecordButtonState extends State<MicRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: widget.isRecording ? AppColors.statusNeedsSupport : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: widget.isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.statusNeedsSupport.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : AppShadows.primaryButton,
                border: Border.all(
                  color: Colors.white,
                  width: 3.5,
                ),
              ),
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.isRecording ? 'Listening in Classroom...' : widget.label,
          style: AppTypography.cardTitle.copyWith(
            color: widget.isRecording ? AppColors.statusNeedsSupport : AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
