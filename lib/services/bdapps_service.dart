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

  /// Returns `true` when [mobile] is already REGISTERED on the
  /// BDApps backend. The default implementation resolves to `false`
  /// so the UI can still render before the endpoint is wired up.
  static Future<bool> isSubscribed(String mobile) async {
    if (mobile.trim().isEmpty) return false;
    try {
      final uri = Uri.parse('$_baseUrl/is_subscribed.php').replace(
        queryParameters: <String, String>{'mobile': mobile},
      );
      final res = await http.get(uri);
      if (kDebugMode) {
        log('isSubscribed -> response', name: 'BdappsService', error: {
          'mobile': mobile,
          'statusCode': res.statusCode,
          'body': res.body,
        });
      }
      if (res.statusCode != 200) return false;
      // Expected success body: { "success": true, "subscribed": true }
      // The implementation simply treats any 200 with "true"/"1" in
      // the body as subscribed. Adjust once the real endpoint is live.
      final body = res.body.toLowerCase();
      return body.contains('"subscribed":true') ||
          body.contains('"subscribed": true') ||
          body.contains('"is_subscribed":true');
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