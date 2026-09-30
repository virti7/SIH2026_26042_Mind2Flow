import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/flashcard/flashcard_image_library.dart';
import 'package:maatribhasha/core/content/flashcard/flashcard_progress_store.dart';
import 'package:maatribhasha/core/content/flashcard/santali_flashcard_local_data_source.dart';
import 'package:maatribhasha/core/content/flashcard/santali_flashcard_model.dart';
import 'package:maatribhasha/core/content/flashcard/santali_flashcard_repository.dart';
import 'package:maatribhasha/core/sync/flashcard_image_pdf_writer.dart';
import 'package:maatribhasha/features/resources/presentation/bloc/santali_flashcard_bloc.dart';
import 'package:maatribhasha/features/resources/presentation/pages/santali_flashcard_player_screen.dart';
import 'package:maatribhasha/features/resources/presentation/widgets/santali_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String canonicalAssetRoot = 'assets/prototype_content/flashcards';

  group('Santali Curriculum Flashcard Dataset & Assets Integrity', () {
    test('assets.json and taxonomy.json exist and contain 166 assets across 13 decks', () {
      final assetsFile = File('$canonicalAssetRoot/metadata/assets.json');
      expect(assetsFile.existsSync(), isTrue, reason: 'assets.json must exist in prototype assets');

      final taxFile = File('$canonicalAssetRoot/config/taxonomy.json');
      expect(taxFile.existsSync(), isTrue, reason: 'taxonomy.json must exist in config');

      final rawAssets = jsonDecode(assetsFile.readAsStringSync()) as Map<String, dynamic>;
      final rawTax = jsonDecode(taxFile.readAsStringSync()) as Map<String, dynamic>;

      final assets = rawAssets['assets'] as List<dynamic>;
      expect(assets.length, equals(166), reason: 'Must contain exactly 166 visual vocabulary assets');

      final categories = rawTax['categories'] as Map<String, dynamic>;
      expect(categories.keys.length, equals(12), reason: 'Must contain 12 distinct vocabulary categories');

      // Verify no Windows local paths exist anywhere in metadata paths
      for (final a in assets) {
        final path = (a['asset']?['path'] ?? '').toString();
        expect(path.contains(r':\'), isFalse, reason: 'No asset path should contain Windows disk drive');
        expect(path.startsWith('/'), isFalse, reason: 'Asset paths must be relative');
        expect(path.startsWith('images/'), isTrue, reason: 'Visual assets should be relative to images/');

        final santali = a['label']?['santali'];
        if (santali != null && santali['label_image'] != null) {
          final lblPath = santali['label_image'].toString();
          expect(lblPath.contains(r':\'), isFalse);
          expect(lblPath.startsWith('labels/'), isTrue);
        }
      }
    });

    test('All 166 image assets referenced by assets.json actually exist on disk', () {
      final assetsFile = File('$canonicalAssetRoot/metadata/assets.json');
      final rawAssets = jsonDecode(assetsFile.readAsStringSync()) as Map<String, dynamic>;
      final assets = rawAssets['assets'] as List<dynamic>;

      final missingImages = <String>[];
      for (final a in assets) {
        final relPath = a['asset']['path'].toString();
        final file = File('$canonicalAssetRoot/$relPath');
        if (!file.existsSync()) {
          missingImages.add(relPath);
        }
      }
      expect(missingImages, isEmpty, reason: 'Every referenced visual image asset must exist');
    });

    test('All 165 label image crops referenced by assets.json exist on disk', () {
      final assetsFile = File('$canonicalAssetRoot/metadata/assets.json');
      final rawAssets = jsonDecode(assetsFile.readAsStringSync()) as Map<String, dynamic>;
      final assets = rawAssets['assets'] as List<dynamic>;

      final missingLabels = <String>[];
      int withLabelCount = 0;
      for (final a in assets) {
        final santali = a['label']?['santali'];
        final lblRel = santali?['label_image'];
        if (lblRel != null && lblRel.toString().isNotEmpty) {
          withLabelCount++;
          final file = File('$canonicalAssetRoot/$lblRel');
          if (!file.existsSync()) {
            missingLabels.add(lblRel.toString());
          }
        }
      }
      expect(withLabelCount, equals(165), reason: 'Exactly 165 vocabulary items have printed label crops');
      expect(missingLabels, isEmpty, reason: 'Every referenced printed label crop must exist on disk');
    });

    test('Edge cases: human body diagram has no label image crop, horse has no text layer', () {
      final assetsFile = File('$canonicalAssetRoot/metadata/assets.json');
      final rawAssets = jsonDecode(assetsFile.readAsStringSync()) as Map<String, dynamic>;
      final assets = (rawAssets['assets'] as List<dynamic>)
          .map((e) => CurriculumFlashcard.fromJson(e as Map<String, dynamic>))
          .toList();

      // Body diagram check
      final diagram = assets.firstWhere((c) => c.id == 'body_part_human_body_diagram_001');
      expect(diagram.santali.hasLabelImage, isFalse);
      expect(diagram.santali.labelImage, isNull);
      expect(diagram.santali.hasText, isFalse);
      expect(diagram.visualType, equals('labelled_diagram'));

      // Horse check (incomplete text layer)
      final horse = assets.firstWhere((c) => c.id == 'domestic_animal_horse_001');
      expect(horse.santali.hasText, isFalse);
      expect(horse.santali.hasLabelImage, isTrue);
      expect(horse.santali.textLayerIncomplete, isTrue);

      // Verify all 166 Santali labels are unverified
      for (final card in assets) {
        expect(card.santali.isVerified, isFalse, reason: 'Santali labels are pending verified review');
      }

      // Verify known source typo preservation (pigeon printed as BABOON)
      final pigeon = assets.firstWhere((c) => c.id == 'bird_pigeon_001');
      expect(pigeon.sourceDiscrepancy, isTrue);
      expect(pigeon.sourceLabel.english, equals('BABOON'));
      expect(pigeon.englishLabel, equals('pigeon'));
    });
  });

  group('Flutter rootBundle Asset Packaging Verification', () {
    test('rootBundle loads metadata and representative images and labels', () async {
      // Load assets.json via rootBundle
      final rawAssets = await rootBundle.loadString('assets/prototype_content/flashcards/metadata/assets.json');
      expect(rawAssets.isNotEmpty, isTrue);

      // Load taxonomy.json via rootBundle
      final rawTax = await rootBundle.loadString('assets/prototype_content/flashcards/config/taxonomy.json');
      expect(rawTax.isNotEmpty, isTrue);

      // Verify representative images from 3 different categories
      final cowImg = await rootBundle.load('assets/prototype_content/flashcards/images/animals/domestic/domestic_animal_cow_001.png');
      expect(cowImg.lengthInBytes, greaterThan(0));

      final redImg = await rootBundle.load('assets/prototype_content/flashcards/images/colours/colour_red_001.png');
      expect(redImg.lengthInBytes, greaterThan(0));

      final bodyImg = await rootBundle.load('assets/prototype_content/flashcards/images/body_parts/body_part_human_body_diagram_001.png');
      expect(bodyImg.lengthInBytes, greaterThan(0));

      // Verify representative labels from 3 different categories
      final cowLabel = await rootBundle.load('assets/prototype_content/flashcards/labels/animals/domestic/domestic_animal_cow_001_santali.png');
      expect(cowLabel.lengthInBytes, greaterThan(0));

      final horseLabel = await rootBundle.load('assets/prototype_content/flashcards/labels/animals/domestic/domestic_animal_horse_001_santali.png');
      expect(horseLabel.lengthInBytes, greaterThan(0));

      final whaleLabel = await rootBundle.load('assets/prototype_content/flashcards/labels/water_animals/water_animal_blue_whale_001_santali.png');
      expect(whaleLabel.lengthInBytes, greaterThan(0));
    });
  });

  group('FlashcardProgressStore & Semantics Tests', () {
    test('markSeen increments seen_count; recordAttempt sets correct mastery semantics', () async {
      final store = InMemoryFlashcardProgressStore();

      // Initially null
      expect(await store.getProgress('card_001'), isNull);

      // 1. Presentation of card increments seen count
      final seen1 = await store.recordSeen('card_001');
      expect(seen1.seenCount, equals(1));
      expect(seen1.correctCount, equals(0));
      expect(seen1.incorrectCount, equals(0));
      expect(seen1.isMastered, isFalse);

      // 2. Answer "Need Practice" (isCorrect: false)
      final incorrectAns = await store.recordAttempt(cardId: 'card_001', isCorrect: false);
      expect(incorrectAns.seenCount, equals(1));
      expect(incorrectAns.correctCount, equals(0));
      expect(incorrectAns.incorrectCount, equals(1));
      expect(incorrectAns.isMastered, isFalse);

      // 3. Next presentation
      await store.recordSeen('card_001');
      final seen2 = await store.getProgress('card_001');
      expect(seen2?.seenCount, equals(2));

      // 4. Answer "I Know" (isCorrect: true) -> immediately mastered
      final correctAns = await store.recordAttempt(cardId: 'card_001', isCorrect: true);
      expect(correctAns.seenCount, equals(2));
      expect(correctAns.correctCount, equals(1));
      expect(correctAns.incorrectCount, equals(1));
      expect(correctAns.isMastered, isTrue);

      // 5. Subsequent "Need Practice" removes mastered status
      final relapse = await store.recordAttempt(cardId: 'card_001', isCorrect: false);
      expect(relapse.isMastered, isFalse);
      expect(relapse.incorrectCount, equals(2));

      // 6. Reset deck progress deletes the progress record
      await store.resetDeckProgress(['card_001']);
      expect(await store.getProgress('card_001'), isNull);
    });
  });

  group('SantaliFlashcardBloc Lifecycle & Transition Tests', () {
    late FakeFlashcardRepository fakeRepo;
    late SantaliFlashcardBloc bloc;

    setUp(() {
      fakeRepo = FakeFlashcardRepository();
      bloc = SantaliFlashcardBloc(repository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is SantaliFlashcardInitial', () {
      expect(bloc.state, isA<SantaliFlashcardInitial>());
    });

    test('LoadSantaliDecksEvent loads categories, decks, and records presentation of first card', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SantaliFlashcardLoading>(),
          isA<SantaliFlashcardLoaded>().having((s) => s.decks.length, 'decks count', 2),
        ]),
      );

      final state = bloc.state as SantaliFlashcardLoaded;
      expect(state.activeDeck?.id, equals('deck_colours'));
      expect(state.currentIndex, equals(0));
      expect(state.isRevealed, isFalse);
    });

    test('FlipCardEvent toggles reveal state', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded);

      expect((bloc.state as SantaliFlashcardLoaded).isRevealed, isFalse);

      bloc.add(FlipCardEvent());
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.isRevealed);
      expect((bloc.state as SantaliFlashcardLoaded).isRevealed, isTrue);

      bloc.add(FlipCardEvent());
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && !s.isRevealed);
      expect((bloc.state as SantaliFlashcardLoaded).isRevealed, isFalse);
    });

    test('AnswerCardEvent is ignored when card is unrevealed', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded);

      // Card is NOT revealed yet
      expect((bloc.state as SantaliFlashcardLoaded).isRevealed, isFalse);
      bloc.add(const AnswerCardEvent(isCorrect: true));

      // Index and progress should NOT change
      final state = bloc.state as SantaliFlashcardLoaded;
      expect(state.currentIndex, equals(0));
      expect(state.progressMap['c1']?.correctCount ?? 0, equals(0));
    });

    test('AnswerCardEvent records progress and advances to next card when revealed', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded);

      // Reveal card
      bloc.add(FlipCardEvent());
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.isRevealed);

      // Answer "I Know"
      bloc.add(const AnswerCardEvent(isCorrect: true));
      final updatedState = await bloc.stream.firstWhere(
        (s) => s is SantaliFlashcardLoaded && s.currentIndex == 1,
      ) as SantaliFlashcardLoaded;

      expect(updatedState.currentIndex, equals(1));
      expect(updatedState.isRevealed, isFalse);
      expect(updatedState.progressMap['c1']?.isMastered, isTrue);
      expect(updatedState.progressMap['c1']?.correctCount, equals(1));
    });

    test('RestartDeckEvent resets navigation index to 0 without deleting SQLite progress', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded);

      // Advance to card 1 and record answer for c1
      bloc.add(FlipCardEvent());
      bloc.add(const AnswerCardEvent(isCorrect: true));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.currentIndex == 1);

      // Restart deck
      bloc.add(const RestartDeckEvent());
      final restarted = await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.currentIndex == 0) as SantaliFlashcardLoaded;

      expect(restarted.currentIndex, equals(0));
      expect(restarted.isRevealed, isFalse);
      // Saved progress for c1 is PRESERVED!
      expect(restarted.progressMap['c1']?.isMastered, isTrue);
    });

    test('ResetDeckProgressEvent clears persistent learning progress', () async {
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded);

      // Record answer for c1
      bloc.add(FlipCardEvent());
      bloc.add(const AnswerCardEvent(isCorrect: true));
      await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.currentIndex == 1);

      // Clear deck progress
      bloc.add(const ResetDeckProgressEvent('deck_colours'));
      final resetState = await bloc.stream.firstWhere((s) => s is SantaliFlashcardLoaded && s.currentIndex == 0) as SantaliFlashcardLoaded;

      expect(resetState.currentIndex, equals(0));
      expect(resetState.progressMap['c1'], isNull);
    });
  });

  group('SantaliCardWidget Visual & Hierarchy Tests', () {
    testWidgets('Answer shows English, Hindi and Santhali without provenance metadata', (tester) async {
      final card = CurriculumFlashcard(
        id: 'test_cow_001',
        category: 'animals',
        concept: 'cow',
        educationalDomain: 'animals',
        visualType: 'photograph',
        englishLabel: 'cow',
        santali: const SantaliLabelInfo(
          value: 'ᱜᱟᱹᱭ',
          labelImage: 'labels/animals/domestic/domestic_animal_cow_001_santali.png',
          isVerified: false,
        ),
        sourceLabel: const SourceLabelInfo(english: 'COW', hindi: 'गाय'),
        caption: 'A photo of a cow',
        keywords: const ['cow'],
        relativeImagePath: 'images/animals/domestic/domestic_animal_cow_001.png',
        imageWidth: 512,
        imageHeight: 512,
        source: const SourceProvenance(
          document: 'Aao Santali Likhna Sikhe.pdf',
          page: 6,
          section: 'DOMESTIC ANIMAL',
        ),
      );

      bool flipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SantaliCardWidget(
              card: card,
              assetRoot: canonicalAssetRoot,
              isRevealed: false,
              onFlip: () => flipped = true,
            ),
          ),
        ),
      );

      // Front Face
      expect(find.text('ANIMALS'), findsOneWidget);
      expect(find.text('Tap to reveal answer'), findsOneWidget);

      await tester.tap(find.byType(SantaliCardWidget));
      expect(flipped, isTrue);

      // Back Face (Revealed)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SantaliCardWidget(
              card: card,
              assetRoot: canonicalAssetRoot,
              isRevealed: true,
              onFlip: () {},
            ),
          ),
        ),
      );

      // Learner-facing answer: English, Hindi, Santhali (Ol Chiki text).
      expect(find.text('ANSWER'), findsOneWidget);
      expect(find.text('COW'), findsOneWidget);
      expect(find.text('गाय'), findsOneWidget);
      expect(find.text('SANTHALI'), findsOneWidget);
      expect(find.text('ᱜᱟᱹᱭ'), findsOneWidget);
      // No provenance / verification metadata shown to learners.
      expect(find.textContaining('GROUND TRUTH'), findsNothing);
      expect(find.text('DIGITAL TEXT'), findsNothing);
      expect(find.text('Pending Verification'), findsNothing);
      expect(find.text('Page 6'), findsNothing);
    });

    testWidgets('Gracefully handles missing label crop on body diagram without crashing', (tester) async {
      final diagramCard = CurriculumFlashcard(
        id: 'body_part_human_body_diagram_001',
        category: 'body_parts',
        concept: 'human_body_diagram',
        educationalDomain: 'body_parts',
        visualType: 'labelled_diagram',
        englishLabel: 'human body diagram',
        santali: const SantaliLabelInfo(
          value: null,
          labelImage: null,
          isVerified: false,
        ),
        sourceLabel: const SourceLabelInfo(english: 'PARTS OF BODY', hindi: 'अंगों के नाम'),
        caption: 'A labelled diagram',
        keywords: const ['diagram'],
        relativeImagePath: 'images/body_parts/body_part_human_body_diagram_001.png',
        imageWidth: 512,
        imageHeight: 512,
        source: const SourceProvenance(
          document: 'Aao Santali Likhna Sikhe.pdf',
          page: 17,
          section: 'PARTS OF BODY',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SantaliCardWidget(
              card: diagramCard,
              assetRoot: canonicalAssetRoot,
              isRevealed: true,
              onFlip: () {},
            ),
          ),
        ),
      );

      // No Santhali text or label: the Santhali row is simply omitted.
      expect(find.text('SANTHALI'), findsNothing);
      expect(find.text('HUMAN BODY DIAGRAM'), findsOneWidget);
      expect(find.text('अंगों के नाम'), findsOneWidget);
    });

    testWidgets('Gracefully handles missing Santali text on horse card', (tester) async {
      final horseCard = CurriculumFlashcard(
        id: 'domestic_animal_horse_001',
        category: 'animals',
        concept: 'horse',
        educationalDomain: 'animals',
        visualType: 'photograph',
        englishLabel: 'horse',
        santali: const SantaliLabelInfo(
          value: null,
          labelImage: 'labels/animals/domestic/domestic_animal_horse_001_santali.png',
          textLayerIncomplete: true,
          isVerified: false,
        ),
        sourceLabel: const SourceLabelInfo(english: 'HORSE', hindi: 'घोड़ा'),
        caption: 'A horse',
        keywords: const ['horse'],
        relativeImagePath: 'images/animals/domestic/domestic_animal_horse_001.png',
        imageWidth: 512,
        imageHeight: 512,
        source: const SourceProvenance(
          document: 'Aao Santali Likhna Sikhe.pdf',
          page: 6,
          section: 'DOMESTIC ANIMAL',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SantaliCardWidget(
              card: horseCard,
              assetRoot: canonicalAssetRoot,
              isRevealed: true,
              onFlip: () {},
            ),
          ),
        ),
      );

      // No Santhali text: the word as printed in the book is shown instead,
      // under the plain SANTHALI label (no verification wording).
      expect(find.text('SANTHALI'), findsOneWidget);
      expect(find.textContaining('GROUND TRUTH'), findsNothing);
      expect(find.text('HORSE'), findsOneWidget);
      expect(find.text('घोड़ा'), findsOneWidget);
    });
  });

  group('SantaliFlashcardLocalDataSource & Repository Integration', () {
    test('Loads 166 cards and 13 decks via FileAssetBundle', () async {
      final fakeBundle = FileAssetBundle();
      final dataSource = SantaliFlashcardLocalDataSource(bundle: fakeBundle);
      final store = InMemoryFlashcardProgressStore();
      final repo = SantaliFlashcardRepositoryImpl(
        localDataSource: dataSource,
        progressStore: store,
      );

      final cards = await repo.getAllCards();
      expect(cards.length, equals(166));

      final decks = await repo.getDecks();
      expect(decks.length, equals(13));

      final coloursDeck = await repo.getDeckById('01_colours');
      expect(coloursDeck, isNotNull);
      expect(coloursDeck!.cardCount, equals(6));

      final categories = await repo.getCategories();
      expect(categories.length, equals(12));

      // Test progress persistence
      await repo.recordCardSeen('colour_red_001');
      await repo.recordCardResult(cardId: 'colour_red_001', isCorrect: true);
      final p = await repo.getProgress('colour_red_001');
      expect(p?.isMastered, isTrue);
      expect(p?.seenCount, equals(1));
      expect(p?.correctCount, equals(1));
    });
  });

  group('SantaliFlashcardPlayerScreen layout (regression)', () {
    // The player hosts SantaliCardWidget inside a scroll view; an Expanded
    // on the card front got unbounded height, so the card never laid out
    // (blank player + mouse_tracker assertion flood on web/desktop).
    testWidgets('player lays out and flips a card without exceptions',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final bloc = SantaliFlashcardBloc(repository: FakeFlashcardRepository());
      addTearDown(bloc.close);
      bloc.add(const LoadSantaliDecksEvent(initialDeckId: 'deck_colours'));
      await tester.pump();
      final loaded = bloc.state;
      expect(loaded, isA<SantaliFlashcardLoaded>());
      expect((loaded as SantaliFlashcardLoaded).activeDeck!.id, 'deck_colours');

      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const SantaliFlashcardPlayerScreen(initialDeckId: 'deck_colours'),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SantaliCardWidget), findsOneWidget);
      expect(find.text('Tap to reveal answer'), findsOneWidget);

      await tester.tap(find.byType(SantaliCardWidget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('ANSWER'), findsOneWidget);
      expect(find.text('SANTHALI'), findsOneWidget);
      expect(find.textContaining('GROUND TRUTH'), findsNothing);
    });
  });

  group('FlashcardImageLibrary (image-first generation)', () {
    late FlashcardImageLibrary library;

    setUp(() {
      final bundle = FileAssetBundle();
      library = FlashcardImageLibrary(
        repository: SantaliFlashcardRepositoryImpl(
          localDataSource: SantaliFlashcardLocalDataSource(bundle: bundle),
          progressStore: InMemoryFlashcardProgressStore(),
        ),
        bundle: bundle,
      );
    });

    test('lists library topics including parent + subcategory topics', () async {
      final topics = await library.topics();
      final keys = topics.map((t) => t.key).toSet();
      expect(keys, containsAll(['fruits', 'birds', 'colours', 'animals', 'wild_animals']));
      final animals = topics.firstWhere((t) => t.key == 'animals');
      final wild = topics.firstWhere((t) => t.key == 'wild_animals');
      expect(animals.cardCount, greaterThan(wild.cardCount));
    });

    test('resolves English, Hindi and id topics; uncovered topics return null', () async {
      expect((await library.findTopic('Fruits'))?.key, 'fruits');
      expect((await library.findTopic('फल'))?.key, 'fruits');
      expect((await library.findTopic('Wild animals'))?.key, 'wild_animals');
      expect((await library.findTopic('Animals'))?.key, 'animals');
      expect((await library.findTopic('', topicId: '06_fruits'))?.key, 'fruits');
      expect(await library.findTopic('Addition'), isNull);
      expect(await library.findTopic('Shapes'), isNull);
    });

    test('builds an image payload from printed labels, capped to available pictures', () async {
      final colours = (await library.findTopic('Colours'))!;
      final payload = library.buildPayload(
        topic: colours,
        grade: 1,
        section: 'A',
        subject: 'Hindi',
        topicLabel: colours.label,
        languageMode: 'hi_en_sat',
        flashcardType: 'vocabulary',
        cardCount: 20,
        difficulty: 'MEDIUM',
        visualStyle: 'illustrated',
        pronunciation: false,
      );
      expect(isImageCatalogPayload(payload), isTrue);
      final cards = (payload['cards'] as List).cast<Map<String, dynamic>>();
      expect(cards, isNotEmpty);
      expect(cards.length, lessThan(20));
      expect(payload['card_count'], cards.length);
      for (final c in cards) {
        expect(c['hindi'], isNotEmpty);
        expect(c['english'], isNotEmpty);
        expect(c['santali'], isNotEmpty);
        final visual = c['visual'] as Map<String, dynamic>;
        expect(visual['kind'], 'image');
        expect(File(visual['image'] as String).existsSync(), isTrue);
      }
    });

    test('en_sat omits Hindi and keeps pictures without a Hindi label', () async {
      final topic = (await library.findTopic('Body parts'))!;
      final hi = library.usableCards(topic, 'hi_sat').length;
      final en = library.usableCards(topic, 'en_sat').length;
      expect(en, greaterThanOrEqualTo(hi));
      final payload = library.buildPayload(
        topic: topic,
        grade: 1,
        section: 'A',
        subject: 'Hindi',
        topicLabel: topic.label,
        languageMode: 'en_sat',
        flashcardType: 'vocabulary',
        cardCount: 5,
        difficulty: 'MEDIUM',
        visualStyle: 'illustrated',
        pronunciation: false,
      );
      for (final c in (payload['cards'] as List).cast<Map<String, dynamic>>()) {
        expect(c['hindi'], isNull);
      }
    });

    test('renders a real PDF with pictures fully offline', () async {
      final topic = (await library.findTopic('Fruits'))!;
      final payload = library.buildPayload(
        topic: topic,
        grade: 1,
        section: 'A',
        subject: 'Hindi',
        topicLabel: topic.label,
        languageMode: 'hi_sat',
        flashcardType: 'vocabulary',
        cardCount: 2,
        difficulty: 'MEDIUM',
        visualStyle: 'illustrated',
        pronunciation: false,
      );
      final bytes =
          await renderImageLibraryFlashcardPdf(payload, bundle: FileAssetBundle());
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(20000), reason: 'pictures are embedded');
    });
  });
}

