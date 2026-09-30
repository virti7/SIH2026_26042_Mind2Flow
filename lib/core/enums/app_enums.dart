/// Core Enums for Maatribhasha NIPUN FLN System
library;

enum OutcomeStatus {
  achieved('Achieved', 'प्राप्त किया'),
  developing('Developing', 'प्रगति पर'),
  needsSupport('Needs Support', 'सहयोग आवश्यक');

  final String label;
  final String labelHindi;
  const OutcomeStatus(this.label, this.labelHindi);
}

enum TribalLanguage {
  ho('Ho', 'हो', 'Warang Chiti / Devanagari'),
  mundari('Mundari', 'मुण्डारी', 'Mundari Bani / Devanagari'),
  santali('Santali', 'संथाली', 'Ol Chiki / Devanagari'),
  all('All Tribal Languages', 'सभी जनजातीय भाषाएं', 'Multilingual Router');

  final String displayName;
  final String hindiName;
  final String script;
  const TribalLanguage(this.displayName, this.hindiName, this.script);
}

enum DeliveryStage {
  explain(1, 'Explain', 'समझाएं', 'Introduce concept orally in Hindi with tribal vocabulary support'),
  demonstrate(2, 'Demonstrate', 'करके दिखाएं', 'Show real visual or concrete manipulatives'),
  ask(3, 'Ask', 'पूछें', 'Classroom check question to test intuitive grasp'),
  activity(4, 'Activity', 'गतिविधि', 'Student hands-on or group interaction'),
  practice(5, 'Practice', 'अभ्यास', 'Individual / paired bilingual task practice'),
  check(6, 'Check', 'जांचें', 'Quick formative observation check');

  final int stepNumber;
  final String title;
  final String titleHindi;
  final String description;
  const DeliveryStage(this.stepNumber, this.title, this.titleHindi, this.description);
}

enum LiteracyStrand {
  oralLanguage('Oral Language', 'मौखिक भाषा विकास', 'Listening, speaking, vocabulary, picture talk, stories'),
  decoding('Decoding', 'डिकोडिंग', 'Sound-symbol cards, phonics, blending, word reading'),
  readingComprehension('Reading & Comprehension', 'पढ़ना और समझना', 'Bilingual stories, read-aloud, contextual questions'),
  writingExpression('Writing & Expression', 'लिखना और अभिव्यक्ति', 'Tracing, letter formation, picture-to-sentence');

  final String titleEn;
  final String titleHi;
  final String description;
  const LiteracyStrand(this.titleEn, this.titleHi, this.description);
}

enum NumeracyStage {
  oralMathTalk('Oral Math Talk', 'मौखिक गणित वार्ता', 'Describe quantity, compare, estimate, explain strategies'),
  skillsTeaching('Skills Teaching', 'कौशल शिक्षण', 'Explicit modeling of counting, operations, shapes'),
  skillsPractice('Skills Practice', 'कौशल अभ्यास', 'Guided bilingual exercises, sorting, counting'),
  mathGames('Math Games', 'गणित खेल', 'Play-based matching, patterns, movement games');

  final String titleEn;
  final String titleHi;
  final String description;
  const NumeracyStage(this.titleEn, this.titleHi, this.description);
}

enum QuestionType {
  oral('Oral Response', 'मौखिक उत्तर'),
  physical('Physical Interaction', 'वस्तु द्वारा प्रदर्शन'),
  written('Written Numeral/Word', 'लिखित उत्तर'),
  matching('Matching', 'सुमेलित करें'),
  counting('Counting', 'गिनती करें');

  final String label;
  final String labelHindi;
  const QuestionType(this.label, this.labelHindi);
}

enum DifficultyLevel {
  easy('Easy', 'सरल'),
  medium('Medium', 'मध्यम'),
  challenging('Challenging', 'चुनौतीपूर्ण');

  final String label;
  final String labelHindi;
  const DifficultyLevel(this.label, this.labelHindi);
}

enum WorksheetType {
  practice('Practice Worksheet', 'अभ्यास पत्रक'),
  matching('Matching Activity', 'मिलान गतिविधि'),
  fillInTheBlanks('Fill in the Blanks', 'रिक्त स्थान भरो'),
  multipleChoice('Multiple Choice', 'बहुविकल्पीय'),
  counting('Counting Objects', 'गिनती आधारित'),
  writing('Writing & Tracing', 'लेखन व अनुरेखण'),
  reading('Bilingual Story Reading', 'द्विभाषी पठन');

  final String title;
  final String titleHindi;
  const WorksheetType(this.title, this.titleHindi);
}

enum PackStatus {
  installed('Installed', 'स्थापित'),
  available('Available', 'उपलब्ध'),
  downloading('Downloading...', 'डाउनलोड हो रहा है...'),
  updateAvailable('Update Available', 'अपडेट उपलब्ध');

  final String label;
  final String labelHindi;
  const PackStatus(this.label, this.labelHindi);
}

enum SyncStatusState {
  synced('All Synced', 'सिंक पूर्ण'),
  syncing('Syncing...', 'सिंक हो रहा है...'),
  pendingUpload('Pending Upload', 'अपलोड प्रतीक्षारत'),
  offline('Offline Ready', 'ऑफ़लाइन सक्रिय');

  final String label;
  final String labelHindi;
  const SyncStatusState(this.label, this.labelHindi);
}
