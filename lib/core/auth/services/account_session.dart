import 'dart:async';

/// Broadcasts account switches so account-scoped BLoCs/caches can
/// clear stale state on logout and reload on login.
///
/// Values are authenticated Supabase user UUIDs; null means signed out.
/// Local SQLite rows are NEVER deleted on logout — they stay on device for
/// offline use but become inaccessible until their owner signs back in.
class AccountSession {
  static final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  static Stream<String?> get changes => _controller.stream;

  static void notifySignedIn(String? userId) {
    final id = (userId ?? '').trim();
    if (!_controller.isClosed) {
      _controller.add(id.isEmpty ? null : id);
    }
  }

  static void notifySignedOut() {
    if (!_controller.isClosed) _controller.add(null);
  }
}
