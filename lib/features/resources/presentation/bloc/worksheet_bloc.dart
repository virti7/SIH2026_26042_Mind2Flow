import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/repositories/app_repositories.dart';

abstract class WorksheetEvent extends Equatable {
  const WorksheetEvent();
  @override
  List<Object?> get props => [];
}

class GenerateWorksheetEvent extends WorksheetEvent {
  final int grade;
  final String subject;
  final String outcomeCode;
  final TribalLanguage targetLanguage;
  final DifficultyLevel difficulty;
  final WorksheetType type;
  final int questionCount;

  const GenerateWorksheetEvent({
    required this.grade,
    required this.subject,
    required this.outcomeCode,
    required this.targetLanguage,
    required this.difficulty,
    required this.type,
    required this.questionCount,
  });

  @override
  List<Object?> get props => [
        grade,
        subject,
        outcomeCode,
        targetLanguage,
        difficulty,
        type,
        questionCount,
      ];
}

/// Shows a server-generated worksheet (online result or post-sync
/// completion) in the existing Worksheet Preview screen.
class ShowGeneratedWorksheetEvent extends WorksheetEvent {
  final WorksheetItem worksheet;

  /// Full server content payload (for download + metadata). Falls back to
  /// SavedMaterial lookup / reconstruction when absent.
  final Map<String, dynamic>? contentPayload;
  final Map<String, dynamic>? assets;
  final String? contentId;

  const ShowGeneratedWorksheetEvent(
    this.worksheet, {
    this.contentPayload,
    this.assets,
    this.contentId,
  });

  @override
  List<Object?> get props => [worksheet, contentPayload, assets, contentId];
}

class SaveWorksheetEvent extends WorksheetEvent {
  final WorksheetItem worksheet;
  const SaveWorksheetEvent(this.worksheet);
  @override
  List<Object?> get props => [worksheet];
}

abstract class WorksheetState extends Equatable {
  const WorksheetState();
  @override
  List<Object?> get props => [];
}

class WorksheetInitial extends WorksheetState {}
class WorksheetGenerating extends WorksheetState {}

class WorksheetGenerated extends WorksheetState {
  final WorksheetItem worksheet;
  final bool isSaved;

  /// Full server content payload + assets for Download (real file + metadata).
  final Map<String, dynamic>? contentPayload;
  final Map<String, dynamic>? assets;
  final String? contentId;

  const WorksheetGenerated({
    required this.worksheet,
    this.isSaved = false,
    this.contentPayload,
    this.assets,
    this.contentId,
  });

  @override
  List<Object?> get props =>
      [worksheet, isSaved, contentPayload, assets, contentId];
}

/// Offline request stored as PENDING_GENERATION; server generation runs on sync.
class WorksheetQueuedOffline extends WorksheetState {
  final String requestId;
  final WorksheetItem scaffold;

  const WorksheetQueuedOffline({
    required this.requestId,
    required this.scaffold,
  });

  @override
  List<Object?> get props => [requestId, scaffold];
}

class WorksheetBloc extends Bloc<WorksheetEvent, WorksheetState> {
  final ResourceRepository resourceRepository;

  WorksheetBloc({required this.resourceRepository}) : super(WorksheetInitial()) {
    on<GenerateWorksheetEvent>((event, emit) async {
      emit(WorksheetGenerating());
      final queued = await resourceRepository.generateWorksheet(
        grade: event.grade,
        subject: event.subject,
        outcomeCode: event.outcomeCode,
        targetLanguage: event.targetLanguage,
        difficulty: event.difficulty,
        type: event.type,
        questionCount: event.questionCount,
      );
      emit(WorksheetQueuedOffline(
        requestId: queued.requestId,
        scaffold: queued.scaffold,
      ));
    });

    on<ShowGeneratedWorksheetEvent>((event, emit) async {
      emit(WorksheetGenerated(
        worksheet: event.worksheet,
        isSaved: true,
        contentPayload: event.contentPayload,
        assets: event.assets,
        contentId: event.contentId,
      ));
    });

    on<SaveWorksheetEvent>((event, emit) async {
      if (state is WorksheetGenerated) {
        final current = state as WorksheetGenerated;
        await resourceRepository.saveWorksheet(event.worksheet);
        emit(WorksheetGenerated(
          worksheet: current.worksheet,
          isSaved: true,
          contentPayload: current.contentPayload,
          assets: current.assets,
          contentId: current.contentId,
        ));
      }
    });
  }
}
