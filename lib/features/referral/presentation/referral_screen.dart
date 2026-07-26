import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../wallet/presentation/wallet_providers.dart';
import 'referral_providers.dart';

/// Refer & earn: your code + stats, and a field to apply a friend's code.
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  Future<void> _apply() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await ref.read(referralRepositoryProvider).apply(code);
      _codeCtrl.clear();
      ref.invalidate(referralInfoProvider);
      ref.invalidate(walletProvider);
      _snack('₹${res.bonus.toStringAsFixed(0)} added to your wallet!');
    } on ApiFailure catch (f) {
      _snack(f.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(referralInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & earn')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(e is ApiFailure ? e.userMessage : 'Could not load your referral code.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: Gap.md),
          FilledButton(onPressed: () => ref.invalidate(referralInfoProvider), child: const Text('Retry')),
        ])),
        data: (info) => SingleChildScrollView(
          child: PageBody(maxWidth: 640, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: Gap.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.leafGradient,
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text('Give ₹${info.bonusPerReferral.toStringAsFixed(0)}, get ₹${info.bonusPerReferral.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Share your code. When a friend joins and uses it, you both get wallet credit.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  const SizedBox(height: Gap.lg),
                  Row(children: <Widget>[
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Text(info.code,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    )),
                    const SizedBox(width: Gap.sm),
                    IconButton.filled(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: info.code));
                        _snack('Code copied');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(height: Gap.lg),
              Row(children: <Widget>[
                Expanded(child: NsCard(child: Column(children: <Widget>[
                  Text('${info.referredCount}',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text('Friends joined', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]))),
                const SizedBox(width: Gap.md),
                Expanded(child: NsCard(child: Column(children: <Widget>[
                  Text(money(info.totalEarned),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Text('Total earned', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]))),
              ]),
              const SizedBox(height: Gap.xl),
              Text('Have a friend’s code?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Gap.sm),
              NsCard(child: Row(children: <Widget>[
                Expanded(child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      hintText: 'Enter code', border: OutlineInputBorder(), isDense: true),
                )),
                const SizedBox(width: Gap.sm),
                FilledButton(
                  onPressed: _busy ? null : _apply,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.forest),
                  child: Text(_busy ? '…' : 'Apply'),
                ),
              ])),
              const SizedBox(height: Gap.section),
            ],
          )),
        ),
      ),
    );
  }
}
