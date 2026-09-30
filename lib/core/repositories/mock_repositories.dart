import 'dart:async';
import '../enums/app_enums.dart';
import '../models/app_models.dart';
import 'app_repositories.dart';

class MockTeacherRepository implements TeacherRepository {
  // Account-scoped in-memory profiles keyed by Supabase user UUID.
  final Map<String, TeacherProfile> _profiles = {};
  final String? Function()? currentUserIdProvider;

  MockTeacherRepository({this.currentUserIdProvider});

  String? get _ownerId {
    try {
      final id = currentUserIdProvider?.call()?.trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  bool get _legacy => currentUserIdProvider == null;

  // Legacy global profile (no provider wired, e.g. older widget tests).
  TeacherProfile _legacyProfile = const TeacherProfile(
    id: 'teacher_primary',
    name: '',
    school: '',
    district: '',
    state: 'Jharkhand',
    classesTaught: [1, 2, 3],
    teachingLanguage: 'Hindi',
    supportedClassroomLanguages: [
      TribalLanguage.mundari,
      TribalLanguage.ho,
      TribalLanguage.santali,
    ],
    activeSessionLanguage: TribalLanguage.mundari,
  );

  TeacherProfile _empty(String id) => TeacherProfile(
        id: id,
        name: '',
        school: '',
        district: '',
        state: 'Jharkhand',
        classesTaught: const [1, 2, 3],
        teachingLanguage: 'Hindi',
        supportedClassroomLanguages: const [
          TribalLanguage.mundari,
          TribalLanguage.ho,
          TribalLanguage.santali,
        ],
        activeSessionLanguage: TribalLanguage.mundari,
      );

  @override
  Future<TeacherProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_legacy) return _legacyProfile;
    final owner = _ownerId;
    if (owner == null) return _empty('teacher_primary');
    return _profiles[owner] ?? _empty(owner);
  }

  @override
  Future<void> updateProfile(TeacherProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_legacy) {
      _legacyProfile = profile;
      return;
    }
    final owner = _ownerId;
    if (owner == null) return;
    _profiles[owner] = profile.copyWith(id: owner);
  }

  @override
  Future<List<TribalLanguage>> getSelectedLanguages() async {
    if (_legacy) return _legacyProfile.supportedClassroomLanguages;
    return (await getProfile()).supportedClassroomLanguages;
  }

  @override
  Future<void> updateLanguages(List<TribalLanguage> languages) async {
    if (_legacy) {
      _legacyProfile =
          _legacyProfile.copyWith(supportedClassroomLanguages: languages);
      return;
    }
    final p = await getProfile();
    final owner = _ownerId;
    if (owner == null) return;
    _profiles[owner] = p.copyWith(supportedClassroomLanguages: languages);
  }
}

class MockLessonRepository implements LessonRepository {
  final List<NipunOutcome> _outcomes = const [
    NipunOutcome(
      id: 'out_001',
      code: 'M2.1.4',
      grade: 2,
      domain: 'Foundational Numeracy',
      competency: 'Numbers and Operations',
      titleEn: 'Numbers up to 100 (दहाई और इकाई)',
      titleHi: '100 तक की संख्याओं की समझ और तुलना',
      targetDescription: 'Recognizes, reads and writes numbers up to 100 using physical objects and local counters.',
      defaultStatus: OutcomeStatus.needsSupport,
      unfinishedSkill: 'Recognizing quantities and place value above 50',
    ),
    NipunOutcome(
      id: 'out_002',
      code: 'M2.2.1',
      grade: 2,
      domain: 'Foundational Numeracy',
      competency: 'Basic Operations',
      titleEn: 'Addition within 20 with concrete objects',
      titleHi: '20 तक के जोड़ को मूर्त वस्तुओं से समझना',
      targetDescription: 'Solves real-life addition problems using bundled tamarind/mahua seeds.',
      defaultStatus: OutcomeStatus.developing,
      unfinishedSkill: 'Mental addition without fingers',
    ),
    NipunOutcome(
      id: 'out_003',
      code: 'L2.1.3',
      grade: 2,
      domain: 'Foundational Literacy',
      competency: 'Oral Language Development',
      titleEn: 'Picture Talk and Story Narration',
      titleHi: 'चित्र देखकर अपनी मातृभाषा व हिंदी में बातचीत',
      targetDescription: 'Expresses opinions on village/forest scenes in mother tongue and simple Hindi.',
      defaultStatus: OutcomeStatus.achieved,
      unfinishedSkill: 'Complex sentence formation in second language',
    ),
    NipunOutcome(
      id: 'out_004',
      code: 'L2.3.2',
      grade: 2,
      domain: 'Foundational Literacy',
      competency: 'Reading and Comprehension',
      titleEn: 'Bilingual Short Story Reading',
      titleHi: 'सरल द्विभाषी कहानी पढ़कर समझना',
      targetDescription: 'Reads grade-level bilingual stories with 80% comprehension accuracy.',
      defaultStatus: OutcomeStatus.developing,
      unfinishedSkill: 'Connecting story events to personal experiences',
    ),
  ];

