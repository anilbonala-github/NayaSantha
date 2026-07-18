import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../state/app_state.dart';

/// 01 — Splash. Brand moment plus session restore.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      final AppState app = context.read<AppState>();
      if (app.signedIn && app.onboardingComplete) {
        context.go(Routes.home);
      } else if (app.signedIn) {
        context.go(Routes.familyProfile);
      } else {
        context.go(Routes.welcome);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _c,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BrandLockup(size: 34, showTagline: true),
                SizedBox(height: Gap.section),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 02 — Welcome. Value proposition and the two entry paths.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageBody(
          maxWidth: 480,
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: Gap.xl),
              const BrandLockup(size: 24),
              const Spacer(),
              Text(
                'AI-powered\nweekly market',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      height: 1.15,
                      color: AppColors.forest,
                    ),
              ),
              const SizedBox(height: Gap.md),
              const Text(
                'Tell us about your family once. We plan the week, size the '
                'quantities and deliver fresh from farmers nearby.',
                style: TextStyle(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: Gap.xl),
              const _ValueProp(
                icon: Icons.eco_outlined,
                title: 'Fresh',
                body: 'Harvested and dispatched within 24 hours',
              ),
              const _ValueProp(
                icon: Icons.auto_awesome_outlined,
                title: 'Smart',
                body: 'Quantities sized to who actually eats what',
              ),
              const _ValueProp(
                icon: Icons.agriculture_outlined,
                title: 'Supporting farmers',
                body: 'Direct procurement, fewer hands in between',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(Routes.login),
                child: const Text('Log in or register'),
              ),
              const SizedBox(height: Gap.md),
              OutlinedButton(
                onPressed: () {
                  context.read<AppState>().continueAsGuest();
                  context.go(Routes.home);
                },
                child: const Text('Continue as guest'),
              ),
              const SizedBox(height: Gap.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  const _ValueProp({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  body,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 03 — Login. Phone number is the primary identifier.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phone = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String value = _phone.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      setState(() => _error = 'Enter a 10-digit Indian mobile number');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await context.read<AppState>().requestOtp(value);
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(Routes.otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const _BackButton()),
      body: PageBody(
        maxWidth: 440,
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Log in',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: Gap.sm),
            const Text(
              'We send a 6-digit code to confirm it is you.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91  ',
                counterText: '',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send code'),
            ),
            const SizedBox(height: Gap.xl),
            const Text(
              'By continuing you agree to the Terms of Service and Privacy '
              'Policy.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 04 — OTP verification with a resend timer.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _code = TextEditingController();
  Timer? _timer;
  int _seconds = 30;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final bool ok = await context.read<AppState>().verifyOtp(_code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.go(Routes.register);
    } else {
      setState(() => _error = 'That code is not right. Check and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String phone = context.watch<AppState>().phone;
    return Scaffold(
      appBar: AppBar(leading: const _BackButton()),
      body: PageBody(
        maxWidth: 440,
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Enter the code',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: Gap.sm),
            Text(
              'Sent to +91 $phone',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 10,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                errorText: _error,
              ),
              onChanged: (String v) {
                if (v.length == 6) _verify();
              },
            ),
            const SizedBox(height: Gap.lg),
            Center(
              child: _seconds > 0
                  ? Text(
                      'Resend in ${_seconds}s',
                      style: const TextStyle(color: AppColors.textSecondary),
                    )
                  : TextButton(
                      onPressed: () {
                        _startTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code sent again')),
                        );
                      },
                      child: const Text('Resend code'),
                    ),
            ),
            const SizedBox(height: Gap.lg),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify'),
            ),
            const SizedBox(height: Gap.lg),
            const Text(
              'Mock mode: any 6 digits will verify.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 05 — Registration. Minimal fields; everything else is asked during setup.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _referral = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  void _continue() {
    if (_name.text.trim().length < 2) {
      setState(() => _nameError = 'Tell us what to call you');
      return;
    }
    context.read<AppState>().completeRegistration(_name.text);
    context.go(Routes.familyProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: PageBody(
        maxWidth: 440,
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full name',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                helperText: 'Used for invoices and order receipts',
              ),
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _referral,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Referral code (optional)',
              ),
            ),
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _continue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(Routes.welcome),
    );
  }
}
