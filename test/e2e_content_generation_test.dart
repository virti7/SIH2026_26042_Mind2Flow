import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:maatribhasha/core/database/app_database.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/network/connectivity_service.dart';
import 'package:maatribhasha/core/repositories/sqlite_repositories.dart';
import 'package:maatribhasha/core/sync/remote_content_data_source.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/content_generation_bloc.dart';

class E2EConnectivityService implements ConnectivityService {
  bool isConnected = true;
  bool serverAvailable = true;

  @override
  Stream<bool> get connectivityStream => Stream.value(isConnected);

  @override
  Future<bool> get isOnline async => isConnected;

  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async =>
      isConnected && serverAvailable;

  @override
  void simulateOnlineStatus(bool? override) {
    if (override != null) isConnected = override;
  }
}

class E2ERemoteContentDataSource implements RemoteContentDataSource {
  int networkCallCount = 0;

  @override
  Future<GenerationJobModel> requestGeneration(
    TeacherGenerationRequestModel request, {
    String? idempotencyKey,
  }) async {
    networkCallCount++;
    if (request.contentType == 'flashcard') {
      return GenerationJobModel(
        jobId: 'job_e2e_fc_001',
        status: 'REVIEW_REQUIRED',
        contentId: 'GC-G1-NUM-041-01-bi-v1',
        contentType: 'flashcard',
        grade: 1,
        targetLanguage: request.targetLanguage,
        reviewGates: {'santali': 'LANG_SAT_SCRIPT_UNCONFIRMED'},
        content: {
          'content_id': 'GC-G1-NUM-041-01-bi-v1',
          'title': 'Numbers 1 to 20 Flashcards',
          'title_hi': '1 से 20 तक की संख्याएं',
          'grade': 1,
          'subject': 'Mathematics',
          'target_language': request.targetLanguage,
          'content_type': 'flashcard',
          'cards': [
            {
              'index': 1,
              'front': {'hi': 'एक', 'sat': 'ᱢᱤᱫ'},
              'back': {'hi': '1 वस्तु', 'sat': '1 ᱴᱟᱝ'},
              'visual_prompt': '1 apple'
            },
            {
              'index': 2,
              'front': {'hi': 'दो', 'sat': 'ᱵᱟᱨ'},
              'back': {'hi': '2 वस्तुएं', 'sat': '2 ᱴᱟᱝ'},
              'visual_prompt': '2 apples'
            }
          ]
        },
        assets: {
          'image': 'flashcards/1/G1-NUM-041/GC-G1-NUM-041-01-bi-v1.png',
        },
      );
    }
    return GenerationJobModel(
      jobId: 'job_e2e_999',
      status: 'REVIEW_REQUIRED',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: request.targetLanguage,
      reviewGates: {'santali': 'LANG_SAT_SCRIPT_UNCONFIRMED'},
      content: {
        'content_id': 'GC-G1-NUM-032-01-bi-v1',
        'title': 'Numbers up to 100 (100 तक की संख्याएं)',
        'title_hi': '100 तक की संख्याएं',
        'grade': 1,
        'subject': 'Mathematics',
        'target_language': request.targetLanguage,
        'questions': [
          {
            'questionNumber': 1,
            'promptHindi': 'चित्र में कितनी वस्तुएं हैं? सही संख्या पर गोला लगाएं:',
            'promptTribal': 'Santali: चित्र रे चिमिन जो-जो मेनाः?',
            'visualIllustration': '🍎 🍎 🍎 🍎 🍎 🍎 🍎',
            'options': ['5', '7', '9'],
            'answer': '7',
          }
        ]
      },
      assets: {
        'pdf': 'worksheets/1/G1-NUM-032/GC-G1-NUM-032-01-bi-v1.pdf',
      },
    );
  }

  @override
  Future<GenerationJobModel> getJobStatus(String jobId) async {
    networkCallCount++;
    if (jobId.contains('fc')) {
      return const GenerationJobModel(
        jobId: 'job_e2e_fc_001',
        status: 'READY',
        contentId: 'GC-G1-NUM-041-01-bi-v1',
        contentType: 'flashcard',
        grade: 1,
        targetLanguage: 'sat',
      );
    }
    return const GenerationJobModel(
      jobId: 'job_e2e_999',
      status: 'READY',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
    );
  }

