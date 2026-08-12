import 'package:flutter/material.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/views/landing_page.dart';
import 'package:quiz_application_app/views/main_shell.dart';

/// Decides where to send the user on launch:
///   1. Has a stored BDApps session (phone+OTP login) AND is still
///      REGISTERED on BDApps right now -> straight into the home page
///      (MainShell). The live re-check is what's new here: a stale
///      local session used to be enough on its own, which let anyone
///      who'd unsubscribed via SMS/USSD/app/website keep getting in
///      without OTP. Now we always ask BDApps directly, so it doesn't
///      matter which channel they unsubscribed through.
///   2. No session, OR session exists but BDApps says UNREGISTERED ->
///      LandingPage, used as the login screen on BOTH web and the
///      mobile app (it's responsive: two-column on wide screens,
///      single column stacked on mobile).
///   3. Also re-runs this check whenever the app resumes from the
///      background, so someone who unsubscribes while the app is
///      already open gets caught without needing to fully restart it.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late Future<bool> _isAuthenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isAuthenticated = _resolve();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check whenever the app comes back to the foreground, so an
    // unsubscribe that happened while the app was open (SMS, USSD,
    // or from the website) doesn't leave the user with stale access
    // until they fully restart the app.
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _isAuthenticated = _resolve();
      });
    }
  }

  Future<bool> _resolve() async {
    final authService = BdAppsAuthService();
    final session = await authService.getStoredAuthSession();

    // No local session at all -> straight to login.
    if (session == null) return false;

    final phone = session.user.phone;

    try {
      // THE FIX: don't just trust that a local session exists — ask
      // BDApps whether this number is REGISTERED right now. This is
      // channel-agnostic: it doesn't matter if unsubscribe happened
      // via SMS, USSD, the app's own Unsubscribe button, or the
      // website — BDApps's live status is the same either way.
      final status = await BdAppsApi().checkSubscriptionStatus(phone);

      if (status.toUpperCase() == 'REGISTERED') {
        return true;
      }

      // Not subscribed anymore -> wipe the stale local session so
      // nothing lingers, and force the OTP/login flow next time.
      await authService.clearStoredAuthSession();
      return false;
    } catch (e) {
      // Network/API failure: fail OPEN so a flaky connection doesn't
      // lock out a genuinely subscribed user. Change to `return false;`
      // if you'd rather fail closed/strict on errors.
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAuthenticated,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.data == true) {
          return const MainShell();
        }
        // Not logged in, any platform: same landing-page-styled login.
        return const LandingPage();
      },
    );
  }
}