  @override
  Future<List<NipunOutcome>> getOutcomes({int? grade, String? domain}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    var list = _outcomes;
    if (grade != null) list = list.where((o) => o.grade == grade).toList();
    if (domain != null) list = list.where((o) => o.domain == domain).toList();
    return list;
  }

  @override
  Future<NipunOutcome?> getOutcomeByCode(String code) async {
    try {
      return _outcomes.firstWhere((o) => o.code == code);
    } catch (_) {
      return _outcomes.first;
    }
  }

  @override
  Future<LessonPlan> getLessonPlanForOutcome(String outcomeCode) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const LessonPlan(
      id: 'lp_m2_1_4',
      title: 'Numbers up to 100: Place Value & Bundles',
      titleHi: 'संख्याएँ 1 से 100: दहाई-इकाई बंडल और गिनती',
      outcomeCode: 'M2.1.4',
      outcomeTitle: 'Counts, reads and compares objects up to 100',
      grade: 2,
      subject: 'Mathematics',
      durationMinutes: 40,
      learningObjective: 'Children will bundle 10 sticks/seeds into "Gela/Dahaai" and identify numbers up to 100 in Hindi and Mundari/Ho/Santali.',
      prerequisiteKnowledge: 'Counting fluently up to 20; familiarity with single digits.',
      teacherMoves: 'Demonstrate with 10 mahua seeds per leaf plate, prompt counting in mother tongue, then bridge to Hindi numerals.',
      activityOverview: 'Mahua Seed Grouping: Small groups create 10-bundles and explain remainder units.',
      assessmentStrategy: 'Ask individual student to pick 3 bundles and 4 loose seeds, state number in mother tongue and write 34.',
      remediationOption: 'Concrete single-to-ten bundling using rubber bands and sal twigs.',
      tribalVocabulary: {
        'One': 'Ho: एतेए | Mundari: मियाद | Santali: मित',
        'Ten': 'Ho: गेल | Mundari: गेल | Santali: गेल',
        'Bundle (Ten)': 'Ho: गेल बंडल | Mundari: गेल पुतली | Santali: गेल मुटा',
        'Seeds': 'Ho: जांग | Mundari: जांग | Santali: जांग',
        'How many?': 'Ho: चिमिन? | Mundari: चिमिन? | Santali: तिन?',
      },
      requiredMaterials: [
        'Mahua or tamarind seeds (100+)',
        'Sal tree leaves or small bowls',
        'Chalk and slates / blackboard',
        'Bilingual Number Flashcards (1–100)',
      ],
      steps: [
        LessonStep(
          stepNumber: 1,
          stage: DeliveryStage.explain,
          title: 'Oral Explanation & Real-life Connection',
          titleHi: 'मौखिक परिचय व स्थानीय संदर्भ',
          scriptHindi: 'बच्चों! जब हम हाट (बाजार) जाते हैं, तो महुआ या इमली को कैसे गिनते हैं? दस-दस की ढेरी बनाकर!',
          scriptTribal: 'Mundari: होनको! बु हाट ते सेन रे महुआ चिमिन लेका बु लेकाये? गेल-गेल पुतली बाईकेते!',
          teacherTip: 'Speak slowly in Hindi, then repeat the key cue in the classroom mother tongue.',
          localContextPrompt: 'Connect with the weekly Tuesday Torpa Haat market.',
        ),
        LessonStep(
          stepNumber: 2,
          stage: DeliveryStage.demonstrate,
          title: 'Concrete Demonstration',
          titleHi: 'करके दिखाना (मूर्त प्रदर्शन)',
          scriptHindi: 'देखो, यह 10 तीलियों का एक बंडल है—इसे हम एक "दहाई" कहते हैं।',
          scriptTribal: 'Ho: नेलपे, नेआ 10 काठी रेयाः मिद बंडल—नेयागे "गेल" मेनाःआ।',
          teacherTip: 'Hold the bundle high so all children see clearly. Tap each seed.',
          localContextPrompt: 'Use bamboo toothpicks or broom sticks tied with string.',
        ),
        LessonStep(
          stepNumber: 3,
          stage: DeliveryStage.ask,
          title: 'Interactive Check Question',
          titleHi: 'कक्षा प्रश्नोत्तरी',
          scriptHindi: 'अगर मेरे पास 3 बंडल और 4 खुली तीलियां हैं, तो कुल कितनी तीलियां हुईं?',
          scriptTribal: 'Santali: आपे चेत् पे मेना? पेया गेल आर पोनया सुसुम रे तिन हुयुगा? (34)',
          teacherTip: 'Allow children to discuss in their mother tongue with a neighbor before answering.',
          localContextPrompt: 'Encourage choral count first, then individual call-out.',
        ),
        LessonStep(
          stepNumber: 4,
          stage: DeliveryStage.activity,
          title: 'Hands-on Small Group Activity',
          titleHi: 'समूह गतिविधि (महुआ बीज खेल)',
          scriptHindi: 'अपनी थाली में 45 बीज बनाओ—चार बंडल और पाँच खुले बीज।',
          scriptTribal: 'Mundari: आपन-आपन थाली रे मोड़े-गेल-अपिया जांग बाईपे!',
          teacherTip: 'Circulate with the tablet, observe which learners struggle with counting beyond 50.',
          localContextPrompt: 'Pair a confident bilingual student with a mono-lingual learner.',
        ),
        LessonStep(
          stepNumber: 5,
          stage: DeliveryStage.practice,
          title: 'Guided Practice & Worksheet',
          titleHi: 'अभ्यास पत्रक व स्लेट कार्य',
          scriptHindi: 'अब अपनी स्लेट पर लिखें: 4 दहाई + 5 इकाई = 45।',
          scriptTribal: 'Santali: स्लेट रे ओलपे: पोन गेल आर मोड़े = 45।',
          teacherTip: 'Use bilingual number cards for visual reference.',
          localContextPrompt: 'Point to the numeral chart painted on the classroom wall.',
        ),
        LessonStep(
          stepNumber: 6,
          stage: DeliveryStage.check,
          title: 'Formative Assessment Check',
          titleHi: 'त्वरित मूल्यांकन (जांच)',
          scriptHindi: 'रवि और आशा, मुझे 52 बनाकर दिखाओ।',
          scriptTribal: 'Ho: रवि आर आशा, 52 लेका केते नेलइपे।',
          teacherTip: 'Open Tablet Assessment immediately to log responses for Asha and Ravi.',
          localContextPrompt: 'Record physical demonstration on the single teacher tablet.',
        ),
      ],
    );
  }

  @override
  Future<List<LocalContextItem>> getLocalContextItems({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final items = const [
      LocalContextItem(
        id: 'lc_001',
        category: 'Local Objects',
        title: 'Mādal (मांदर)',
        titleHi: 'मांदर और नगाड़ा की ताल पर गिनती',
        description: 'Traditional terracotta two-headed drum used across Jharkhand tribal festivities.',
        culturalRelevance: 'Children recognize 2-beat and 3-beat rhythm cycles for counting patterns.',
        tribalTerm: 'Mundari: दुरंग मांदल | Santali: तुम्दाक',
        language: TribalLanguage.santali,
      ),
      LocalContextItem(
        id: 'lc_002',
        category: 'Environment',
        title: 'Mahua Flowers & Seeds (महुआ)',
        titleHi: 'महुआ के फूल व बीज संग्रह',
        description: 'Fallen mahua flower collection in spring season; standard rural counting currency.',
        culturalRelevance: 'Every child collects mahua with grandparents in baskets; natural ten-frame grouping.',
        tribalTerm: 'Ho: मादम जांग | Mundari: मदकम',
        language: TribalLanguage.ho,
      ),
      LocalContextItem(
        id: 'lc_003',
        category: 'Stories',
        title: 'The Clever Jackal & Sarhul Tree',
        titleHi: 'चतुर सियार और सखुआ का वृक्ष',
        description: 'Folk tale highlighting nature preservation, animal trickery, and forest sounds.',
        culturalRelevance: 'Reinforces sacred Sal grove (Sarna sthal) reverence while teaching descriptive adjectives.',
        tribalTerm: 'Mundari: सरजॉम बा | Santali: सारजोम',
        language: TribalLanguage.mundari,
      ),
      LocalContextItem(
        id: 'lc_004',
        category: 'Mathematics',
        title: 'Weekly Haat (साप्ताहिक हाट)',
        titleHi: 'हाट में खरीदारी और सिक्कों का हिसाब',
        description: 'Using 5, 10, and 20 rupee currency tokens to buy vegetables in the village weekly market.',
        culturalRelevance: 'Practical financial literacy contextualized to Torpa, Khunti rural markets.',
        tribalTerm: 'Ho: हाट रेयाः हिसाब | Mundari: हाट-बाजार',
        language: TribalLanguage.ho,
      ),
    ];

    if (category != null && category.isNotEmpty) {
      return items.where((i) => i.category == category).toList();
    }
    return items;
  }

  @override
  Future<List<ActivityItem>> getActivities({String? strand, int? grade, TribalLanguage? language}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    return const [
      ActivityItem(
        id: 'act_001',
        title: 'Sal Leaf Number Tracing',
        titleHi: 'सखुआ के पत्तों पर संख्याओं की माला',
        grade: 2,
        subject: 'Mathematics',
        strandOrStage: 'Skills Practice',
        language: TribalLanguage.mundari,
        durationMinutes: 20,
        difficulty: DifficultyLevel.easy,
        materials: 'Dried sal leaves, chalk, small pebbles',
        teacherSteps: [
          'Hand out 5 broad sal leaves to each child.',
          'Instruct students to write numerals 10, 20, 30, 40, 50 with chalk.',
          'Place corresponding pebble counters beside each leaf.',
        ],
        studentSteps: [
          'Write numeral on leaf.',
          'Count pebbles in Mundari: गेल, हिसि, हिसि-गेल.',
          'Show neighbor and verify.',
        ],
        questions: [
          '30 में कितने 10 हैं? (चिमिन गेल मेनाः?)',
        ],
        expectedResponse: 'तीन दहाई (अपिया गेल).',
        audioPromptHindi: 'सखुआ के पत्तों पर 10-10 की ढेरी बनाकर गिनें।',
        audioPromptTribal: 'सरजॉम साकाम रे गेल-गेल लेका केते नेलपे।',
      ),
      ActivityItem(
        id: 'act_002',
        title: 'Sound-Symbol Forest Bird Match',
        titleHi: 'वन पक्षियों की ध्वनियां और अक्षर मिलान',
        grade: 2,
        subject: 'Language',
        strandOrStage: 'Decoding',
        language: TribalLanguage.santali,
        durationMinutes: 15,
        difficulty: DifficultyLevel.medium,
        materials: 'Bird flashcards with Santali and Hindi phonics',
        teacherSteps: [
          'Imitate local bird calls (कोयल, मैना, तोता).',
          'Ask children which letter sound starts the bird name.',
          'Show the card with Ol Chiki / Devanagari letter.',
        ],
        studentSteps: [
          'Listen to the call.',
          'Point to the matching letter card.',
          'Pronounce aloud together.',
        ],
        questions: [
          'कोयल की पहली ध्वनि क्या है? (चेत् साडे?)',
        ],
        expectedResponse: 'ध्वनि "क" (साडे क).',
        audioPromptHindi: 'पक्षी की आवाज सुनें और सही अक्षर चुनें।',
        audioPromptTribal: 'चेणे साडे आंजोम केते सहीं आखोर बाछावपे।',
      ),
      ActivityItem(
        id: 'act_003',
        title: 'Weekly Haat Role Play',
        titleHi: 'हाट-बाजार का नाटक व संवाद',
        grade: 2,
        subject: 'Language',
        strandOrStage: 'Oral Language',
        language: TribalLanguage.ho,
        durationMinutes: 25,
        difficulty: DifficultyLevel.easy,
        materials: 'Wooden vegetable replicas, play currency',
        teacherSteps: [
          'Designate 2 students as shopkeepers, 4 as buyers.',
          'Model greeting and bargaining dialogue in Ho and Hindi.',
        ],
        studentSteps: [
          'Buyer asks price: "नेया चिमिन गोनोङ?"',
          'Shopkeeper replies with number.',
          'Complete transaction using bilingual phrases.',
        ],
        questions: [
          'सब्जी कितने की है? (सब्जी चिमिन रे?)',
        ],
        expectedResponse: 'दस रुपये किलो (गेल टका किलो).',
        audioPromptHindi: 'दुकानदार और ग्राहक बनकर बातचीत करें।',
        audioPromptTribal: 'दुकानी आर ग्राहक बाईकेते जगरपे।',
      ),
    ];
  }

  @override
  Future<ActivityItem?> getActivityById(String id) async {
    final list = await getActivities();
    try {
      return list.firstWhere((a) => a.id == id);
    } catch (_) {
      return list.first;
    }
  }

  @override
  Future<LessonPlan> createLesson(LessonPlan plan) async {
    return plan;
  }

  @override
  Future<LessonPlan> updateLesson(LessonPlan plan) async {
    return plan;
  }

  @override
  Future<void> updateLessonDeliveryProgress(String lessonId, int currentStep, bool isCompleted) async {}

  @override
  Future<Map<String, dynamic>?> getLessonDeliveryProgress(String lessonId) async {
    return {
      'lessonId': lessonId,
      'currentStep': 1,
      'isCompleted': false,
      'startedAt': DateTime.now(),
    };
  }
}