class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = File(key);
    if (!file.existsSync()) {
      throw FlutterError('Asset file not found: $key');
    }
    return file.readAsString();
  }

  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

class FakeFlashcardRepository implements SantaliFlashcardRepository {
  final Map<String, FlashcardLearningProgress> _progress = {};

  final List<CurriculumFlashcard> _cards = [
    const CurriculumFlashcard(
      id: 'c1',
      category: 'colours',
      concept: 'red',
      educationalDomain: 'colours',
      visualType: 'colour_swatch',
      englishLabel: 'red',
      santali: SantaliLabelInfo(value: 'ᱟᱨᱟᱜ'),
      sourceLabel: SourceLabelInfo(english: 'RED', hindi: 'लाल'),
      caption: 'Red colour',
      keywords: ['red'],
      relativeImagePath: 'images/colours/colour_red_001.png',
      imageWidth: 512,
      imageHeight: 512,
      source: SourceProvenance(document: 'doc.pdf', page: 18, section: 'COLOURS'),
    ),
    const CurriculumFlashcard(
      id: 'c2',
      category: 'colours',
      concept: 'blue',
      educationalDomain: 'colours',
      visualType: 'colour_swatch',
      englishLabel: 'blue',
      santali: SantaliLabelInfo(value: 'ᱞᱤᱞ'),
      sourceLabel: SourceLabelInfo(english: 'BULE', hindi: 'नीला'),
      caption: 'Blue colour',
      keywords: ['blue'],
      relativeImagePath: 'images/colours/colour_blue_001.png',
      imageWidth: 512,
      imageHeight: 512,
      source: SourceProvenance(document: 'doc.pdf', page: 18, section: 'COLOURS'),
      sourceDiscrepancy: true,
    ),
  ];

