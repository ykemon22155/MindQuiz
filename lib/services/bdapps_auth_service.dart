
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

class UnregisteredUserException implements Exception {
  final String referenceNo;
  UnregisteredUserException(this.referenceNo);
  @override
  String toString() => 'UNREGISTERED_USER';
}

class BdAppsAuthService {
  static const String _storageKey = 'NewsQuickyai_session';

  static final BdAppsAuthService _instance = BdAppsAuthService._internal();
  factory BdAppsAuthService({BdAppsApi? api}) {
    if (api != null) _instance._api = api;
    return _instance;
  }
  BdAppsAuthService._internal() : _api = BdAppsApi();

  BdAppsApi _api;

  String? _cachedPhone;

  String? get currentPhone => _cachedPhone;

  bool get isLoggedIn => _cachedPhone != null && _cachedPhone!.isNotEmpty;

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
  Future<AuthSession> loginWithPhone(String phone) async {
    // ১. প্রথমে সরাসরি ওটিপি এপিআই (requestOtp) কল করে চেক করব সার্ভার কী রেসপন্স দেয়
    try {
      final res = await _api.requestOtp(phone);

      // যদি সার্ভার থেকে referenceNo দেয়, তার মানে ইউজার আনসাবস্ক্রাইবড বা নতুন — ওটিপি লাগবে
      if (res.referenceNo != null && res.referenceNo!.isNotEmpty) {
        throw UnregisteredUserException(res.referenceNo!);
      }

      // ২. যদি সার্ভার বলে যে ইউজার অলরেডি রেজিস্টার্ড (E1351),
      // তবে কোনো ওটিপি চাইবে না — সরাসরি সেশন সেভ করে হোম পেজে ঢুকিয়ে দেব।
      if (!res.success) {
        final message = (res.message ?? '').toLowerCase();
        final looksAlreadyRegistered =
            res.statusCode == 'E1351' || message.contains('already registered');

        if (looksAlreadyRegistered) {
          debugPrint('✅ [LOGIN] User is already registered. Bypassing OTP directly to home.');
          return _setStoredAuthSession(phone);
        }
        throw BdAppsApiException(res.message ?? 'লগইন করা যায়নি, আবার চেষ্টা করুন');
      }

      if (res.success && res.referenceNo == null) {
        return _setStoredAuthSession(phone);
      }
    } catch (e) {
      if (e is UnregisteredUserException) rethrow;
      if (e is BdAppsApiException) rethrow;

      // ৩. যদি নেটওয়ার্ক বা অন্য কোনো কারণে উপরে এক্সেপশন হয়, তখন সাবস্ক্রিপশন স্ট্যাটাস চেক করে ফ্যালব্যাক হ্যান্ডেল করব
      try {
        final subscriptionStatus = await _api.checkSubscriptionStatus(phone);
        debugPrint('🔍 [LOGIN] Fallback Subscription Status: $subscriptionStatus');

        if (subscriptionStatus.toUpperCase() == 'UNREGISTERED' ||
            subscriptionStatus.toUpperCase() == 'E1951') {
          final otpRes = await _api.requestOtp(phone);
          throw UnregisteredUserException(otpRes.referenceNo ?? '');
        } else {
          return _setStoredAuthSession(phone);
        }
      } catch (subError) {
        if (subError is UnregisteredUserException) rethrow;
        debugPrint('⚠️ [LOGIN] Fallback error: $subError');
      }

      throw BdAppsApiException('লগইন করা যায়নি, আবার চেষ্টা করুন');
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