  @override
  Future<GenerationJobModel> approveJob(
    String jobId, {
    String? santaliScriptConfirmed,
    String? notes,
  }) async {
    networkCallCount++;
    if (jobId.contains('fc')) {
      return const GenerationJobModel(
        jobId: 'job_e2e_fc_001',
        status: 'READY',
        contentId: 'GC-G1-NUM-041-01-bi-v1',
        contentType: 'flashcard',
        grade: 1,
        targetLanguage: 'sat',
        content: {
          'content_id': 'GC-G1-NUM-041-01-bi-v1',
          'title': 'Numbers 1 to 20 Flashcards',
          'title_hi': '1 से 20 तक की संख्याएं',
          'grade': 1,
          'subject': 'Mathematics',
          'target_language': 'sat',
          'content_type': 'flashcard',
          'cards': [
            {
              'index': 1,
              'front': {'hi': 'एक', 'sat': 'ᱢᱤᱫ'},
              'back': {'hi': '1 वस्तु', 'sat': '1 ᱴᱟᱝ'},
              'visual_prompt': '1 apple'
            },
            {
              'index': 2,
              'front': {'hi': 'दो', 'sat': 'ᱵᱟᱨ'},
              'back': {'hi': '2 वस्तुएं', 'sat': '2 ᱴᱟᱝ'},
              'visual_prompt': '2 apples'
            }
          ]
        },
        assets: {
          'image': 'flashcards/1/G1-NUM-041/GC-G1-NUM-041-01-bi-v1.png',
        },
      );
    }
    return const GenerationJobModel(
      jobId: 'job_e2e_999',
      status: 'READY',
      contentId: 'GC-G1-NUM-032-01-bi-v1',
      contentType: 'worksheet',
      grade: 1,
      targetLanguage: 'sat',
      content: {
        'content_id': 'GC-G1-NUM-032-01-bi-v1',
        'title': 'Numbers up to 100 (100 तक की संख्याएं)',
        'title_hi': '100 तक की संख्याएं',
        'grade': 1,
        'subject': 'Mathematics',
        'target_language': 'sat',
        'questions': [
          {
            'questionNumber': 1,
            'promptHindi': 'चित्र में कितनी वस्तुएं हैं? सही संख्या पर गोला लगाएं:',
            'promptTribal': 'Santali: चित्र रे चिमिन जो-जो मेनाः?',
            'visualIllustration': '🍎 🍎 🍎 🍎 🍎 🍎 🍎',
            'options': ['5', '7', '9'],
            'answer': '7',
          }
        ]
      },
      assets: {
        'pdf': 'worksheets/1/G1-NUM-032/GC-G1-NUM-032-01-bi-v1.pdf',
      },
    );
  }

  @override
  Future<File> downloadAsset(String assetUrlOrPath, String localFileName) async {
    networkCallCount++;
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$localFileName');
    await file.writeAsString('E2E Generated PDF Content for $localFileName');
    return file;
  }
}

