import 'dart:convert';
import 'package:drift/drift.dart';
import 'app_database.dart';

class DatabaseSeeder {
  final AppDatabase db;

  DatabaseSeeder(this.db);

  /// Removes demo records that older app versions auto-inserted
  /// (fictional teacher, sample students, sample results/gaps and the
  /// default worksheet). Matches exact legacy seed fingerprints only.
  Future<void> _removeLegacyDemoRecords() async {
    try {
      await (db.delete(db.teachers)
            ..where((t) =>
                t.id.equals('t_001') & t.name.equals('Sunita Marandi')))
          .go();

      await (db.delete(db.students)
            ..where((t) =>
                t.id.isIn(['stu_1', 'stu_2', 'stu_3', 'stu_4']) &
                t.name.isIn([
                  'Asha Hembrom',
                  'Ravi Munda',
                  'Birsa Ho',
                  'Sita Soren',
                ])))
          .go();

      await (db.delete(db.assessmentResults)
            ..where((t) => t.id.isIn(['res_init_1', 'res_init_2'])))
          .go();

      await (db.delete(db.learningGaps)
            ..where((t) => t.id.isIn(['gap_1', 'gap_2'])))
          .go();

      await (db.delete(db.remedialRecommendations)
            ..where((t) => t.id.isIn(['rec_1', 'rec_2'])))
          .go();

      await (db.delete(db.savedMaterials)
            ..where((t) => t.id.equals('ws_default_1')))
          .go();
    } catch (_) {
      // Cleanup is best-effort; seeding proceeds regardless.
    }
  }

