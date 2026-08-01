import 'bdapps_auth_service.dart';

/// Thin compatibility wrapper around [BdAppsAuthService], kept only so
/// existing code that calls `AuthService()` doesn't need to change.
///
/// It does NOT keep its own cache anymore — it just forwards to
/// BdAppsAuthService, which is the single source of truth for the
/// logged-in phone number. If nothing else in your project still
/// references `AuthService()`, you can delete this file entirely and
/// call `BdAppsAuthService()` directly everywhere instead.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final BdAppsAuthService _bdAuth = BdAppsAuthService();

  /// The phone number of the currently logged-in user, or null.
  String? get currentPhone => _bdAuth.currentPhone;

  bool get isLoggedIn => _bdAuth.isLoggedIn;

  /// Loads the stored session from disk into memory. Call once at app
  /// startup, before runApp(). Safe to call even if you're calling
  /// BdAppsAuthService().restoreSessionIfPossible() elsewhere too —
  /// they share the same underlying cache, so it won't double-load.
  Future<String?> restoreSessionIfPossible() =>
      _bdAuth.restoreSessionIfPossible();

  Future<void> signOut() => _bdAuth.clearStoredAuthSession();
}