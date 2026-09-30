import 'package:drift/drift.dart';

@DataClassName('AssessmentQuestionData')
class AssessmentQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get outcomeCode => text()();
  TextColumn get questionsJson => text()(); // JSON list of AssessmentQuestionItem

  @override
  Set<Column> get primaryKey => {id};
}
