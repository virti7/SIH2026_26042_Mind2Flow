import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/content/prototype_local_content_data_source.dart';
import 'package:maatribhasha/core/content/prototype_manifests.dart';
import 'package:maatribhasha/core/widgets/responsive_form_row.dart';

void main() {
  group('Prototype manifest format', () {
    test('worksheet manifest parses expected demo shape', () {
      final m = PrototypeWorksheetManifest.fromJson({
        'id': 'class2_math_numbers',
        'title': 'Numbers up to 100',
        'className': 'Class 2',
        'subject': 'Mathematics',
        'topic': 'Numbers up to 100',
        'languages': ['Hindi', 'Santali'],
        'type': 'bilingual_worksheet',
        'asset':
            'assets/prototype_content/worksheets/pdf/class2_math_numbers.pdf',
      });
      expect(m.isValid, isTrue);
      expect(m.id, 'class2_math_numbers');
      expect(m.asset.endsWith('.pdf'), isTrue);
    });

    test('flashcard + assessment manifests parse', () {
      final f = PrototypeFlashcardSetManifest.fromJson({
        'setId': 'class2_santali_animals',
        'title': 'Animals',
        'className': 'Class 2',
        'subject': 'Hindi',
        'topic': 'Animals',
        'languagePair': ['Hindi', 'Santali'],
        'cardCount': 12,
        'coverImage': 'assets/prototype_content/flashcards/images/cover.png',
        'setFile':
            'assets/prototype_content/flashcards/sets/class2_santali_animals.json',
      });
      expect(f.isValid, isTrue);

      final a = PrototypeAssessmentManifest.fromJson({
        'assessmentId': 'class2_math_numbers_check',
        'className': 'Class 2',
        'subject': 'Mathematics',
        'topic': 'Numbers up to 100',
        'language': 'Hindi + Santali',
        'questions': [
          {
            'number': 1,
            'promptHindi': 'q',
            'promptTribal': 'q',
            'type': 'mcq',
            'options': ['a', 'b'],
            'correctIndex': 0,
          },
        ],
      });
      expect(a.isValid, isTrue);
      expect(a.questions, hasLength(1));
    });
  });

  group('PrototypeLocalContentDataSource (offline)', () {
    test('empty bundle returns empty catalogs, never throws', () async {
      final ds = PrototypeLocalContentDataSource(
          bundle: _EmptyAssetBundle());
      expect(await ds.getPrototypeWorksheets(), isEmpty);
      expect(await ds.getPrototypeFlashcardSets(), isEmpty);
      expect(await ds.getPrototypeAssessments(), isEmpty);
      expect(
          await ds.findWorksheetManifest(
            className: 'Class 2',
            subject: 'Mathematics',
            topic: 'Numbers up to 100',
          ),
          isNull);
    });

    test('manifest converts to existing WorksheetItem model', () {
      final ds = PrototypeLocalContentDataSource(
          bundle: _EmptyAssetBundle());
      const manifest = PrototypeWorksheetManifest(
        id: 'class2_math_numbers',
        title: 'Numbers up to 100',
        className: 'Class 2',
        subject: 'Mathematics',
        topic: 'Numbers up to 100',
        languages: ['Hindi', 'Santali'],
        type: 'bilingual_worksheet',
        asset: 'assets/prototype_content/worksheets/pdf/x.pdf',
      );
      final item = ds.worksheetItemFromManifest(manifest);
      expect(item.id, 'class2_math_numbers');
      expect(item.grade, 2);
      expect(item.subject, 'Mathematics');
      final payload = ds.downloadPayloadForWorksheet(manifest);
      expect(payload['content_id'], 'class2_math_numbers');
      expect(payload['prototype'], isTrue);
    });
  });

  group('Responsive overflow guards', () {
    testWidgets('ResponsiveFormRow stacks on narrow, rows on wide',
        (tester) async {
      Widget build(double width) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: const ResponsiveFormRow(
                  first: Text('Language 1'),
                  second: Text('Language 2'),
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(360));
      expect(find.byType(Column), findsWidgets);

      await tester.pumpWidget(build(800));
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('ResponsiveBottomActions stacks on narrow',
        (tester) async {
      Widget build(double width) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: ResponsiveBottomActions(
                  secondary: ElevatedButton(
                      onPressed: () {}, child: const Text('Previous')),
                  primary: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Bilingual Worksheet')),
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(360));
      // Stacked vertically on narrow: both buttons visible, no overflow.
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Bilingual Worksheet'), findsOneWidget);
      tester.takeException();
    });
  });
}

/// AssetBundle that reports no prototype manifests (simulates a fresh
/// install before the teacher adds files). Never hits the network.
class _EmptyAssetBundle extends AssetBundle {
  _EmptyAssetBundle();

  @override
  Future<ByteData> load(String key) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(FlutterError('not found: $key'));

  @override
  Future<T> loadStructuredData<T>(
      String key, Future<T> Function(String value) parser) =>
      Future.error(FlutterError('not found: $key'));

  @override
  void evict(String key) {}
}