  @override
  String get assetRoot => 'assets/prototype_content/flashcards';

  @override
  Future<List<CurriculumFlashcard>> getAllCards() async => _cards;

  @override
  Future<Map<String, FlashcardLearningProgress>> getAllProgress() async => _progress;

  @override
  Future<CurriculumFlashcard?> getCardById(String cardId) async =>
      _cards.firstWhere((c) => c.id == cardId);

  @override
  Future<List<FlashcardCategoryMetadata>> getCategories() async => [
        FlashcardCategoryMetadata(
          key: 'colours',
          label: 'Colours',
          decks: await getDecks(),
        ),
      ];

  @override
  Future<FlashcardDeck?> getDeckById(String deckId) async {
    final decks = await getDecks();
    return decks.firstWhere((d) => d.id == deckId);
  }

  @override
  Future<List<FlashcardDeck>> getDecks() async => [
        FlashcardDeck(
          id: 'deck_colours',
          title: 'Colours',
          categoryKey: 'colours',
          folder: 'colours',
          cards: _cards,
        ),
        FlashcardDeck(
          id: 'deck_animals',
          title: 'Animals',
          categoryKey: 'animals',
          folder: 'animals',
          cards: const [],
        ),
      ];

  @override
  Future<FlashcardLearningProgress?> getProgress(String cardId) async =>
      _progress[cardId];

  @override
  Future<FlashcardLearningProgress> recordCardSeen(String cardId) async {
    final existing = _progress[cardId] ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );
    final updated = existing.markSeen();
    _progress[cardId] = updated;
    return updated;
  }

  @override
  Future<FlashcardLearningProgress> recordCardResult({
    required String cardId,
    required bool isCorrect,
  }) async {
    final existing = _progress[cardId] ??
        FlashcardLearningProgress(
          cardId: cardId,
          lastReviewedAt: DateTime.now(),
        );
    final updated = existing.recordAttempt(isCorrect: isCorrect);
    _progress[cardId] = updated;
    return updated;
  }

  @override
  Future<void> resetDeckProgress(String deckId) async {
    _progress.clear();
  }
}