void main() {
  test('E2E Full Flow: Online Generation -> Review -> Atomic Download -> Local SQLite -> Complete Offline Access', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final connectivity = E2EConnectivityService();
    final remote = E2ERemoteContentDataSource();
    final bloc = ContentGenerationBloc(
      remoteDataSource: remote,
      connectivityService: connectivity,
      database: db,
    );

    // =========================================================================
    // STEP 1: Online Teacher initiates generation request
    // =========================================================================
    expect(connectivity.isConnected, isTrue);
    expect(await connectivity.checkBackendReachability(), isTrue);

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(
        contentType: 'worksheet',
        grade: 1,
        subject: 'Mathematics',
        targetLanguage: 'sat',
      ),
      idempotencyKey: 'e2e_unique_key_001',
    ));

    // Wait until Review Required (Santali Ol Chiki script gate)
    final reviewState = await bloc.stream.firstWhere((s) => s is ContentGenerationReviewRequired)
        as ContentGenerationReviewRequired;
    expect(reviewState.reviewGates.containsKey('santali'), isTrue);
    expect(reviewState.contentId, 'GC-G1-NUM-032-01-bi-v1');

    // =========================================================================
    // STEP 2: Teacher confirms script review -> Transitions to READY -> Downloads
    // =========================================================================
    bloc.add(const ApproveContentReviewEvent(
      jobId: 'job_e2e_999',
      santaliScriptConfirmed: 'Olck',
    ));

    // Wait until Saved Locally
    final savedState = await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally)
        as ContentGenerationSavedLocally;
    expect(savedState.savedMaterial.id, 'GC-G1-NUM-032-01-bi-v1');
    expect(savedState.savedMaterial.title, contains('Numbers up to 100'));

    final networkCallsDuringOnlinePhase = remote.networkCallCount;
    expect(networkCallsDuringOnlinePhase, greaterThan(0));

    // =========================================================================
    // STEP 3: DISCONNECT NETWORK COMPLETELY (Offline classroom scenario)
    // =========================================================================
    connectivity.isConnected = false;
    connectivity.serverAvailable = false;
    expect(await connectivity.isOnline, isFalse);
    expect(await connectivity.checkBackendReachability(), isFalse);

    // =========================================================================
    // STEP 4: Access and use the saved content OFFLINE with ZERO network calls
    // =========================================================================
    final repo = SqliteResourceRepository(db: db);
    final savedWorksheets = await repo.getSavedWorksheets();

    expect(savedWorksheets, isNotEmpty);
    final offlineItem = savedWorksheets.firstWhere((w) => w.id == 'GC-G1-NUM-032-01-bi-v1');
    expect(offlineItem.title, contains('Numbers up to 100'));
    expect(offlineItem.targetLanguage, TribalLanguage.santali);
    expect(offlineItem.questions, isNotEmpty);
    expect(offlineItem.questions.first.promptHindi, contains('चित्र में कितनी वस्तुएं हैं'));
    expect(offlineItem.questions.first.answer, '7');

    // Verify ZERO additional network calls occurred during offline access
    expect(remote.networkCallCount, equals(networkCallsDuringOnlinePhase));

    await bloc.close();
    await db.close();
  });

  test('E2E Flashcard Flow: Online Generation -> Review -> Save Cards -> Complete Offline Access', () async {
    final connectivity = E2EConnectivityService();
    final remote = E2ERemoteContentDataSource();
    final db = AppDatabase(NativeDatabase.memory());

    final bloc = ContentGenerationBloc(
      remoteDataSource: remote,
      connectivityService: connectivity,
      database: db,
    );

    // STEP 1: Online Teacher generates Flashcards
    connectivity.isConnected = true;
    connectivity.serverAvailable = true;

    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(
        contentType: 'flashcard',
        grade: 1,
        subject: 'Mathematics',
        targetLanguage: 'sat',
        topic: 'Numbers',
      ),
      idempotencyKey: 'e2e_fc_key_001',
    ));

    final reviewState = await bloc.stream.firstWhere((s) => s is ContentGenerationReviewRequired)
        as ContentGenerationReviewRequired;
    expect(reviewState.reviewGates.containsKey('santali'), isTrue);
    expect(reviewState.contentId, 'GC-G1-NUM-041-01-bi-v1');

    // STEP 2: Teacher approves review -> Saved Locally
    bloc.add(const ApproveContentReviewEvent(
      jobId: 'job_e2e_fc_001',
      santaliScriptConfirmed: 'Olck',
    ));

    final savedState = await bloc.stream.firstWhere((s) => s is ContentGenerationSavedLocally)
        as ContentGenerationSavedLocally;
    expect(savedState.savedMaterial.id, 'GC-G1-NUM-041-01-bi-v1');
    expect(savedState.savedMaterial.type, 'flashcard');

    final networkCallsOnline = remote.networkCallCount;

    // STEP 3: Offline Classroom Scenario (Disconnect Network)
    connectivity.isConnected = false;
    connectivity.serverAvailable = false;
    expect(await connectivity.isOnline, isFalse);

    // STEP 4: Access Flashcards Offline from SQLite DB
    final savedMaterials = await db.resourceDao.getSavedMaterials(type: 'flashcard');
    expect(savedMaterials, isNotEmpty);
    final fcMaterial = savedMaterials.firstWhere((m) => m.id == 'GC-G1-NUM-041-01-bi-v1');
    expect(fcMaterial.title, contains('Numbers 1 to 20 Flashcards'));
    expect(fcMaterial.type, 'flashcard');

    // Verify ZERO additional network calls were made offline
    expect(remote.networkCallCount, equals(networkCallsOnline));

    // STEP 5: Verify new generation queues offline without network call
    bloc.add(const StartContentGenerationEvent(
      request: TeacherGenerationRequestModel(
        contentType: 'flashcard',
        grade: 1,
        subject: 'Mathematics',
        targetLanguage: 'sat',
      ),
    ));

    final queuedState = await bloc.stream.firstWhere((s) => s is ContentGenerationQueuedOffline)
        as ContentGenerationQueuedOffline;
    expect(queuedState.requestId, isNotEmpty);
    expect(remote.networkCallCount, equals(networkCallsOnline));

    await bloc.close();
    await db.close();
  });
}