class MockResourceRepository implements ResourceRepository {
  final List<WorksheetItem> _savedWorksheets = [];

  @override
  Future<QueuedWorksheetGeneration> generateWorksheet({
    required int grade,
    required String subject,
    required String outcomeCode,
    required TribalLanguage targetLanguage,
    required DifficultyLevel difficulty,
    required WorksheetType type,
    required int questionCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Demo stub: queue the real parameters, never fabricate translations.
    final requestId = 'mock_req_${DateTime.now().millisecondsSinceEpoch}';
    final scaffold = WorksheetItem(
      id: requestId,
      title: '$subject Worksheet ($outcomeCode)',
      titleHi: '$subject अभ्यास पत्रक ($outcomeCode)',
      grade: grade,
      subject: subject,
      outcomeCode: outcomeCode,
      targetLanguage: targetLanguage,
      difficulty: difficulty,
      type: type,
      questionCount: questionCount,
      questions: const [],
      createdAt: DateTime.now(),
    );
    return QueuedWorksheetGeneration(requestId: requestId, scaffold: scaffold);
  }

  @override
  Future<List<FlashcardItem>> getFlashcards({required String topic, required TribalLanguage language}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final matching = _savedFlashcards.where((c) =>
      c.topic.toLowerCase() == topic.toLowerCase() &&
      c.language == language,
    ).toList();
    if (matching.isNotEmpty) {
      return matching;
    }
    return const [
      FlashcardItem(
        id: 'fc_1',
        topic: 'Numbers',
        hindiWord: 'एक (1)',
        tribalWord: 'मियाद (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Mi-yaad',
        teacherPrompt: 'Show 1 single finger. Prompt child: "मियाद".',
        emojiOrIcon: '🍎',
        exampleSentence: 'मियाद सेब मेनाः (One apple is here).',
      ),
      FlashcardItem(
        id: 'fc_2',
        topic: 'Numbers',
        hindiWord: 'दो (2)',
        tribalWord: 'बारिया (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Baa-ri-ya',
        teacherPrompt: 'Show 2 birds. Prompt child: "बारिया चेणे".',
        emojiOrIcon: '🐥 🐥',
        exampleSentence: 'बारिया चेणे उडौताना (Two birds are flying).',
      ),
      FlashcardItem(
        id: 'fc_3',
        topic: 'Numbers',
        hindiWord: 'तीन (3)',
        tribalWord: 'अपिया (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'A-pi-ya',
        teacherPrompt: 'Show 3 flowers. Prompt child: "अपिया बाहा".',
        emojiOrIcon: '🌸 🌸 🌸',
        exampleSentence: 'अपिया बाहा बिर रे (Three flowers in forest).',
      ),
      FlashcardItem(
        id: 'fc_4',
        topic: 'Numbers',
        hindiWord: 'चार (4)',
        tribalWord: 'उपून (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'U-poon',
        teacherPrompt: 'Show 4 trees.',
        emojiOrIcon: '🌲 🌲 🌲 🌲',
        exampleSentence: 'उपून दारु मेनाः (Four trees).',
      ),
      FlashcardItem(
        id: 'fc_5',
        topic: 'Numbers',
        hindiWord: 'पाँच (5)',
        tribalWord: 'मोड़े (Mundari)',
        language: TribalLanguage.mundari,
        pronunciation: 'Mo-re',
        teacherPrompt: 'Show whole hand with 5 fingers spread.',
        emojiOrIcon: '🖐️',
        exampleSentence: 'मोड़े ती काटी (Five fingers).',
      ),
    ];
  }

  @override
  Future<List<WorksheetItem>> getSavedWorksheets() async {
    // Web/demo mock keeps no invented worksheets: only genuinely generated ones.
    return _savedWorksheets;
  }

  final List<FlashcardItem> _savedFlashcards = [];

  @override
  Future<List<FlashcardItem>> getSavedFlashcards() async {
    return _savedFlashcards;
  }

  @override
  Future<void> saveFlashcardSet({
    required String topic,
    required TribalLanguage language,
    required List<FlashcardItem> cards,
  }) async {
    _savedFlashcards
      ..removeWhere((c) => c.topic == topic && c.language == language)
      ..addAll(cards);
  }

  @override
  Future<List<ActivityItem>> getSavedActivities() async {
    return MockLessonRepository().getActivities();
  }

  @override
  Future<void> saveWorksheet(WorksheetItem item) async {
    _savedWorksheets.add(item);
  }
}

class MockAssessmentRepository implements AssessmentRepository {
  final List<AssessmentQuestionItem> _questions = const [
    AssessmentQuestionItem(
      number: 1,
      promptHindi: 'मौखिक गणना: स्लेट पर बनी 7 मछलियों को देखकर मुण्डारी या संताली में गिनें।',
      promptTribal: 'Santali: सात चेत् को मेताक-आ? (मित, बार, पे, पोन, मोड़े, तुरूई, सांते)',
      type: QuestionType.oral,
      choices: ['सांते (7)', 'तुरूई (6)', 'इरल (8)'],
      correctIndex: 0,
      teacherObservationRubric: 'Observe if student counts accurately 1-by-1 without skipping.',
    ),
    AssessmentQuestionItem(
      number: 2,
      promptHindi: 'मूर्त प्रदर्शन: थाली में से 5 दहाई (50) और 4 खुली तीलियां अलग करें। कुल संख्या बताएं।',
      promptTribal: 'Mundari: 5 गेल आर 4 सुसुम लेकाकेते संख्या ओलापे।',
      type: QuestionType.physical,
      choices: ['54 (मोड़े गेल उपून)', '45 (उपून गेल मोड़े)', '50 (मोड़े गेल)'],
      correctIndex: 0,
      teacherObservationRubric: 'Check if student confuses tens and units position.',
    ),
    AssessmentQuestionItem(
      number: 3,
      promptHindi: 'लिखित पहचान: 68 में दहाई का अंक कौन-सा है?',
      promptTribal: 'Ho: 68 रे गेल स्थान रे चिमिन मेनाः?',
      type: QuestionType.written,
      choices: ['6', '8', '60'],
      correctIndex: 0,
      teacherObservationRubric: 'Verify child writes digit 6 representing 60.',
    ),
  ];

