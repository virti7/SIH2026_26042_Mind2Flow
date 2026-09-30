/// Time-based teacher greeting for the Home screen header.
///
/// Uses the device's local time ([DateTime.now()], never UTC) and the
/// authenticated teacher name already held in local Drift/profile state,
/// so the greeting works fully offline with no FastAPI/Supabase call.
///
/// Boundaries (local time):
/// - 05:00–11:59 → Good morning
/// - 12:00–16:59 → Good afternoon
/// - 17:00–20:59 → Good evening
/// - 21:00–04:59 → Good night
class TimeGreetingHelper {
  const TimeGreetingHelper._();

  /// Returns only the greeting text, e.g. "Good morning, Ved".
  ///
  /// [now] must be local device time (pass `DateTime.now()`).
  /// An empty/blank [teacherName] falls back to "Teacher" so the header
  /// never renders a dangling comma.
  static String getGreeting(DateTime now, String teacherName) {
    final name = teacherName.trim().isEmpty ? 'Teacher' : teacherName.trim();
    final minutes = now.hour * 60 + now.minute;

    const morningStart = 5 * 60; // 05:00 inclusive
    const afternoonStart = 12 * 60; // 12:00 inclusive
    const eveningStart = 17 * 60; // 17:00 inclusive
    const nightStart = 21 * 60; // 21:00 inclusive

    if (minutes >= morningStart && minutes < afternoonStart) {
      return 'Good morning, $name';
    }
    if (minutes >= afternoonStart && minutes < eveningStart) {
      return 'Good afternoon, $name';
    }
    if (minutes >= eveningStart && minutes < nightStart) {
      return 'Good evening, $name';
    }
    return 'Good night, $name';
  }

  /// Convenience: greeting for "right now" on this device (local time).
  static String greetingNow(String teacherName) =>
      getGreeting(DateTime.now(), teacherName);
}

/// Backwards-compatible alias requested in the spec (`GreetingService`).
abstract class GreetingService {
  static String getGreeting(DateTime now, String teacherName) =>
      TimeGreetingHelper.getGreeting(now, teacherName);

  static String greetingNow(String teacherName) =>
      TimeGreetingHelper.greetingNow(teacherName);
}
