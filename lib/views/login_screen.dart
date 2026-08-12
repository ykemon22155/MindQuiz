import 'package:flutter/material.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/user_data.dart';
import 'package:quiz_application_app/views/enter_otp_page.dart';
import 'package:quiz_application_app/views/main_shell.dart';
import 'package:quiz_application_app/widgets/my_text_field.dart';

/// Primary sign-in screen.
///
/// BDApps owns the main flow: enter a phone number, and
/// [BdAppsAuthService.loginWithPhone] either logs the user straight in
/// (already-registered subscribers) or sends an OTP and routes to
/// [EnterOtpPage]. On successful verification the user is sent
/// straight to the home page (MainShell).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final BdAppsAuthService _bdAuth = BdAppsAuthService();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  // Bangladeshi mobile format: 01[3-9]XXXXXXXX (11 digits total)
  static final RegExp _bdPhoneRegex = RegExp(r'^01[3-9]\d{8}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Please enter your phone number.';
    if (!_bdPhoneRegex.hasMatch(phone)) {
      return 'Enter a valid number, e.g. 01712345678.';
    }
    return null;
  }

  void _goToApp() {
    if (!mounted) return;
    UserData.load();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
    );
  }

  Future<void> _continueWithPhone() async {
    // Run TextFormField's own validator (via MyTextField)
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // BDApps decides everything here: already-registered numbers are
      // logged in immediately (this now happens correctly inside
      // loginWithPhone itself — no need to special-case the error
      // message here anymore); new numbers throw
      // UnregisteredUserException to move to the OTP step.
      await _bdAuth.loginWithPhone(phone);
      _goToApp();
    } on UnregisteredUserException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnterOtpPage(
            mobileNumber: phone,
            referenceNo: e.referenceNo,
          ),
        ),
      );
      return;
    } on BdAppsApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF4A2E2B);
    const primaryColor = Color(0xFFE27D60);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: isDesktop ? 450 : double.infinity,
                padding: isDesktop ? const EdgeInsets.all(32) : EdgeInsets.zero,
                decoration: isDesktop
                    ? BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                )
                    : null,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF1E6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology, size: 80, color: primaryColor),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'MindQuest',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Learn • Compete • Shine',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 40),
                      MyTextField(
                        controller: _phoneController,
                        label: 'Phone Number (e.g., 01XXXXXXXXX)',
                        showNumberKeyboardOnly: true,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _continueWithPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF41B3A3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Continue with Phone',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}