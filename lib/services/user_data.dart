import 'package:flutter/foundation.dart';
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
///
/// Requirement 7 update — GLOBAL SYNC:
/// This used to be a set of plain static fields with no way for a widget
/// to know when they changed, so Home/Category/Leaderboard/Profile each
/// drew their own hard-coded default avatar and never saw an update. It
/// now exposes [notifier] (a `Listenable`) that ticks on every change —
/// wrap any widget that shows the name/avatar in a
/// `ListenableBuilder(listenable: UserData.notifier, ...)` (see
/// `widgets/user_avatar.dart`) and it will rebuild the instant any of the
/// `update*` methods below are called, from anywhere in the app.
class UserData {
  static const String placeholderImageUrl =
      'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png';

  static String userImageUrl = placeholderImageUrl;
  static String userName = 'Quiz Player';
  static String userEmail = '--';
  static String userMobileNumber = '--';
  static bool isSubscribed = false;
  static String userJoined = '--';

  static final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  /// Listen to this anywhere a widget needs to rebuild when profile data
  /// changes (name, avatar, phone, subscription status).
  static Listenable get notifier => _tick;

  static void _notify() => _tick.value++;

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
    _notify();
  }

  /// Requirement 5 — editable display name, synced everywhere instantly.
  static void updateName(String name) {
    if (name.trim().isEmpty) return;
    userName = name.trim();
    _notify();
  }

  /// Requirement 5 — mobile number changed (call this ONLY after the new
  /// number has actually been OTP-verified and the auth session/Firestore
  /// doc have been migrated — see profile_screen.dart's `_saveNewPhone`).
  static void updateMobile(String mobile) {
    userMobileNumber = mobile;
    _notify();
  }

  /// Requirement 6/7 — avatar changed (either a local file path for an
  /// instant preview, or a remote URL once uploaded). Pass `null` to fall
  /// back to the default avatar (requirement 6's "delete photo" case).
  static void updateAvatar(String? url) {
    userImageUrl = (url == null || url.isEmpty) ? placeholderImageUrl : url;
    _notify();
  }

  /// Requirement 3 — subscription status flag, kept separate from score.
  static void updateSubscription(bool subscribed) {
    isSubscribed = subscribed;
    _notify();
  }

  /// Resets everything back to defaults — call this on sign out.
  static void reset() {
    userImageUrl = placeholderImageUrl;
    userName = 'Quiz Player';
    userEmail = '--';
    userMobileNumber = '--';
    isSubscribed = false;
    userJoined = '--';
    _notify();
  }
}