import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../core/api/api_failure.dart';
import '../state/app_state.dart';
import 'auth/presentation/auth_controller.dart';
import 'auth/data/msg91_login.dart';
import 'profile/presentation/profile_providers.dart';

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo_transparent.png',
                  width: 340,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: Gap.section),
                const SizedBox(
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
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/logo_transparent.png',
                  width: 400,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: Gap.lg),
              const Text(
                'Tell us about your family once. We plan the week, size the '
                'quantities and deliver fresh from farmers nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.5),
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


/// 03 — Login. Phone number is the primary identifier.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  int _seconds = 0;
  Timer? _resendTimer;
  String? _error;

  @override
  void dispose() {
    resetMsg91();
    _resendTimer?.cancel();
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(authControllerProvider) is AuthLoading) return;
    if (_sent) {
      if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
        setState(() => _error = 'Enter the 6-digit SMS code.');
        return;
      }
      setState(() => _error = null);
      ref.read(authControllerProvider.notifier).verifyOtp(_phone.text.trim(), _code.text.trim());
      return;
    }
    final String value = _phone.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      setState(() => _error = 'Enter a 10-digit Indian mobile number');
      return;
    }
    setState(() => _error = null);
    // Real backend call: POST /api/v1/auth/otp/request (Vol2 §6.1).
    ref.read(authControllerProvider.notifier).requestOtp(value);
  }

  @override
  Widget build(BuildContext context) {
    // React to the auth state machine (Vol2 §9): navigate on OTP sent, surface errors.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthOtpSent) {
        setState(() { _sent = true; _seconds = 30; _error = null; });
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) { timer.cancel(); return; }
          setState(() => _seconds--);
          if (_seconds <= 0) timer.cancel();
        });
      } else if (next is AuthAuthenticated) {
        context.read<AppState>().applyBackendSignIn(
          phone: next.user.mobile, name: next.user.name,
          onboardingComplete: !next.user.needsOnboarding);
        context.go(next.user.role == 'ORDER_MANAGER' ? Routes.ops : next.user.isAdmin ? '/admin' : next.user.needsOnboarding ? Routes.register : Routes.home);
      } else if (next is AuthFailed) {
        setState(() => _error = next.failure.userMessage);
      }
    });
    final bool _busy = ref.watch(authControllerProvider) is AuthLoading;
    return Scaffold(
      appBar: AppBar(leading: const _BackButton()),
      body: SingleChildScrollView(child: PageBody(
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
              enabled: !_sent && !_busy,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91  ',
                counterText: '',

              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Gap.xl),
            msg91Captcha(),
            if (_sent) ...[
              TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: const InputDecoration(labelText: 'SMS verification code'),
                onSubmitted: (_) => _submit(),
              ),
              TextButton(onPressed: _busy || _seconds > 0 ? null : () {
                _code.clear();
                ref.read(authControllerProvider.notifier).requestOtp(_phone.text.trim());
              }, child: Text(_seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend code')),
              TextButton(onPressed: _busy ? null : () => setState(() {
                _sent = false; _code.clear(); _error = null;
              }), child: const Text('Change mobile number')),
            ],
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_sent ? 'Verify and sign in' : 'Send code'),
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
      )),
    );
  }
}

/// 04 — OTP verification, backed by POST /api/v1/auth/otp/verify (Vol2 §6.1).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _code = TextEditingController();
  Timer? _timer;
  int _seconds = 30;
  String? _error;
  late String _mobile;
  String? _devHint;

  @override
  void initState() {
    super.initState();
    final AuthState state = ref.read(authControllerProvider);
    _mobile = state is AuthOtpSent ? state.mobile : '';
    _devHint = state is AuthOtpSent ? state.devHint : null;
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

  void _verify() {
    if (_code.text.trim().length != 6) return;
    setState(() => _error = null);
    ref.read(authControllerProvider.notifier).verifyOtp(_mobile, _code.text.trim());
  }

  void _resend() {
    _startTimer();
    ref.read(authControllerProvider.notifier).requestOtp(_mobile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code sent again')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Route on the auth outcome (Vol2 §6.1: new users → onboarding by status).
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.read<AppState>().applyBackendSignIn(
              phone: _mobile,
              name: next.user.name,
              onboardingComplete: !next.user.needsOnboarding,
            );
        context.go(next.user.role == 'ORDER_MANAGER' ? Routes.ops : next.user.isAdmin ? '/admin' : next.user.needsOnboarding ? Routes.register : Routes.home);
      } else if (next is AuthFailed) {
        setState(() => _error = next.failure.userMessage);
      } else if (next is AuthOtpSent) {
        setState(() => _devHint = next.devHint);
      }
    });
    final bool _busy = ref.watch(authControllerProvider) is AuthLoading;
    final String phone = _mobile;
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
                      onPressed: _resend,
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
            if (_devHint != null)
              Text(
                _devHint!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// 05 — Registration. Minimal fields; everything else is asked during setup.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _referral = TextEditingController();
  String? _nameError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_name.text.trim().length < 2) {
      setState(() => _nameError = 'Tell us what to call you');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          );
      ref.invalidate(profileProvider);
      if (mounted) context.go(Routes.familyProfile);
    } on ApiFailure catch (f) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(f.userMessage), backgroundColor: AppColors.danger));
      }
    }
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
              onPressed: _busy ? null : _continue,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continue'),
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
