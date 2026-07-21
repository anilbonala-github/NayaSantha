import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy;

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../state/app_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/profile_models.dart';
import 'profile_providers.dart';

/// Dynamic profile (Vol2 §6.12): the signed-in customer + household from the API.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(e is ApiFailure ? e.userMessage : 'Could not load your profile.',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: Gap.md),
            FilledButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry')),
          ]),
        ),
        data: (profile) => SingleChildScrollView(
          child: PageBody(
            maxWidth: 800,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const SizedBox(height: Gap.lg),
              _header(profile),
              const SizedBox(height: Gap.lg),
              _householdCard(ref),
              const SizedBox(height: Gap.lg),
              NsCard(
                padding: EdgeInsets.zero,
                child: Column(children: <Widget>[
                  _tile(context, Icons.receipt_long_outlined, 'Orders', Routes.orders),
                  const Divider(height: 1),
                  _tile(context, Icons.kitchen_outlined, 'Pantry', Routes.pantry),
                  const Divider(height: 1),
                  _tile(context, Icons.auto_awesome_outlined, 'AI weekly plan', Routes.weeklyPlan),
                  const Divider(height: 1),
                  _tile(context, Icons.settings_outlined, 'Settings', Routes.settings),
                ]),
              ),
              const SizedBox(height: Gap.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign out'),
                ),
              ),
              const SizedBox(height: Gap.section),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header(Profile p) {
    return Row(children: <Widget>[
      CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.surfaceMuted,
        child: Text(p.initial,
            style: const TextStyle(
                color: AppColors.forest, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      const SizedBox(width: Gap.md),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(p.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text('+91 ${p.mobile}',
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
      StatusChip(
        label: p.profileCompletionStatus == 'COMPLETE' ? 'Complete' : 'Onboarding',
        color: p.profileCompletionStatus == 'COMPLETE' ? AppColors.forest : AppColors.primary,
      ),
    ]);
  }

  Widget _householdCard(WidgetRef ref) {
    final householdAsync = ref.watch(householdProvider);
    return NsCard(
      child: householdAsync.when(
        loading: () => const SizedBox(
            height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const Text('Household details unavailable',
            style: TextStyle(color: AppColors.textSecondary)),
        data: (h) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            const Text('Household', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('Budget ₹${h.weeklyBudget.toStringAsFixed(0)}/week',
                style: const TextStyle(color: AppColors.textSecondary)),
          ]),
          if (h.members.isNotEmpty) ...<Widget>[
            const SizedBox(height: Gap.sm),
            Wrap(spacing: Gap.sm, runSpacing: 6, children: <Widget>[
              for (final m in h.members)
                StatusChip(
                  label: '${m.name ?? m.dietaryType}'
                      '${m.allergies != null && m.allergies!.isNotEmpty ? ' · no ${m.allergies}' : ''}',
                  color: AppColors.primary,
                ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () => context.go(route),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final appState = legacy.Provider.of<AppState>(context, listen: false);
    await ref.read(authControllerProvider.notifier).logout(); // clears JWT/refresh token
    appState.signOut(); // reset the still-mock session
    ref.invalidate(profileProvider);
    ref.invalidate(householdProvider);
    if (context.mounted) context.go(Routes.welcome);
  }
}
