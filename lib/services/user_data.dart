import 'package:quiz_application_app/services/bdapps_auth_service.dart';

/// Simple in-memory holder for the current user's display info.
///
/// Previously these fields were `static X = AuthService().currentUser?.y ?? fallback`,
/// which only ran ONCE on first access — usually before login finished — so
/// they'd freeze at their fallback values forever. Call [load] explicitly
/// after [BdAppsAuthService.restoreSessionIfPossible] (and again right after a
/// successful login) to refresh them.
///
/// Also: there's no Firebase Auth provider anymore, so there's no real
/// photoURL / displayName / email to pull from. Those are now just local
/// defaults you can overwrite yourself (e.g. if you ever let users set a
/// nickname or avatar and store it in Firestore).
class UserData {
  static const String placeholderImageUrl =
      'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png';

  static String userImageUrl = placeholderImageUrl;
  static String userName = 'Quiz Player';
  static String userEmail = '--';
  static String userMobileNumber = '--';
  static bool isSubscribed = false;
  static String userJoined = '--';

  /// Refreshes fields from the current BDApps session. Call this:
  /// 1. Once at app startup, right after BdAppsAuthService().restoreSessionIfPossible()
  /// 2. Again right after a successful login (so the UI updates immediately)
  static void load() {
    final phone = BdAppsAuthService().currentPhone;
    if (phone != null && phone.isNotEmpty) {
      userMobileNumber = phone;
    } else {
      userMobileNumber = '--';
    }
    // userName / userImageUrl / userEmail stay as whatever was set locally
    // (e.g. loaded from your Firestore user doc) — there's no auth
    // provider to pull them from anymore.
  }

  /// Resets everything back to defaults — call this on sign out.
  static void reset() {
    userImageUrl = placeholderImageUrl;
    userName = 'Quiz Player';
    userEmail = '--';
    userMobileNumber = '--';
    isSubscribed = false;
    userJoined = '--';
  }
}