import '../domain/repositories/auth_repository.dart';

/// Single central source for the authenticated Supabase user identity.
///
/// Canonical chain: `supabase.auth.currentSession.user.id` -> [currentUserId]
/// -> all teacher-owned records. Never derive identity from username, email,
/// teacher name, school name, or hardcoded dev IDs at the data layer.
class CurrentUserService {
  final AuthRepository _authRepository;

  CurrentUserService(this._authRepository);

  /// Authenticated Supabase user UUID, or null when signed out.
  /// Empty/blank IDs are treated as unauthenticated so repositories can
  /// never silently return another teacher's data.
  String? get currentUserId {
    final id = _authRepository.currentUserId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool get isAuthenticated =>
      currentUserId != null && _authRepository.isAuthenticated;

  Stream<bool> get authStateChanges => _authRepository.authStateChanges;
}
