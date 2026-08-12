import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Thin client for the BDApps subscription backend. The endpoints
/// used by the app are:
///
///   * `isSubscribed`  — checks whether [mobile] is currently
///                       REGISTERED.
///   * `sendOtp`       — sends the 6-digit OTP to [mobile] and
///                       returns the backend's `referenceNo`.
///
///   * `verifyOtp`     — submits [code] against [referenceNo] to
///                       complete the subscription flow.
///
/// The actual base URL is left as a constant so it can be swapped
/// per build (staging vs production) without touching every call
/// site.
class BdappsService {
  // Replace with the deployed BDApps endpoint when known.
  static const String _baseUrl = 'https://bdappsdigitalapps.com/NADB26117';

  /// Returns `true` when [mobile] is currently REGISTERED on the
  /// BDApps backend.
  ///
  /// FIX: this used to call `is_subscribed.php` with a GET + query
  /// param — that file doesn't exist on the backend (the real one is
  /// `check_subscription.php`, which reads a POST JSON body, not
  /// query params). Every call was silently failing and returning
  /// `false`, which is why anything relying on this (SubscriptionGate)
  /// never reflected real subscription status. Now it calls the real
  /// endpoint the same way BdAppsApi.checkSubscriptionStatus does.
  static Future<bool> isSubscribed(String mobile) async {
    if (mobile.trim().isEmpty) return false;
    try {
      var digits = mobile.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('880') && digits.length == 13) {
        digits = '0${digits.substring(3)}';
      } else if (digits.startsWith('88') && digits.length == 12) {
        digits = '0${digits.substring(2)}';
      } else if (!digits.startsWith('0') && digits.length == 10) {
        digits = '0$digits';
      }
      final subscriberId = 'tel:88${digits.substring(1)}';

      final uri = Uri.parse('$_baseUrl/check_subscription.php');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'subscriberId': subscriberId}),
      );
      if (kDebugMode) {
        log('isSubscribed -> response', name: 'BdappsService', error: {
          'mobile': mobile,
          'statusCode': res.statusCode,
          'body': res.body,
        });
      }
      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['isSubscribed'] == true) return true;
      final status = (data['subscriptionStatus'] as String? ?? '').toUpperCase();
      return status == 'REGISTERED';
    } catch (e, stack) {
      if (kDebugMode) {
        log('isSubscribed -> failed', name: 'BdappsService', error: e, stackTrace: stack);
      }
      return false;
    }
  }

  /// Sends an OTP to [mobile]. The returned [http.Response] is
  /// surfaced to callers so they can inspect `statusCode` and the
  /// JSON body for the `referenceNo` value.
  static Future<http.Response> sendOtp(String mobile) async {
    final uri = Uri.parse('$_baseUrl/send_otp.php').replace(
      queryParameters: <String, String>{'mobile': mobile},
    );
    if (kDebugMode) {
      log('sendOtp -> requesting', name: 'BdappsService', error: {
        'mobile': mobile,
        'url': uri.toString(),
      });
    }
    final res = await http.post(uri);
    if (kDebugMode) {
      log('sendOtp -> response', name: 'BdappsService', error: {
        'mobile': mobile,
        'statusCode': res.statusCode,
        'body': res.body,
      });
    }
    return res;
  }

  /// Verifies [code] against [referenceNo]. The returned
  /// [http.Response] is surfaced to callers so they can inspect
  /// `statusCode` and parse the success/failure message themselves.
  static Future<http.Response> verifyOtp(String code, String referenceNo) async {
    final uri = Uri.parse('$_baseUrl/verify_otp.php').replace(
      queryParameters: <String, String>{
        'code': code,
        'reference_no': referenceNo,
      },
    );
    if (kDebugMode) {
      log('verifyOtp -> requesting', name: 'BdappsService', error: {
        'referenceNo': referenceNo,
        'url': uri.toString(),
      });
    }
    final res = await http.post(uri);
    if (kDebugMode) {
      log('verifyOtp -> response', name: 'BdappsService', error: {
        'referenceNo': referenceNo,
        'statusCode': res.statusCode,
        'body': res.body,
      });
    }
    return res;
  }
}