  @override
  Future<List<AssessmentQuestionItem>> getQuestionsForOutcome(String outcomeCode) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _questions;
  }

  @override
  Future<AssessmentResultData> submitAssessment({
    required String studentId,
    required String studentName,
    required String outcomeCode,
    required List<int> selectedAnswers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    int correct = 0;
    for (int i = 0; i < selectedAnswers.length && i < _questions.length; i++) {
      if (selectedAnswers[i] == _questions[i].correctIndex) {
        correct++;
      }
    }

    final OutcomeStatus status;
    if (correct >= 3) {
      status = OutcomeStatus.achieved;
    } else if (correct >= 2) {
      status = OutcomeStatus.developing;
    } else {
      status = OutcomeStatus.needsSupport;
    }

    return AssessmentResultData(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      studentName: studentName,
      studentId: studentId,
      outcomeCode: outcomeCode,
      outcomeTitle: 'Numbers up to 100 (दहाई और इकाई)',
      totalQuestions: _questions.length,
      correctCount: correct,
      status: status,
      unfinishedSkill: status == OutcomeStatus.achieved
          ? 'Outcome mastered successfully!'
          : 'Recognizing quantities above 50 and distinguishing tens/units.',
      recommendedRemediation: 'Activity: "Mahua Seed Bundles (दहाई-इकाई खेल)" with concrete 10-packs.',
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<ActivityItem> getRemedialActivityForOutcome(String outcomeCode) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const ActivityItem(
      id: 'rem_001',
      title: 'Remedial: Mahua Seed 10-Bundles',
      titleHi: 'उपचारात्मक शिक्षण: महुआ बीज 10-बंडल खेल',
      grade: 2,
      subject: 'Mathematics',
      strandOrStage: 'Skills Teaching',
      language: TribalLanguage.mundari,
      durationMinutes: 15,
      difficulty: DifficultyLevel.easy,
      materials: '50 Mahua seeds, 5 small sal leaf bowls, chalk slate',
      teacherSteps: [
        'Sit directly with student in one-on-one session.',
        'Place 10 seeds in bowl 1. Say: "नेया 1 गेल (10) ताना।" Have student repeat.',
        'Add bowls one by one: 20 (हिसि), 30 (हिसि-गेल), 40 (बार-हिसि), 50 (बार-हिसि-गेल).',
        'Add 2 loose seeds: "अब कुल कितना हुआ? 52!"',
      ],
      studentSteps: [
        'Physically count seeds into each bowl.',
        'State total count in mother tongue and then write in Hindi on slate.',
      ],
      questions: [
        '5 बंडल में कितने बीज हैं? (5 गेल रे चिमिन जांग?)',
      ],
      expectedResponse: '50 बीज (हिसि-गेल / 50).',
      audioPromptHindi: 'प्रत्येक कटोरी में 10-10 बीज रखकर 50 तक गिनें।',
      audioPromptTribal: 'साकाम कटोरी रे गेल-गेल जांग दोहकेते 50 धाब लेकापे।',
    );
  }

  @override
  Future<AssessmentResultData> submitReassessment({
    required String studentId,
    required String outcomeCode,
    required bool passed,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return AssessmentResultData(
      id: 'reass_${DateTime.now().millisecondsSinceEpoch}',
      studentName: 'Learner',
      studentId: studentId,
      outcomeCode: outcomeCode,
      outcomeTitle: 'Numbers up to 100 (दहाई और इकाई)',
      totalQuestions: 2,
      correctCount: passed ? 2 : 1,
      status: passed ? OutcomeStatus.achieved : OutcomeStatus.developing,
      unfinishedSkill: passed ? 'None - Outcome Achieved' : 'Needs additional physical practice',
      recommendedRemediation: passed ? 'Proceed to Next NIPUN Outcome (M2.1.5)' : 'Repeat 10-bundle game',
      completedAt: DateTime.now(),
    );
  }
}

class MockStudentRepository implements StudentRepository {
  final List<StudentRecord> _students = [
    StudentRecord(
      id: 'stu_1',
      name: 'Asha Hembrom',
      rollNumber: 4,
      grade: 2,
      motherTongue: TribalLanguage.santali,
      achievedOutcomes: 4,
      developingOutcomes: 2,
      needsSupportOutcomes: 1,
      literacyProgress: 0.78,
      numeracyProgress: 0.62,
      recentEvidence: 'Assessed on M2.1.4: Place value above 50 requires concrete bundle support.',
      assessmentHistory: [],
      identifiedGaps: ['Recognizing quantities above 50 (M2.1.4)'],
    ),
    StudentRecord(
      id: 'stu_2',
      name: 'Ravi Munda',
      rollNumber: 12,
      grade: 2,
      motherTongue: TribalLanguage.mundari,
      achievedOutcomes: 6,
      developingOutcomes: 1,
      needsSupportOutcomes: 0,
      literacyProgress: 0.85,
      numeracyProgress: 0.90,
      recentEvidence: 'Fluent in 20-addition mental strategies; helps peers in Mundari oral talk.',
      assessmentHistory: [],
      identifiedGaps: [],
    ),
    StudentRecord(
      id: 'stu_3',
      name: 'Birsa Ho',
      rollNumber: 7,
      grade: 2,
      motherTongue: TribalLanguage.ho,
      achievedOutcomes: 3,
      developingOutcomes: 3,
      needsSupportOutcomes: 1,
      literacyProgress: 0.65,
      numeracyProgress: 0.70,
      recentEvidence: 'Understands counting in Ho; developing Hindi numeral recognition.',
      assessmentHistory: [],
      identifiedGaps: ['Hindi numeral writing 21-50 (M2.1.3)'],
    ),
    StudentRecord(
      id: 'stu_4',
      name: 'Sita Soren',
      rollNumber: 15,
      grade: 2,
      motherTongue: TribalLanguage.santali,
      achievedOutcomes: 5,
      developingOutcomes: 2,
      needsSupportOutcomes: 0,
      literacyProgress: 0.82,
      numeracyProgress: 0.75,
      recentEvidence: 'Strong oral decoding; accurately answers bilingual comprehension questions.',
      assessmentHistory: [],
      identifiedGaps: [],
    ),
  ];

  @override
  Future<List<StudentRecord>> getStudents({int? grade}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (grade != null) {
      return _students.where((s) => s.grade == grade).toList();
    }
    return _students;
  }

  @override
  Future<StudentRecord?> getStudentById(String id) async {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return _students.first;
    }
  }

  @override
  Future<void> updateOutcomeStatus(String studentId, String outcomeCode, OutcomeStatus newStatus) async {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final s = _students[idx];
      if (newStatus == OutcomeStatus.achieved) {
        _students[idx] = s.copyWith(
          achievedOutcomes: s.achievedOutcomes + 1,
          needsSupportOutcomes: s.needsSupportOutcomes > 0 ? s.needsSupportOutcomes - 1 : 0,
          numeracyProgress: 0.88,
          identifiedGaps: [],
        );
      }
    }
  }
}

class MockTranslationRepository implements TranslationRepository {
  final List<QuickPhrase> _phrases = const [
    QuickPhrase(
      id: 'qp_1',
      category: 'Classroom Instructions',
      hindi: 'अपनी पुस्तक पृष्ठ संख्या 5 पर खोलें।',
      ho: 'आपेआ पुथी साकाम 5 रे ओड़ोङपे।',
      mundari: 'आपन-आपन हिसाब पुथी साकाम मोड़े रे उगुइपे।',
      santali: 'आपेआक् पुथी साकाम मोड़े रे झिज्पे।',
    ),
    QuickPhrase(
      id: 'qp_2',
      category: 'Classroom Instructions',
      hindi: 'सब बच्चे ध्यान से सुनो।',
      ho: 'सबिन होनको सुकूते आंजोमपे।',
      mundari: 'सबिन होनको सुकूते आंजोमपे।',
      santali: 'सान्ते गिदराको ध्यान ते आंजोमपे।',
    ),
    QuickPhrase(
      id: 'qp_3',
      category: 'Greetings',
      hindi: 'नमस्ते बच्चों! आप सब कैसे हैं?',
      ho: 'जोहार होनको! आपे चिलेका मेनाःपेया?',
      mundari: 'जोहार होनको! आपे चिलेका मेनाःपेया?',
      santali: 'जोहार गिदराको! चेत् लेका मेनाक् पेया?',
    ),
    QuickPhrase(
      id: 'qp_4',
      category: 'Encouragement',
      hindi: 'शाबाश! आपने बहुत अच्छा उत्तर दिया।',
      ho: 'बेश! आपे पुरः बेस काजीपे काजियाना।',
      mundari: 'बेश! आपे खूब बेस काजी रूवाड़केदा।',
      santali: 'नापाय! खूब बेस पे रोड़केदा।',
    ),
    QuickPhrase(
      id: 'qp_5',
      category: 'Questions',
      hindi: 'क्या किसी बच्चे को समझ नहीं आया?',
      ho: 'जाँय होन कापे बुझावकेदा चि?',
      mundari: 'जाँय होन कापे बुझावकेदा चि?',
      santali: 'जाहाँय गिदरा बांय बुझाव दाड़ेयादा?',
    ),
  ];

