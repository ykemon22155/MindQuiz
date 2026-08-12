import 'package:flutter/material.dart';
import 'package:quiz_application_app/l10n/app_localizations.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/views/enter_otp_page.dart';
import 'package:quiz_application_app/views/auth_gate.dart';
import 'package:quiz_application_app/views/main_shell.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key, required this.mobileNumber});

  final String mobileNumber;

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  bool _isChecking = false;
  late String _mobileNumber;

  @override
  void initState() {
    super.initState();
    _mobileNumber = widget.mobileNumber;
  }

  Future<void> _signOut() async {
    await BdAppsAuthService().clearStoredAuthSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
    );
  }

  Future<void> _refresh() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isChecking = true);

    try {
      final status = await BdAppsApi().checkSubscriptionStatus(_mobileNumber);
      if (!mounted) return;
      setState(() => _isChecking = false);

      if (status == 'REGISTERED') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
              (_) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.subscriptionNotActive),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('BdAppsApiException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isChecking = true);

    try {
      final res = await BdAppsApi().requestOtp(_mobileNumber);
      if (!mounted) return;
      setState(() => _isChecking = false);

      if (res.referenceNo != null && res.referenceNo!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.otpSent)),
        );

        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => EnterOtpPage(
              mobileNumber: _mobileNumber,
              referenceNo: res.referenceNo!,
              onVerified: () => _handleVerified(),
            ),
            fullscreenDialog: true,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? l10n.otpSendFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('BdAppsApiException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _editPhoneNumber() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final newMobile = await showDialog<String>(
      context: context,
      builder: (_) => _EditPhoneNumberDialog(initialValue: _mobileNumber),
    );

    if (newMobile == null || !mounted) return;

    setState(() => _mobileNumber = newMobile);

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.phoneNumberUpdated)),
    );

    await _refresh();
  }

  Future<void> _handleVerified() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final status = await BdAppsApi().checkSubscriptionStatus(_mobileNumber);
      if (!mounted) return;

      Navigator.of(context).pop();

      if (status == 'REGISTERED') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
              (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subscriptionNotActive),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('BdAppsApiException: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(l10n.subscription),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.subscriptions, size: 44, color: colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.subscriptionRequiredTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subscriptionRequiredDescription,
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
                  title: Text(l10n.mobileNumber),
                  subtitle: Text(_mobileNumber),
                  trailing: IconButton(
                    onPressed: _isChecking ? null : _editPhoneNumber,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: l10n.editPhoneNumber,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _refresh,
                  icon: _isChecking
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    ),
                  )
                      : const Icon(Icons.refresh),
                  label: Text(l10n.reCheckSubscription, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isChecking ? null : _sendOtp,
                  icon: _isChecking
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                      : const Icon(Icons.sms_outlined),
                  label: Text(l10n.sendOtp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _isChecking ? null : _signOut,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditPhoneNumberDialog extends StatefulWidget {
  const _EditPhoneNumberDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditPhoneNumberDialog> createState() => _EditPhoneNumberDialogState();
}

class _EditPhoneNumberDialogState extends State<_EditPhoneNumberDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.updatePhoneNumberTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.updatePhoneNumberDescription,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onSave(),
                validator: (value) {
                  final trimmed = (value ?? '').trim();
                  if (trimmed.isEmpty) {
                    return l10n.pleaseEnterMobileNumber;
                  }
                  final regex = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$');
                  if (!regex.hasMatch(trimmed)) {
                    return l10n.pleaseEnterValidMobile;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: l10n.mobileNumber,
                  hintText: l10n.mobileNumberHint,
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}