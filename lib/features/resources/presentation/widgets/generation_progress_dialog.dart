import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/sync/worksheet_generation_sync.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/content_generation_bloc.dart';
import '../bloc/worksheet_bloc.dart';

class GenerationProgressDialog extends StatelessWidget {
  final VoidCallback? onCompleted;

  /// Overrides the queued-offline body message (e.g. online-but-backend-
  /// unreachable). Defaults to the offline message. Never provider/debug
  /// text: callers pass teacher-facing copy only.
  final String? queuedMessage;

  const GenerationProgressDialog({super.key, this.onCompleted, this.queuedMessage});

  static Future<void> show(BuildContext context,
      {VoidCallback? onCompleted, String? queuedMessage}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<ContentGenerationBloc>(),
        child: GenerationProgressDialog(
            onCompleted: onCompleted, queuedMessage: queuedMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContentGenerationBloc, ContentGenerationState>(
      listener: (context, state) {
        if (state is ContentGenerationSavedLocally) {
          // Feed the completed server worksheet into the existing Worksheet
          // Preview screen (View Offline button) via WorksheetBloc,
          // including the full payload so Preview can offer a real Download.
          try {
            final payload = jsonDecode(state.savedMaterial.contentJson)
                as Map<String, dynamic>;
            context.read<WorksheetBloc>().add(
                  ShowGeneratedWorksheetEvent(
                    worksheetItemFromGenerationPayload(payload),
                    contentPayload: payload,
                    assets: state.assets,
                    contentId: state.savedMaterial.id,
                  ),
                );
          } catch (_) {
            // Preview mapping must never break the saved flow.
          }
          onCompleted?.call();
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 20),
                _buildBody(context, state),
                const SizedBox(height: 24),
                _buildActions(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ContentGenerationState state) {
    IconData icon;
    Color color;
    String title;

    if (state is ContentGenerationSavedLocally) {
      icon = Icons.check_circle_rounded;
      color = AppColors.greenLight;
      title = 'Worksheet Ready!';
    } else if (state is ContentGenerationQueuedOffline) {
      icon = Icons.cloud_off_rounded;
      color = AppColors.primary;
      title = 'Saved for Later';
    } else if (state is ContentGenerationReviewRequired) {
      icon = Icons.rate_review_rounded;
      color = AppColors.accentAmber;
      title = 'Review Required';
    } else if (state is ContentGenerationFailed) {
      icon = Icons.error_outline_rounded;
      color = AppColors.accentRed;
      // A persistence failure must never masquerade as a saved request.
      title = state.isPersistenceError
          ? "Couldn't Save Request"
          : (state.isOfflineError ? 'Saved for Later' : 'Generation Failed');
    } else if (state is ContentGenerationStillWaiting) {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.primary;
      title = 'Still generating';
    } else if (state is ContentGenerationSubmitting ||
        state is ContentGenerationCheckingConnectivity) {
      icon = Icons.auto_awesome_rounded;
      color = AppColors.primary;
      title = 'Sending Request...';
    } else {
      icon = Icons.auto_awesome_rounded;
      color = AppColors.primary;
      title = state is ContentGenerationInProgress
          ? state.stageTitle
          : 'Generating Worksheet';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: AppRadius.radiusMd,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
              Text(
                'Bilingual worksheet • NIPUN-aligned',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ContentGenerationState state) {
    if (state is ContentGenerationCheckingConnectivity) {
      return const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 14),
          Text('Verifying server connectivity...'),
        ],
      );
    }

    if (state is ContentGenerationSubmitting || state is ContentGenerationInProgress) {
      final msg = state is ContentGenerationInProgress
          ? state.message
          : 'Connecting to the server...';
      return Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 14),
          Text(msg, textAlign: TextAlign.center, style: AppTypography.bodySmall),
        ],
      );
    }

    if (state is ContentGenerationStillWaiting) {
      return const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 14),
          Text(
            'Your worksheet is taking a little longer than usual. '
            'You can keep waiting or return to the previous screen.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (state is ContentGenerationReviewRequired) {
      return CustomCard(
        color: AppColors.surfaceSubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accentAmber, size: 18),
                const SizedBox(width: 8),
                Text('Santali Linguistic Review Gate',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generated content includes Santali. Per curriculum safety policy, please confirm Ol Chiki script before classroom download.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    if (state is ContentGenerationDownloading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: state.progress,
            color: AppColors.primary,
            backgroundColor: AppColors.cardBorder,
          ),
          const SizedBox(height: 12),
          Text(
            'Downloading structured content and assets to device...',
            style: AppTypography.caption,
          ),
        ],
      );
    }

    if (state is ContentGenerationSavedLocally) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.savedMaterial.title,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      Text(
                        'Saved on this device. Available offline anytime!',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state is ContentGenerationFailed) {
      return Column(
        children: [
          Text(
            state.errorMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.accentRed),
          ),
        ],
      );
    }

    if (state is ContentGenerationQueuedOffline) {
      return Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            queuedMessage ??
                'Your worksheet request is saved on this device. '
                    'It will be generated when you reconnect and sync.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActions(BuildContext context, ContentGenerationState state) {
    if (state is ContentGenerationReviewRequired) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Cancel',
              onPressed: () {
                context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Confirm Script',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                context.read<ContentGenerationBloc>().add(
                      ApproveContentReviewEvent(
                        jobId: state.jobId,
                        santaliScriptConfirmed: 'Olck',
                      ),
                    );
              },
            ),
          ),
        ],
      );
    }

    if (state is ContentGenerationSavedLocally) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Done',
              onPressed: () {
                context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'View Offline',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                Navigator.of(context).pop();
                context.push(AppRoutes.worksheetPreview);
              },
            ),
          ),
        ],
      );
    }

    if (state is ContentGenerationStillWaiting) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Back',
              onPressed: () {
                context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Keep Waiting',
              icon: Icons.hourglass_top_rounded,
              onPressed: () {
                context.read<ContentGenerationBloc>().add(
                      ResumeWaitingPollEvent(state.jobId),
                    );
              },
            ),
          ),
        ],
      );
    }

    if (state is ContentGenerationFailed) {
      if (state.canRetry && !state.isOfflineError) {
        return Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Close',
                onPressed: () {
                  context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  // Close the dialog; the generator screen button offers
                  // "Retry Generation", which starts a new attempt of the
                  // same logical request (a fresh idempotency key, so no
                  // blind duplicate of an in-flight job).
                  context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      }
      return PrimaryButton(
        label: 'Close',
        onPressed: () {
          context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
          Navigator.of(context).pop();
        },
      );
    }

    if (state is ContentGenerationQueuedOffline) {
      return PrimaryButton(
        label: 'Done',
        onPressed: () {
          context.read<ContentGenerationBloc>().add(const ResetContentGenerationEvent());
          Navigator.of(context).pop();
        },
      );
    }

    // In progress: disable dismissing
    return const SizedBox.shrink();
  }
}
