import 'package:flutter/material.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/views/login_screen.dart';
import 'package:quiz_application_app/views/main_shell.dart';

/// Decides where to send the user on launch:
///   1. Has a stored BDApps session (phone+OTP login) -> straight into
///      the home page (MainShell).
///   2. Otherwise -> LoginScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = _resolve();
  }

  Future<bool> _resolve() async {
    final session = await BdAppsAuthService().getStoredAuthSession();
    return session != null;
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
        return const LoginScreen();
      },
    );
  }
}