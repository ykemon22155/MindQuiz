// views/landing_page.dart
//
// Flutter port of the MindQuest marketing/subscribe landing page design.
// Responsive: two-column on wide screens (desktop/tablet), single column
// stacked on mobile — matches the HTML mockup exactly, but wired to the
// REAL phone-login flow instead of being a static visual.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/user_data.dart';
import 'package:quiz_application_app/views/enter_otp_page.dart';
import 'package:quiz_application_app/views/main_shell.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // ---- Palette (from the design brief) ----
  static const bg = Color(0xFFFDFBF7);
  static const ink = Color(0xFF14302C);
  static const inkSoft = Color(0xFF57534E);
  static const teal = Color(0xFF0D9488);
  static const tealDeep = Color(0xFF0F766E);
  static const tealTint = Color(0xFFEDF9F6);
  static const tealTint2 = Color(0xFFDFF3EF);
  static const line = Color(0xFFE7E2D8);
  static const gold = Color(0xFFE8B75A);

  final BdAppsAuthService _bdAuth = BdAppsAuthService();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  static final RegExp _bdPhoneRegex = RegExp(r'^01[3-9]\d{8}$');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'মোবাইল নম্বর দিন';
    if (!_bdPhoneRegex.hasMatch(phone)) return 'সঠিক নম্বর দিন, যেমন: 01712345678';
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

  Future<void> _subscribe() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _bdAuth.loginWithPhone(phone);
      _goToApp();
    } on UnregisteredUserException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnterOtpPage(mobileNumber: phone, referenceNo: e.referenceNo),
        ),
      );
      return;
    } on BdAppsApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextStyle get _bodyFont => GoogleFonts.hindSiliguri();
  TextStyle get _brandFont => GoogleFonts.poppins();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 980;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 16, // প্যাডিং সামান্য কমানো হলো
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(isDesktop),
                    const SizedBox(height: 20),
                    isDesktop
                        ? Row(
                      // NOTE: previously wrapped in IntrinsicHeight to
                      // equalize column heights, but IntrinsicHeight's
                      // separate dry-layout pass for wrapped Bengali text
                      // (with a custom line-height multiplier) came out a
                      // few pixels different from the real layout - that
                      // mismatch caused the "BOTTOM OVERFLOWED BY 5.0
                      // PIXELS" error. A plain Row with
                      // crossAxisAlignment.center gives the same visual
                      // result without the extra, inconsistent layout pass.
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 105, child: _leftColumn()),
                        const SizedBox(width: 40),
                        Expanded(flex: 95, child: Center(child: _subscribeCard())),
                      ],
                    )
                        : Column(
                      children: [
                        Center(child: _subscribeCard()),
                        const SizedBox(height: 24),
                        _leftColumn(),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------
  Widget _topBar(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: teal,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: tealTint, blurRadius: 0, spreadRadius: 4)],
              ),
            ),
            const SizedBox(width: 10),
            Text('MindQuest', style: _brandFont.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
          ],
        ),
        Row(
          children: [
            if (isDesktop) ...[
              Text('Powered by', style: _bodyFont.copyWith(fontSize: 13, color: inkSoft)),
              const SizedBox(width: 6),
            ],
            Text('bdapps', style: _bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Left column
  // ---------------------------------------------------------------------
  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow chip
        Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
          decoration: BoxDecoration(color: tealTint, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 14, color: tealDeep),
              const SizedBox(width: 8),
              Text(
                'দৈনিক কুইজ প্ল্যাটফর্ম',
                style: _brandFont.copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: tealDeep),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Headline
        RichText(
          text: TextSpan(
            style: _bodyFont.copyWith(fontSize: 28, height: 1.25, fontWeight: FontWeight.w700, color: ink),
            children: [
              const TextSpan(text: 'যেখানেই থাকুন, জ্ঞান, কুইজ আর প্রতিযোগিতায় '),
              TextSpan(text: 'অভিষেক করুন MindQuest-এ', style: TextStyle(color: tealDeep)),
              const TextSpan(text: ' ✨'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'প্রতিদিন নতুন প্রশ্ন, রিয়েল-টাইম লিডারবোর্ডে বন্ধুদের সাথে প্রতিযোগিতা, আর ঝকঝকে সহজ অভিজ্ঞতা — সব একটাই জায়গায়।',
          style: _bodyFont.copyWith(fontSize: 14.5, height: 1.5, color: inkSoft),
        ),
        const SizedBox(height: 18),

        // Features
        _feature(Icons.psychology_outlined, 'স্মার্ট কুইজ', 'বিষয়ভিত্তিক, প্রতিদিন হালনাগাদ হওয়া হাজারো প্রশ্ন'),
        const SizedBox(height: 10),
        _feature(Icons.bar_chart_rounded, 'লিডারবোর্ড ও প্রতিযোগিতা', 'বন্ধু ও সারা দেশের খেলোয়াড়দের সাথে র‍্যাংকিংয়ে লড়াই'),
        const SizedBox(height: 10),
        _feature(Icons.smartphone_rounded, 'সহজ ও মসৃণ ব্যবহার', 'ঝামেলাহীন ইন্টারফেস, মোবাইল ও ওয়েব দুটোতেই স্বচ্ছন্দ'),
        const SizedBox(height: 16),

        // Privacy badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [tealTint, tealTint2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: const Color(0xFFCDEDE6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 20, color: tealDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'আপনার নম্বর ও তথ্য সম্পূর্ণ নিরাপদ — কোনো তৃতীয় পক্ষের সাথে শেয়ার করা হয় না।',
                  style: _bodyFont.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: tealDeep, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Text('নিরাপদ সাবস্ক্রিপশন প্রসেস দ্বারা পরিচালিত — ', style: _bodyFont.copyWith(fontSize: 11.5, color: inkSoft)),
            Text('bdapps', style: _bodyFont.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: ink)),
          ],
        ),
      ],
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: tealTint, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 17, color: tealDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _bodyFont.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink)),
                const SizedBox(height: 1),
                Text(subtitle, style: _bodyFont.copyWith(fontSize: 12.5, color: inkSoft, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Right column: subscribe card with signature glow + sparkles
  // ---------------------------------------------------------------------
  Widget _subscribeCard() {
    return SizedBox(
      width: 400,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Signature: radiating shine behind the card
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [teal.withValues(alpha: 0.16), gold.withValues(alpha: 0.08), bg.withValues(alpha: 0)],
                stops: const [0.0, 0.45, 0.72],
              ),
            ),
          ),
          const Positioned(top: 10, right: 40, child: _Spark(size: 18)),
          const Positioned(bottom: 40, left: 10, child: _Spark(size: 13)),

          // Card
          Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1EEE5)),
              boxShadow: [
                BoxShadow(color: ink.withValues(alpha: 0.14), blurRadius: 35, offset: const Offset(0, 14)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [teal, tealDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: teal.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.psychology_alt_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('MindQuest', style: _brandFont.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(
                    'LEARN  •  COMPETE  •  SHINE',
                    style: _brandFont.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: tealDeep),
                  ),
                  const SizedBox(height: 18),

                  if (_errorMessage != null) ...[
                    Text(_errorMessage!, style: _bodyFont.copyWith(color: Colors.redAccent, fontSize: 12.5), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                  ],

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('মোবাইল নম্বর', style: _bodyFont.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink)),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: _bodyFont.copyWith(fontSize: 14.5, color: ink),
                    validator: _validatePhone,
                    decoration: InputDecoration(
                      hintText: '০১XXXXXXXXX',
                      hintStyle: _bodyFont.copyWith(color: const Color(0xFFA6A099)),
                      prefixIcon: Icon(Icons.phone_outlined, size: 18, color: inkSoft),
                      filled: true,
                      fillColor: const Color(0xFFFBFAF6),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line, width: 1.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: teal, width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 13, color: inkSoft),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('চার্জ ২.৭৮ টাকা/দিন, ভ্যাট ও শুল্কসহ', style: _bodyFont.copyWith(fontSize: 11.5, color: inkSoft)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _subscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Subscribe করুন', style: _bodyFont.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'সাবস্ক্রাইব করার মাধ্যমে আপনি শর্তাবলীতে সম্মত হচ্ছেন। যেকোনো সময় আনসাবস্ক্রাইব করা যাবে।',
                    textAlign: TextAlign.center,
                    style: _bodyFont.copyWith(fontSize: 11, color: const Color(0xFFA6A099), height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  final double size;
  const _Spark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome, size: size, color: const Color(0xFFE8B75A).withValues(alpha: 0.7));
  }
}