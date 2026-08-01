import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/views/main_shell.dart';

/// Asks the user for the 6-digit OTP BDApps sent to [mobileNumber].
/// Verification and session storage both go through
/// [BdAppsAuthService] — no Firebase involved in this path.
class EnterOtpPage extends StatefulWidget {
  const EnterOtpPage({
    super.key,
    required this.mobileNumber,
    required this.referenceNo,
    this.onVerified,
  });

  final String mobileNumber;
  final String referenceNo;

  /// Optional callback fired after a successful verification. The
  /// caller is then responsible for navigation. When `null`, the page
  /// navigates to [MainShell] itself and clears the back stack.
  final VoidCallback? onVerified;

  @override
  State<EnterOtpPage> createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends State<EnterOtpPage> {
  static const int _codeLength = 6;

  final BdAppsAuthService _bdAuth = BdAppsAuthService();
  final BdAppsApi _api = BdAppsApi();

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late String _referenceNo;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _referenceNo = widget.referenceNo;
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    for (final c in _controllers) {
      c.addListener(_onAnyDigitChanged);
    }
  }

  @override
  void dispose() {
    for (var i = 0; i < _codeLength; i++) {
      _controllers[i].removeListener(_onAnyDigitChanged);
      _controllers[i].dispose();
      _focusNodes[i].dispose();
    }
    super.dispose();
  }

  void _onAnyDigitChanged() {
    if (_errorText != null) setState(() => _errorText = null);
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_currentCode.length == _codeLength && !_isVerifying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _verify();
      });
    }
  }

  void _onBackspace(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey != LogicalKeyboardKey.backspace) return;
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    final code = _currentCode;
    if (code.length != _codeLength) {
      setState(() => _errorText = 'Please enter the 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      await _bdAuth.verifyOtpAndLogin(widget.mobileNumber, code, _referenceNo);
      if (!mounted) return;
      if (widget.onVerified != null) {
        widget.onVerified!.call();
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on BdAppsApiException catch (e) {
      setState(() => _errorText = e.message);
    } catch (_) {
      setState(() => _errorText = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      final res = await _api.requestOtp(widget.mobileNumber);
      if (res.success && res.referenceNo != null) {
        _referenceNo = res.referenceNo!;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent.')));
      }
    } on BdAppsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(backgroundColor: colorScheme.surface, elevation: 0, title: const Text('Enter OTP'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.sms_outlined, size: 40, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'We sent a 6-digit code to your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: Icon(Icons.phone, color: colorScheme.primary),
                  title: const Text('Mobile number'),
                  subtitle: Text(widget.mobileNumber),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _codeLength; i++)
                    SizedBox(
                      width: 46,
                      child: KeyboardListener(
                        focusNode: FocusNode(skipTraversal: true),
                        onKeyEvent: (event) => _onBackspace(i, event),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _errorText != null
                                ? colorScheme.errorContainer.withValues(alpha: 0.25)
                                : colorScheme.surfaceContainerLow,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _errorText != null ? colorScheme.error : colorScheme.outlineVariant,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
                            ),
                          ),
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      ),
                    ),
                ],
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colorScheme.error, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verify,
                  icon: _isVerifying
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                          ),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isResending ? null : _resend,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}