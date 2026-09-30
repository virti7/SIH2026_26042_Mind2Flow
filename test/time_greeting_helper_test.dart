import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/core/enums/app_enums.dart';
import 'package:maatribhasha/core/models/app_models.dart';
import 'package:maatribhasha/core/utils/time_greeting_helper.dart';

/// Time-based Home greeting boundaries (device local time) + proof that the
/// actual teacher profile name flows into the greeting (no hardcoded name).
void main() {
  DateTime at(int hour, int minute) => DateTime(2026, 1, 1, hour, minute);

  // Fixture names only — the helper itself never hardcodes a name.
  const fixtureName = 'Test Teacher';

  group('TimeGreetingHelper boundaries', () {
    test('05:00 -> Good morning', () {
      expect(TimeGreetingHelper.getGreeting(at(5, 0), fixtureName),
          'Good morning, $fixtureName');
    });
    test('11:59 -> Good morning', () {
      expect(TimeGreetingHelper.getGreeting(at(11, 59), fixtureName),
          'Good morning, $fixtureName');
    });
    test('12:00 -> Good afternoon', () {
      expect(TimeGreetingHelper.getGreeting(at(12, 0), fixtureName),
          'Good afternoon, $fixtureName');
    });
    test('16:59 -> Good afternoon', () {
      expect(TimeGreetingHelper.getGreeting(at(16, 59), fixtureName),
          'Good afternoon, $fixtureName');
    });
    test('17:00 -> Good evening', () {
      expect(TimeGreetingHelper.getGreeting(at(17, 0), fixtureName),
          'Good evening, $fixtureName');
    });
    test('20:59 -> Good evening', () {
      expect(TimeGreetingHelper.getGreeting(at(20, 59), fixtureName),
          'Good evening, $fixtureName');
    });
    test('21:00 -> Good night', () {
      expect(TimeGreetingHelper.getGreeting(at(21, 0), fixtureName),
          'Good night, $fixtureName');
    });
    test('23:59 -> Good night', () {
      expect(TimeGreetingHelper.getGreeting(at(23, 59), fixtureName),
          'Good night, $fixtureName');
    });
    test('00:30 -> Good night', () {
      expect(TimeGreetingHelper.getGreeting(at(0, 30), fixtureName),
          'Good night, $fixtureName');
    });
    test('04:59 -> Good night', () {
      expect(TimeGreetingHelper.getGreeting(at(4, 59), fixtureName),
          'Good night, $fixtureName');
    });
  });

  group('spec examples', () {
    test('08:30 / 14:10 / 18:30 / 22:15', () {
      expect(TimeGreetingHelper.getGreeting(at(8, 30), 'Ved'),
          'Good morning, Ved');
      expect(TimeGreetingHelper.getGreeting(at(14, 10), 'Ved'),
          'Good afternoon, Ved');
      expect(TimeGreetingHelper.getGreeting(at(18, 30), 'Ved'),
          'Good evening, Ved');
      expect(TimeGreetingHelper.getGreeting(at(22, 15), 'Ved'),
          'Good night, Ved');
    });
  });

  group('actual teacher profile name is used', () {
    TeacherProfile profileFixture(String name) => TeacherProfile(
          id: 'teacher_primary',
          name: name,
          school: 'GPS Bundu',
          district: 'Khunti',
          state: 'Jharkhand',
          classesTaught: const [1, 2, 3],
          teachingLanguage: 'Hindi',
          supportedClassroomLanguages: const [],
          activeSessionLanguage: TribalLanguage.mundari,
        );

    test('morning greeting embeds the profile name', () {
      final profile = profileFixture('Sunita Soren');
      expect(TimeGreetingHelper.getGreeting(at(8, 30), profile.name),
          'Good morning, Sunita Soren');
    });

    test('afternoon greeting embeds the profile name', () {
      final profile = profileFixture('Birsa Munda');
      expect(TimeGreetingHelper.getGreeting(at(14, 10), profile.name),
          'Good afternoon, Birsa Munda');
    });

    test('different profiles give different greetings (no hardcoded name)',
        () {
      final a = profileFixture('Sunita Soren');
      final b = profileFixture('Birsa Munda');
      final ga = TimeGreetingHelper.getGreeting(at(9, 0), a.name);
      final gb = TimeGreetingHelper.getGreeting(at(9, 0), b.name);
      expect(ga, isNot(equals(gb)));
      expect(ga, contains('Sunita Soren'));
      expect(gb, contains('Birsa Munda'));
    });

    test('blank profile name falls back to Teacher', () {
      expect(TimeGreetingHelper.getGreeting(at(9, 0), '   '),
          'Good morning, Teacher');
    });

    test('GreetingService alias behaves identically', () {
      expect(GreetingService.getGreeting(at(18, 30), 'Ved'),
          'Good evening, Ved');
    });
  });
}
