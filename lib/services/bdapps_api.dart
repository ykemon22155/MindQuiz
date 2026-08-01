// services/bdapps_api.dart
//
// Dart port of api.ts. Talks to the same PHP backend
// (appsbackend.lokhalapps.com/api/v1), which expects a JSON body with
// `appName` on every request (see app_auth.php / app_credentials.php).

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OtpRequestResult {
  final bool success;
  final String? message;
  final String? referenceNo;
  final String? statusCode;
  final String? statusDetail;

  OtpRequestResult({
    required this.success,
    this.message,
    this.referenceNo,
    this.statusCode,
    this.statusDetail,
  });
}

/// Thrown for any non-success response from the backend.
class BdAppsApiException implements Exception {
  final String message;
  BdAppsApiException(this.message);
  @override
  String toString() => message;
}

class BdAppsApi {
  static const String _baseUrl = 'https://bdappsdigitalapps.com/NADB26117';

  // Must exactly match a key in app_credentials.php on the backend.
  // Currently registered on the BDApps backend as 'MindQuiz'.
  static const String _appName = 'mindquiz';

  late final Dio _dio;

  BdAppsApi({Dio? dio})
      : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
        ),
      );

  /// Normalizes any reasonable input (with or without country code,
  /// spaces, dashes, +) down to the bare local-mobile format the
  /// backend expects: 01XXXXXXXXX (11 digits, leading 0).
  ///
  /// Used by both [toSubscriberId] and [requestOtp] — previously this
  /// logic was duplicated in two places and had drifted slightly out
  /// of sync with each other.
  String _normalizeToLocalMobile(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('8801') && digits.length == 13) {
      digits = '0${digits.substring(3)}';
    } else if (digits.startsWith('88') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (!digits.startsWith('0') && digits.length == 10) {
      digits = '0$digits';
    }
    return digits;
  }

  /// Converts a BD phone number into BDApps subscriberId format:
  /// tel:8801XXXXXXXXX
  ///
  /// Throws [BdAppsApiException] instead of crashing with a RangeError
  /// if the input can't be normalized into a valid 11-digit number.
  String toSubscriberId(String phone) {
    final digits = _normalizeToLocalMobile(phone);

    if (!RegExp(r'^0\d{10}$').hasMatch(digits)) {
      throw BdAppsApiException('Invalid phone number format: $phone');
    }

    final tenDigits = digits.substring(1);
    return 'tel:880$tenDigits';
  }

  /// Base POST helper — injects appName into every request automatically.
  Future<Map<String, dynamic>> _post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final res = await _dio.post(
        endpoint,
        data: {'appName': _appName, ...body},
      );
      final data = res.data;
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(data as Map);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw BdAppsApiException('HTTP error! status: ${status ?? 'unknown'}');
    }
  }

  /// Check subscription status (REGISTERED / UNREGISTERED)
  Future<String> checkSubscriptionStatus(String userMobile) async {
    final subscriberId = toSubscriberId(userMobile);
    debugPrint('📤 [CHECK SUBSCRIPTION] Checking for: $subscriberId');

    final data =
    await _post('/check_subscription.php', {'subscriberId': subscriberId});
    debugPrint('✅ [CHECK SUBSCRIPTION] Response: $data');

    if (data['statusCode'] == 'E1951') {
      debugPrint('ℹ️ [CHECK SUBSCRIPTION] E1951 → treating as UNREGISTERED');
      return 'UNREGISTERED';
    }

    if (data['statusCode'] != 'S1000') {
      debugPrint('❌ [CHECK SUBSCRIPTION] Failed: $data');
      throw BdAppsApiException(
        (data['statusDetail'] as String?) ?? 'Failed to check subscription status',
      );
    }

    return (data['subscriptionStatus'] as String?) ?? 'UNREGISTERED';
  }

  /// Request OTP
  Future<OtpRequestResult> requestOtp(String userMobile) async {
    final digits = _normalizeToLocalMobile(userMobile);

    debugPrint('📤 [REQUEST OTP] Sending to: $digits');
    final data = await _post('/send_otp.php', {'userMobile': digits});
    debugPrint('✅ [REQUEST OTP] Response: $data');

    final message = ((data['message'] as String?) ?? '').toLowerCase();
    if (data['statusCode'] == 'E1351' || message.contains('already registered')) {
      debugPrint('ℹ️ [REQUEST OTP] User already registered on BDApps');
      return OtpRequestResult(
        success: false,
        message: (data['message'] as String?) ?? 'user already registered',
        referenceNo: null,
        statusCode: (data['statusCode'] as String?) ?? 'E1351',
      );
    }

    if (data['success'] == true && data['referenceNo'] != null) {
      return OtpRequestResult(
        success: true,
        referenceNo: data['referenceNo'] as String,
        statusCode: data['statusCode'] as String?,
        statusDetail: data['statusDetail'] as String?,
      );
    }

    debugPrint('❌ [REQUEST OTP] Failed: $data');
    throw BdAppsApiException(
      (data['message'] as String?) ??
          (data['statusDetail'] as String?) ??
          'Failed to request OTP',
    );
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String referenceNo, String otp) async {
    // Never log the actual OTP value, even in debug builds.
    debugPrint('📤 [VERIFY OTP] ReferenceNo: $referenceNo | OTP: ${'*' * otp.length}');
    final data =
    await _post('/verify_otp.php', {'referenceNo': referenceNo, 'otp': otp});
    debugPrint('✅ [VERIFY OTP] Response: $data');

    if (data['statusCode'] != 'S1000') {
      throw BdAppsApiException(
        (data['statusDetail'] as String?) ??
            (data['message'] as String?) ??
            'Invalid OTP',
      );
    }
    return data;
  }

  /// Unsubscribe user
  Future<Map<String, dynamic>> unsubscribe(String userMobile) async {
    final subscriberId = toSubscriberId(userMobile);
    debugPrint('📤 [UNSUBSCRIBE] for: $subscriberId');
    final data =
    await _post('/unsubscribe.php', {'subscriberId': subscriberId});
    debugPrint('✅ [UNSUBSCRIBE] Response: $data');
    return data;
  }
}