class AppRoutes {
  AppRoutes._();

  // Common / Entry
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String teacherSetup = '/profile/setup';
  static const String languageSetup = '/classroom-language/setup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String offlineStatus = '/offline/status';

  // Teach Module
  static const String teach = '/teach';
  static const String classOverview = '/teach/class/:classId';
  static const String subjectDetail = '/teach/subject/:subjectId';
  static const String nipunOutcomes = '/teach/outcomes';
  static const String lessonPlanner = '/teach/planner';
  static const String lessonDetail = '/teach/lesson/:lessonId';
  static const String lessonDelivery = '/teach/lesson/:lessonId/delivery';
  static const String teacherCopilot = '/teach/copilot';
  static const String teacherGuidance = '/teach/guidance';
  static const String localContext = '/teach/local-context';
  static const String smartboard = '/teach/smartboard';

  // Literacy Strands
  static const String literacy = '/teach/literacy';
  static const String oralLanguage = '/literacy/oral-language';
  static const String decoding = '/literacy/decoding';
  static const String readingComprehension = '/literacy/reading';
  static const String writingExpression = '/literacy/writing';
  static const String literacyActivityDetail = '/literacy/activity/:id';

  // Numeracy Stages
  static const String oralMath = '/numeracy/oral-math';
  static const String skillsTeaching = '/numeracy/skills-teaching';
  static const String skillsPractice = '/numeracy/skills-practice';
  static const String mathGames = '/numeracy/games';
  static const String numeracyActivityDetail = '/numeracy/activity/:id';

  // Resources
  static const String topicDetail = '/resources/topic';
  static const String worksheetGenerator = '/resources/worksheet-generator';
  static const String worksheetPreview = '/resources/worksheet-preview';
  static const String flashcardGenerator = '/resources/flashcards';
  static const String flashcardViewer = '/resources/flashcard-viewer';
  static const String flashcardDeckBrowser = '/resources/flashcards/browser';
  static const String flashcardPlayer = '/resources/flashcards/player';
  static const String flashcardDeck = '/resources/flashcards/deck';
  static const String flashcardPlayerDetail = '/resources/flashcard-player/:deckId';
  static const String activityLibrary = '/resources/activities';
  static const String resourceActivityDetail = '/resources/activity/:id';
  static const String savedMaterials = '/resources/saved';
  static const String downloads = '/resources/downloads';

  // Assessment & Remediation Loop
  static const String assessmentBuilder = '/assessment/builder';
  static const String assessmentPlay = '/assessment/play';
  static const String assessmentResult = '/assessment/result';
  static const String learningGap = '/assessment/gap';
  static const String remediation = '/assessment/remediation';
  static const String reassessment = '/assessment/reassessment';

  // Translate Module
  static const String translate = '/translate';
  static const String translateContext = '/translate/context';
  static const String languageRouter = '/translate/router';
  static const String studentResponse = '/translate/student-response';
  static const String twoWayConversation = '/translate/conversation';
  static const String quickPhrases = '/translate/phrases';
  static const String newSentence = '/translate/new-sentence';
  static const String translationFeedback = '/translate/feedback';
  static const String reviewerPortal = '/translate/reviewer-portal';
  static const String reviewDetail = '/translate/reviewer-portal/detail';

  // Progress Module (Individual Learners Only)
  static const String progress = '/progress';
  static const String studentList = '/progress/students';
  static const String studentProfile = '/progress/student/:id';
  static const String subjectProgress = '/progress/student/:id/subject';
  static const String assessmentHistory = '/progress/student/:id/assessments';
  static const String learningGapHistory = '/progress/student/:id/gaps';
  static const String recommendations = '/progress/student/:id/recommendations';

  // Offline / Settings
  static const String initialProvisioning = '/offline/provisioning';
  static const String languagePacks = '/offline/languages';
  static const String contentPacks = '/offline/content';
  static const String syncUpdates = '/offline/sync';
  static const String offlineStorage = '/offline/storage';
  static const String settings = '/settings';
  static const String languageSettings = '/settings/language';
  static const String audioSettings = '/settings/audio';
  static const String classroomSettings = '/settings/classroom';
  static const String about = '/about';
// Teacher Review Portal (Separate from Reviewer Portal)
  static const String teacherReview = '/teacher-review';
  static const String teacherReviewDetail = '/teacher-review/detail';
}
