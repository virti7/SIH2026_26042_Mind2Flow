class AppConstants {
  AppConstants._();

  static const String appName = 'Maatribhasha';
  static const String appHindiName = 'मातृभाषा';
  static const String appTagline = 'Mother-Tongue Teaching Assistant';
  static const String appPromise = 'One teacher. One tablet. Multiple mother tongues. One NIPUN-aligned classroom.';

  // Teacher identity is never prefilled: fields start empty and are loaded
  // dynamically from the local database once the teacher saves a profile.
  static const String defaultTeacherName = '';
  static const String defaultSchool = '';
  static const String defaultDistrict = '';
  static const String defaultState = 'Jharkhand';
  static const String defaultTeachingLanguage = 'Hindi';

  static const String problemStatementId = 'PS 26042';
  static const String nipunBharatPortal = 'https://nipunbharat.education.gov.in';
  static const String appVersion = 'v1.4.2 (Offline-First Edition)';
}