  @override
  Future<TranslationMessage> translateUtterance({
    required String text,
    required TribalLanguage targetLanguage,
    required bool isTeacher,
    Map<String, String>? contextMeta,
  }) async {
    // Simulated realistic ultra-low latency offline NMT (120ms)
    await Future.delayed(const Duration(milliseconds: 140));

    String translated;
    if (isTeacher) {
      if (text.contains('किताब') || text.contains('पुस्तक')) {
        translated = targetLanguage == TribalLanguage.santali
            ? 'आपेआक् पुथी झिज्पे (Open your books)'
            : 'सबिन होनको आपन-आपन पुथी उगुइपे';
      } else if (text.contains('गिन') || text.contains('संख्या')) {
        translated = targetLanguage == TribalLanguage.ho
            ? 'नेया जांग सुकूँते लेकापे (Count carefully)'
            : 'गेल-गेल लेका केते नेलपे';
      } else {
        translated = targetLanguage == TribalLanguage.santali
            ? 'सान्ते गिदराको ध्यान ते आंजोमपे (Listen attentively in Santali)'
            : 'सबिन होनको आंजोमपे (Children listen)';
      }
    } else {
      // Student speaking in tribal language translated into Hindi for teacher
      translated = 'गुरुजी, मुझे यह सवाल समझ नहीं आ रहा है। कृपया दोबारा बताएं।';
    }

    return TranslationMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      isTeacher: isTeacher,
      speakerName: isTeacher ? 'Teacher (Hindi)' : 'Student (${targetLanguage.displayName})',
      originalText: text,
      translatedText: translated,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
      latencyMs: 128,
      isOfflineNmt: true,
    );
  }