  Future<void> seedIfNeeded() async {
    // One-time cleanup of demo records inserted by older app versions.
    // Only rows matching the exact legacy seed fingerprints are removed;
    // real teacher-entered data is never touched.
    await _removeLegacyDemoRecords();

    // Seeding is idempotent and covers reference/curriculum content only.
    // Teacher identity, student rosters, assessment results and generated
    // resources are NEVER seeded: they are created only by real app usage.
    final existingOutcomes = await db.curriculumDao.getOutcomes();
    if (existingOutcomes.isNotEmpty) {
      return; // Already seeded
    }

    await db.transaction(() async {
      final now = DateTime.now();

      // 1. Seed Classrooms
      for (int g = 1; g <= 5; g++) {
        await db.into(db.classrooms).insertOnConflictUpdate(
          ClassroomsCompanion(
            id: Value('cls_$g'),
            grade: Value(g),
            name: Value('Class $g'),
            section: const Value('A'),
            isActive: Value(g <= 3),
          ),
        );
      }

      // 3. Seed NIPUN Outcomes
      await db.curriculumDao.insertOutcomes([
        const NipunOutcomesCompanion(
          id: Value('out_001'),
          code: Value('M2.1.4'),
          grade: Value(2),
          domain: Value('Foundational Numeracy'),
          competency: Value('Numbers and Operations'),
          titleEn: Value('Numbers up to 100 (दहाई और इकाई)'),
          titleHi: Value('100 तक की संख्याओं की समझ और तुलना'),
          targetDescription: Value('Recognizes, reads and writes numbers up to 100 using physical objects and local counters.'),
          defaultStatus: Value('needsSupport'),
          unfinishedSkill: Value('Recognizing quantities and place value above 50'),
        ),
        const NipunOutcomesCompanion(
          id: Value('out_002'),
          code: Value('M2.2.1'),
          grade: Value(2),
          domain: Value('Foundational Numeracy'),
          competency: Value('Basic Operations'),
          titleEn: Value('Addition within 20 with concrete objects'),
          titleHi: Value('20 तक के जोड़ को मूर्त वस्तुओं से समझना'),
          targetDescription: Value('Solves real-life addition problems using bundled tamarind/mahua seeds.'),
          defaultStatus: Value('developing'),
          unfinishedSkill: Value('Mental addition without fingers'),
        ),
        const NipunOutcomesCompanion(
          id: Value('out_003'),
          code: Value('L2.1.3'),
          grade: Value(2),
          domain: Value('Foundational Literacy'),
          competency: Value('Oral Language Development'),
          titleEn: Value('Picture Talk and Story Narration'),
          titleHi: Value('चित्र देखकर अपनी मातृभाषा व हिंदी में बातचीत'),
          targetDescription: Value('Expresses opinions on village/forest scenes in mother tongue and simple Hindi.'),
          defaultStatus: Value('achieved'),
          unfinishedSkill: Value('Complex sentence formation in second language'),
        ),
        const NipunOutcomesCompanion(
          id: Value('out_004'),
          code: Value('L2.3.2'),
          grade: Value(2),
          domain: Value('Foundational Literacy'),
          competency: Value('Reading and Comprehension'),
          titleEn: Value('Bilingual Short Story Reading'),
          titleHi: Value('सरल द्विभाषी कहानी पढ़कर समझना'),
          targetDescription: Value('Reads grade-level bilingual stories with 80% comprehension accuracy.'),
          defaultStatus: Value('developing'),
          unfinishedSkill: Value('Connecting story events to personal experiences'),
        ),
      ]);

      // 4. Seed Detailed Lesson Plan for M2.1.4
      final stepsJson = jsonEncode([
        {
          'stepNumber': 1,
          'stage': 'explain',
          'title': 'Oral Explanation & Real-life Connection',
          'titleHi': 'मौखिक परिचय व स्थानीय संदर्भ',
          'scriptHindi': 'बच्चों! जब हम हाट (बाजार) जाते हैं, तो महुआ या इमली को कैसे गिनते हैं? दस-दस की ढेरी बनाकर!',
          'scriptTribal': 'Mundari: होनको! बु हाट ते सेन रे महुआ चिमिन लेका बु लेकाये? गेल-गेल पुतली बाईकेते!',
          'teacherTip': 'Speak slowly in Hindi, then repeat the key cue in the classroom mother tongue.',
          'localContextPrompt': 'Connect with the weekly Tuesday Torpa Haat market.',
        },
        {
          'stepNumber': 2,
          'stage': 'demonstrate',
          'title': 'Concrete Demonstration',
          'titleHi': 'करके दिखाना (मूर्त प्रदर्शन)',
          'scriptHindi': 'देखो, यह 10 तीलियों का एक बंडल है—इसे हम एक "दहाई" कहते हैं।',
          'scriptTribal': 'Ho: नेलपे, नेआ 10 काठी रेयाः मिद बंडल—नेयागे "गेल" मेनाःआ।',
          'teacherTip': 'Hold the bundle high so all children see clearly. Tap each seed.',
          'localContextPrompt': 'Use bamboo toothpicks or broom sticks tied with string.',
        },
        {
          'stepNumber': 3,
          'stage': 'ask',
          'title': 'Interactive Check Question',
          'titleHi': 'कक्षा प्रश्नोत्तरी',
          'scriptHindi': 'अगर मेरे पास 3 बंडल और 4 खुली तीलियां हैं, तो कुल कितनी तीलियां हुईं?',
          'scriptTribal': 'Santali: आपे चेत् पे मेना? पेया गेल आर पोनया सुसुम रे तिन हुयुगा? (34)',
          'teacherTip': 'Allow children to discuss in their mother tongue with a neighbor before answering.',
          'localContextPrompt': 'Encourage choral count first, then individual call-out.',
        },
        {
          'stepNumber': 4,
          'stage': 'activity',
          'title': 'Hands-on Small Group Activity',
          'titleHi': 'समूह गतिविधि (महुआ बीज खेल)',
          'scriptHindi': 'अपनी थाली में 45 बीज बनाओ—चार बंडल और पाँच खुले बीज।',
          'scriptTribal': 'Mundari: आपन-आपन थाली रे मोड़े-गेल-अपिया जांग बाईपे!',
          'teacherTip': 'Circulate with the tablet, observe which learners struggle with counting beyond 50.',
          'localContextPrompt': 'Pair a confident bilingual student with a mono-lingual learner.',
        },
        {
          'stepNumber': 5,
          'stage': 'practice',
          'title': 'Guided Practice & Worksheet',
          'titleHi': 'अभ्यास पत्रक व स्लेट कार्य',
          'scriptHindi': 'अब अपनी स्लेट पर लिखें: 4 दहाई + 5 इकाई = 45।',
          'scriptTribal': 'Santali: स्लेट रे ओलपे: पोन गेल आर मोड़े = 45।',
          'teacherTip': 'Use bilingual number cards for visual reference.',
          'localContextPrompt': 'Point to the numeral chart painted on the classroom wall.',
        },
        {
          'stepNumber': 6,
          'stage': 'check',
          'title': 'Formative Assessment Check',
          'titleHi': 'त्वरित मूल्यांकन (जांच)',
          'scriptHindi': 'रवि और आशा, मुझे 52 बनाकर दिखाओ।',
          'scriptTribal': 'Ho: रवि आर आशा, 52 लेका केते नेलइपे।',
          'teacherTip': 'Open Tablet Assessment immediately to log responses for Asha and Ravi.',
          'localContextPrompt': 'Record physical demonstration on the single teacher tablet.',
        },
      ]);

      final tribalVocabJson = jsonEncode({
        'One': 'Ho: एतेए | Mundari: मियाद | Santali: मित',
        'Ten': 'Ho: गेल | Mundari: गेल | Santali: गेल',
        'Bundle (Ten)': 'Ho: गेल बंडल | Mundari: गेल पुतली | Santali: गेल मुटा',
        'Seeds': 'Ho: जांग | Mundari: जांग | Santali: जांग',
        'How many?': 'Ho: चिमिन? | Mundari: चिमिन? | Santali: तिन?',
      });

      final reqMaterialsJson = jsonEncode([
        'Mahua or tamarind seeds (100+)',
        'Sal tree leaves or small bowls',
        'Chalk and slates / blackboard',
        'Bilingual Number Flashcards (1–100)',
      ]);

      await db.lessonDao.insertOrUpdateLesson(
        LessonsCompanion(
          id: const Value('lp_m2_1_4'),
          title: const Value('Numbers up to 100: Place Value & Bundles'),
          titleHi: const Value('संख्याएँ 1 से 100: दहाई-इकाई बंडल और गिनती'),
          outcomeCode: const Value('M2.1.4'),
          outcomeTitle: const Value('Counts, reads and compares objects up to 100'),
          grade: const Value(2),
          subject: const Value('Mathematics'),
          durationMinutes: const Value(40),
          learningObjective: const Value('Children will bundle 10 sticks/seeds into "Gela/Dahaai" and identify numbers up to 100 in Hindi and Mundari/Ho/Santali.'),
          prerequisiteKnowledge: const Value('Counting fluently up to 20; familiarity with single digits.'),
          teacherMoves: const Value('Demonstrate with 10 mahua seeds per leaf plate, prompt counting in mother tongue, then bridge to Hindi numerals.'),
          activityOverview: const Value('Mahua Seed Grouping: Small groups create 10-bundles and explain remainder units.'),
          assessmentStrategy: const Value('Ask individual student to pick 3 bundles and 4 loose seeds, state number in mother tongue and write 34.'),
          remediationOption: const Value('Concrete single-to-ten bundling using rubber bands and sal twigs.'),
          tribalVocabularyJson: Value(tribalVocabJson),
          requiredMaterialsJson: Value(reqMaterialsJson),
          stepsJson: Value(stepsJson),
          createdAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('synced'),
        ),
      );

      // 5. Seed Local Contexts
      await db.curriculumDao.insertLocalContexts([
        const LocalContextsCompanion(
          id: Value('lc_001'),
          category: Value('Local Objects'),
          title: Value('Mādal (मांदर)'),
          titleHi: Value('मांदर और नगाड़ा की ताल पर गिनती'),
          description: Value('Traditional terracotta two-headed drum used across Jharkhand tribal festivities.'),
          culturalRelevance: Value('Children recognize 2-beat and 3-beat rhythm cycles for counting patterns.'),
          tribalTerm: Value('Mundari: दुरंग मांदल | Santali: तुम्दाक'),
          language: Value('santali'),
        ),
        const LocalContextsCompanion(
          id: Value('lc_002'),
          category: Value('Environment'),
          title: Value('Mahua Flowers & Seeds (महुआ)'),
          titleHi: Value('महुआ के फूल व बीज संग्रह'),
          description: Value('Fallen mahua flower collection in spring season; standard rural counting currency.'),
          culturalRelevance: Value('Every child collects mahua with grandparents in baskets; natural ten-frame grouping.'),
          tribalTerm: Value('Ho: मादम जांग | Mundari: मदकम'),
          language: Value('ho'),
        ),
        const LocalContextsCompanion(
          id: Value('lc_003'),
          category: Value('Stories'),
          title: Value('The Clever Jackal & Sarhul Tree'),
          titleHi: Value('चतुर सियार और सखुआ का वृक्ष'),
          description: Value('Folk tale highlighting nature preservation, animal trickery, and forest sounds.'),
          culturalRelevance: Value('Reinforces sacred Sal grove (Sarna sthal) reverence while teaching descriptive adjectives.'),
          tribalTerm: Value('Mundari: सरजॉम बा | Santali: सारजोम'),
          language: Value('mundari'),
        ),
        const LocalContextsCompanion(
          id: Value('lc_004'),
          category: Value('Mathematics'),
          title: Value('Weekly Haat (साप्ताहिक हाट)'),
          titleHi: Value('हाट में खरीदारी और सिक्कों का हिसाब'),
          description: Value('Using 5, 10, and 20 rupee currency tokens to buy vegetables in the village weekly market.'),
          culturalRelevance: Value('Practical financial literacy contextualized to Torpa, Khunti rural markets.'),
          tribalTerm: Value('Ho: हाट रेयाः हिसाब | Mundari: हाट-बाजार'),
          language: Value('ho'),
        ),
      ]);

      // 6. Seed Activities
      await db.curriculumDao.insertActivities([
        ActivitiesCompanion(
          id: const Value('act_001'),
          title: const Value('Sal Leaf Number Tracing'),
          titleHi: const Value('सखुआ के पत्तों पर संख्याओं की माला'),
          grade: const Value(2),
          subject: const Value('Mathematics'),
          strandOrStage: const Value('Skills Practice'),
          language: const Value('mundari'),
          durationMinutes: const Value(20),
          difficulty: const Value('easy'),
          materials: const Value('Dried sal leaves, chalk, small pebbles'),
          teacherStepsJson: Value(jsonEncode([
            'Hand out 5 broad sal leaves to each child.',
            'Instruct students to write numerals 10, 20, 30, 40, 50 with chalk.',
            'Place corresponding pebble counters beside each leaf.',
          ])),
          studentStepsJson: Value(jsonEncode([
            'Write numeral on leaf.',
            'Count pebbles in Mundari: गेल, हिसि, हिसि-गेल.',
            'Show neighbor and verify.',
          ])),
          questionsJson: Value(jsonEncode(['30 में कितने 10 हैं? (चिमिन गेल मेनाः?)'])),
          expectedResponse: const Value('तीन दहाई (अपिया गेल).'),
          audioPromptHindi: const Value('सखुआ के पत्तों पर 10-10 की ढेरी बनाकर गिनें।'),
          audioPromptTribal: const Value('सरजॉम साकाम रे गेल-गेल लेका केते नेलपे।'),
          isSaved: const Value(true),
        ),
        ActivitiesCompanion(
          id: const Value('act_002'),
          title: const Value('Sound-Symbol Forest Bird Match'),
          titleHi: const Value('वन पक्षियों की ध्वनियां और अक्षर मिलान'),
          grade: const Value(2),
          subject: const Value('Language'),
          strandOrStage: const Value('Decoding'),
          language: const Value('santali'),
          durationMinutes: const Value(15),
          difficulty: const Value('medium'),
          materials: const Value('Bird flashcards with Santali and Hindi phonics'),
          teacherStepsJson: Value(jsonEncode([
            'Imitate local bird calls (कोयल, मैना, तोता).',
            'Ask children which letter sound starts the bird name.',
            'Show the card with Ol Chiki / Devanagari letter.',
          ])),
          studentStepsJson: Value(jsonEncode([
            'Listen to the call.',
            'Point to the matching letter card.',
            'Pronounce aloud together.',
          ])),
          questionsJson: Value(jsonEncode(['कोयल की पहली ध्वनि क्या है? (चेत् साडे?)'])),
          expectedResponse: const Value('ध्वनि "क" (साडे क).'),
          audioPromptHindi: const Value('पक्षी की आवाज सुनें और सही अक्षर चुनें।'),
          audioPromptTribal: const Value('चेणे साडे आंजोम केते सहीं आखोर बाछावपे।'),
          isSaved: const Value(false),
        ),
        ActivitiesCompanion(
          id: const Value('act_003'),
          title: const Value('Weekly Haat Role Play'),
          titleHi: const Value('हाट-बाजार का नाटक व संवाद'),
          grade: const Value(2),
          subject: const Value('Language'),
          strandOrStage: const Value('Oral Language'),
          language: const Value('ho'),
          durationMinutes: const Value(25),
          difficulty: const Value('easy'),
          materials: const Value('Wooden vegetable replicas, play currency'),
          teacherStepsJson: Value(jsonEncode([
            'Designate 2 students as shopkeepers, 4 as buyers.',
            'Model greeting and bargaining dialogue in Ho and Hindi.',
          ])),
          studentStepsJson: Value(jsonEncode([
            'Buyer asks price: "नेया चिमिन गोनोङ?"',
            'Shopkeeper replies with number.',
            'Complete transaction using bilingual phrases.',
          ])),
          questionsJson: Value(jsonEncode(['सब्जी कितने की है? (सब्जी चिमिन रे?)'])),
          expectedResponse: const Value('दस रुपये किलो (गेल टका किलो).'),
          audioPromptHindi: const Value('दुकानदार और ग्राहक बनकर बातचीत करें।'),
          audioPromptTribal: const Value('दुकानी आर ग्राहक बाईकेते जगरपे।'),
          isSaved: const Value(false),
        ),
        ActivitiesCompanion(
          id: const Value('rem_001'),
          title: const Value('Remedial: Mahua Seed 10-Bundles'),
          titleHi: const Value('उपचारात्मक शिक्षण: महुआ बीज 10-बंडल खेल'),
          grade: const Value(2),
          subject: const Value('Mathematics'),
          strandOrStage: const Value('Skills Teaching'),
          language: const Value('mundari'),
          durationMinutes: const Value(15),
          difficulty: const Value('easy'),
          materials: const Value('50 Mahua seeds, 5 small sal leaf bowls, chalk slate'),
          teacherStepsJson: Value(jsonEncode([
            'Sit directly with student in one-on-one session.',
            'Place 10 seeds in bowl 1. Say: "नेया 1 गेल (10) ताना।" Have student repeat.',
            'Add bowls one by one: 20 (हिसि), 30 (हिसि-गेल), 40 (बार-हिसि), 50 (बार-हिसि-गेल).',
            'Add 2 loose seeds: "अब कुल कितना हुआ? 52!"',
          ])),
          studentStepsJson: Value(jsonEncode([
            'Physically count seeds into each bowl.',
            'State total count in mother tongue and then write in Hindi on slate.',
          ])),
          questionsJson: Value(jsonEncode(['5 बंडल में कितने बीज हैं? (5 गेल रे चिमिन जांग?)'])),
          expectedResponse: const Value('50 बीज (हिसि-गेल / 50).'),
          audioPromptHindi: const Value('प्रत्येक कटोरी में 10-10 बीज रखकर 50 तक गिनें।'),
          audioPromptTribal: const Value('साकाम कटोरी रे गेल-गेल जांग दोहकेते 50 धाब लेकापे।'),
          isSaved: const Value(true),
        ),
      ]);

      // 7. Seed Assessment Questions
      final questionsList = jsonEncode([
        {
          'number': 1,
          'promptHindi': 'मौखिक गणना: स्लेट पर बनी 7 मछलियों को देखकर मुण्डारी या संताली में गिनें।',
          'promptTribal': 'Santali: सात चेत् को मेताक-आ? (मित, बार, पे, पोन, मोड़े, तुरूई, सांते)',
          'type': 'oral',
          'choices': ['सांते (7)', 'तुरूई (6)', 'इरल (8)'],
          'correctIndex': 0,
          'teacherObservationRubric': 'Observe if student counts accurately 1-by-1 without skipping.',
        },
        {
          'number': 2,
          'promptHindi': 'मूर्त प्रदर्शन: थाली में से 5 दहाई (50) और 4 खुली तीलियां अलग करें। कुल संख्या बताएं।',
          'promptTribal': 'Mundari: 5 गेल आर 4 सुसुम लेकाकेते संख्या ओलापे।',
          'type': 'physical',
          'choices': ['54 (मोड़े गेल उपून)', '45 (उपून गेल मोड़े)', '50 (मोड़े गेल)'],
          'correctIndex': 0,
          'teacherObservationRubric': 'Check if student confuses tens and units position.',
        },
        {
          'number': 3,
          'promptHindi': 'लिखित पहचान: 68 में दहाई का अंक कौन-सा है?',
          'promptTribal': 'Ho: 68 रे गेल स्थान रे चिमिन मेनाः?',
          'type': 'written',
          'choices': ['6', '8', '60'],
          'correctIndex': 0,
          'teacherObservationRubric': 'Verify child writes digit 6 representing 60.',
        },
      ]);

      await db.assessmentDao.insertAssessmentQuestions(
        AssessmentQuestionsCompanion(
          id: const Value('aq_m2_1_4'),
          outcomeCode: const Value('M2.1.4'),
          questionsJson: Value(questionsList),
        ),
      );

      // NOTE: Student rosters, assessment results, learning gaps and
      // remedial recommendations are NEVER seeded. They are created only by
      // real classroom usage and stay isolated from teacher progress.

      // 9. Seed Quick Phrases
      await db.translationDao.insertQuickPhrases([
        const QuickPhrasesCompanion(
          id: Value('qp_1'),
          category: Value('Classroom Instructions'),
          hindi: Value('अपनी पुस्तक पृष्ठ संख्या 5 पर खोलें।'),
          ho: Value('आपेआ पुथी साकाम 5 रे ओड़ोङपे।'),
          mundari: Value('आपन-आपन हिसाब पुथी साकाम मोड़े रे उगुइपे।'),
          santali: Value('आपेआक् पुथी साकाम मोड़े रे झिज्पे।'),
        ),
        const QuickPhrasesCompanion(
          id: Value('qp_2'),
          category: Value('Classroom Instructions'),
          hindi: Value('सब बच्चे ध्यान से सुनो।'),
          ho: Value('सबिन होनको सुकूते आंजोमपे।'),
          mundari: Value('सबिन होनको सुकूते आंजोमपे।'),
          santali: Value('सान्ते गिदराको ध्यान ते आंजोमपे।'),
        ),
        const QuickPhrasesCompanion(
          id: Value('qp_3'),
          category: Value('Greetings'),
          hindi: Value('नमस्ते बच्चों! आप सब कैसे हैं?'),
          ho: Value('जोहार होनको! आपे चिलेका मेनाःपेया?'),
          mundari: Value('जोहार होनको! आपे चिलेका मेनाःपेया?'),
          santali: Value('जोहार गिदराको! चेत् लेका मेनाक् पेया?'),
        ),
        const QuickPhrasesCompanion(
          id: Value('qp_4'),
          category: Value('Encouragement'),
          hindi: Value('शाबाश! आपने बहुत अच्छा उत्तर दिया।'),
          ho: Value('बेश! आपे पुरः बेस काजीपे काजियाना।'),
          mundari: Value('बेश! आपे खूब बेस काजी रूवाड़केदा।'),
          santali: Value('नापाय! खूब बेस पे रोड़केदा।'),
        ),
        const QuickPhrasesCompanion(
          id: Value('qp_5'),
          category: Value('Questions'),
          hindi: Value('क्या किसी बच्चे को समझ नहीं आया?'),
          ho: Value('जाँय होन कापे बुझावकेदा चि?'),
          mundari: Value('जाँय होन कापे बुझावकेदा चि?'),
          santali: Value('जाहाँय गिदरा बांय बुझाव दाड़ेयादा?'),
        ),
      ]);

      // 13. Seed Language Packs
      await db.offlineDao.insertLanguagePacks([
        const LanguagePacksCompanion(
          id: Value('pack_mundari'),
          language: Value('mundari'),
          sizeMb: Value(210),
          version: Value('Installed'),
          status: Value('installed'),
          progress: Value(1.0),
        ),
        const LanguagePacksCompanion(
          id: Value('pack_ho'),
          language: Value('ho'),
          sizeMb: Value(240),
          version: Value('Installed'),
          status: Value('installed'),
          progress: Value(1.0),
        ),
        const LanguagePacksCompanion(
          id: Value('pack_santali'),
          language: Value('santali'),
          sizeMb: Value(220),
          version: Value('Sync when online'),
          status: Value('available'),
          progress: Value(0.0),
        ),
      ]);

      // 14. Seed Content Packs
      await db.offlineDao.insertContentPacks([
        const ContentPacksCompanion(
          id: Value('cp_1_3'),
          title: Value('NIPUN Foundational (Classes 1–3)'),
          description: Value('Complete literacy & numeracy lesson scripts, sound cards, and audio packs.'),
          sizeMb: Value(450),
          isInstalled: Value(true),
        ),
        const ContentPacksCompanion(
          id: Value('cp_4_5'),
          title: Value('Primary Curriculum (Classes 4–5)'),
          description: Value('Jharkhand state board environmental studies and mathematics modules.'),
          sizeMb: Value(380),
          isInstalled: Value(true),
        ),
        const ContentPacksCompanion(
          id: Value('cp_audio_hi'),
          title: Value('Jharkhand Local Audio Library'),
          description: Value('Native speaker tribal pronunciations for 1200+ foundational vocabulary words.'),
          sizeMb: Value(310),
          isInstalled: Value(true),
        ),
      ]);

      // NOTE: No default worksheets are seeded. Saved materials appear only
      // after the teacher actually generates them.
    });
  }
}
