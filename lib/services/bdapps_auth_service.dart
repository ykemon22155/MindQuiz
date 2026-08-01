// services/bdapps_auth_service.dart
//
// Dart port of auth.ts. Uses SharedPreferences in place of localStorage.
// Depends on bdapps_api.dart (the Dart port of api.ts).
//
// Also owns a small in-memory cache of the current phone number so
// callers that need synchronous access (e.g. DatabaseService's field
// initializer) don't have to await SharedPreferences every time.
// Call restoreSessionIfPossible() once at app startup, before anything
// reads currentPhone.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'bdapps_api.dart';

class AuthUser {
  final String phone;
  AuthUser(this.phone);

  Map<String, dynamic> toJson() => {'phone': phone};

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      AuthUser(json['phone'] as String? ?? '');
}

class AuthSession {
  final AuthUser user;
  final int createdAt;

  AuthSession(this.user, this.createdAt);

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'createdAt': createdAt,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    (json['createdAt'] as num?)?.toInt() ?? 0,
  );
}

/// Thrown by [BdAppsAuthService.loginWithPhone] for numbers not yet
/// registered on BDApps. Carries the referenceNo the caller needs to
/// show the OTP-entry step (equivalent to the "UNREGISTERED_USER"
/// error + err.referenceNo pattern in auth.ts).
class UnregisteredUserException implements Exception {
  final String referenceNo;
  UnregisteredUserException(this.referenceNo);
  @override
  String toString() => 'UNREGISTERED_USER';
}

class BdAppsAuthService {
  static const String _storageKey = 'NewsQuickyai_session';

  // Singleton so the in-memory cache below is shared across the whole app.
  static final BdAppsAuthService _instance = BdAppsAuthService._internal();
  factory BdAppsAuthService({BdAppsApi? api}) {
    if (api != null) _instance._api = api;
    return _instance;
  }
  BdAppsAuthService._internal() : _api = BdAppsApi();

  BdAppsApi _api;

  String? _cachedPhone;

  /// Synchronous access to the logged-in user's phone number. Null until
  /// [restoreSessionIfPossible] has been awaited at least once, or before
  /// any successful login/logout in this app run.
  String? get currentPhone => _cachedPhone;

  bool get isLoggedIn => _cachedPhone != null && _cachedPhone!.isNotEmpty;

  /// Loads the stored session (if any) from disk into memory. Call this
  /// once at app startup, before runApp(), so currentPhone is usable
  /// synchronously everywhere else afterward.
  Future<String?> restoreSessionIfPossible() async {
    final session = await getStoredAuthSession();
    _cachedPhone = session?.user.phone;
    return _cachedPhone;
  }

  Future<AuthSession?> getStoredAuthSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return null;

      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromJson(parsed);
      if (session.user.phone.isEmpty) return null;
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<AuthSession> _setStoredAuthSession(String phone) async {
    final session = AuthSession(
      AuthUser(phone),
      DateTime.now().millisecondsSinceEpoch,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(session.toJson()));
    _cachedPhone = phone;
    return session;
  }

  Future<void> clearStoredAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cachedPhone = null;
  }

  /// Starts login for a phone number.
  /// - Already-registered BDApps subscribers (E1351) are logged in immediately.
  /// - New numbers throw [UnregisteredUserException] carrying a referenceNo,
  ///   which the caller uses to show the OTP step.
  Future<AuthSession> loginWithPhone(String phone) async {
    final res = await _api.requestOtp(phone);

    if (!res.success) {
      if (res.statusCode == 'E1351') {
        // Already registered on BDApps — treat as an existing subscriber login.
        return _setStoredAuthSession(phone);
      }
      throw BdAppsApiException(res.message ?? 'লগইন করা যায়নি, আবার চেষ্টা করুন');
    }

    if (res.referenceNo != null) {
      throw UnregisteredUserException(res.referenceNo!);
    }

    throw BdAppsApiException('লগইন করা যায়নি, আবার চেষ্টা করুন');
  }

  Future<AuthSession> verifyOtpAndLogin(
      String phone,
      String otp,
      String referenceNo,
      ) async {
    await _api.verifyOtp(referenceNo, otp);
    return _setStoredAuthSession(phone);
  }
}