  @override
  Future<List<QuickPhrase>> getQuickPhrases({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (category != null && category.isNotEmpty && category != 'All') {
      return _phrases.where((p) => p.category == category).toList();
    }
    return _phrases;
  }

  @override
  Future<void> submitFeedback({
    required String original,
    required String translated,
    required String issueType,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
  }
}

class MockOfflineRepository implements OfflineRepository {
  List<LanguagePackInfo> _packs = [
    const LanguagePackInfo(
      id: 'pack_mundari',
      language: TribalLanguage.mundari,
      sizeMb: 210,
      version: 'Installed',
      status: PackStatus.installed,
      progress: 1.0,
    ),
    const LanguagePackInfo(
      id: 'pack_ho',
      language: TribalLanguage.ho,
      sizeMb: 240,
      version: 'Installed',
      status: PackStatus.installed,
      progress: 1.0,
    ),
    const LanguagePackInfo(
      id: 'pack_santali',
      language: TribalLanguage.santali,
      sizeMb: 220,
      version: 'Sync when online',
      status: PackStatus.available,
      progress: 0.0,
    ),
  ];

  @override
  Future<List<LanguagePackInfo>> getLanguagePacks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _packs;
  }

  @override
  Future<void> downloadLanguagePack(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _packs = _packs.map((p) {
      if (p.id == id) {
        return p.copyWith(status: PackStatus.installed, progress: 1.0);
      }
      return p;
    }).toList();
  }

  @override
  Future<List<ContentPackInfo>> getContentPacks() async {
    return const [
      ContentPackInfo(
        id: 'cp_1_3',
        title: 'NIPUN Foundational (Classes 1–3)',
        description: 'Complete literacy & numeracy lesson scripts, sound cards, and audio packs.',
        sizeMb: 450,
        isInstalled: true,
      ),
      ContentPackInfo(
        id: 'cp_4_5',
        title: 'Primary Curriculum (Classes 4–5)',
        description: 'Jharkhand state board environmental studies and mathematics modules.',
        sizeMb: 380,
        isInstalled: true,
      ),
      ContentPackInfo(
        id: 'cp_audio_hi',
        title: 'Jharkhand Local Audio Library',
        description: 'Native speaker tribal pronunciations for 1200+ foundational vocabulary words.',
        sizeMb: 310,
        isInstalled: true,
      ),
    ];
  }

  @override
  Future<void> syncClassroomData() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<int> getPendingSyncCount() async {
    return 0;
  }

  @override
  Future<SyncStatusState> getSyncStatus() async {
    return SyncStatusState.synced;
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return DateTime.now().subtract(const Duration(hours: 1));
  }
}
