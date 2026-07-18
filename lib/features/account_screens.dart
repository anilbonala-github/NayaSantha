import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';

/// 24 — Subscription.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Membership'),
            const Text(
              'Change or cancel any time. Charges apply from the next billing '
              'cycle.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: Gap.xl),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisExtent: 300,
                crossAxisSpacing: Gap.md,
                mainAxisSpacing: Gap.md,
              ),
              itemCount: MockData.subscriptionPlans.length,
              itemBuilder: (BuildContext c, int i) {
                final SubscriptionPlan p = MockData.subscriptionPlans[i];
                final bool current = p.id == app.subscriptionId;
                return NsCard(
                  borderColor:
                      current ? AppColors.primary : AppColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (p.badge != null)
                            StatusChip(
                                label: p.badge!, color: AppColors.carrot),
                        ],
                      ),
                      const SizedBox(height: Gap.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            p.pricePerMonth == 0
                                ? 'Free'
                                : money(p.pricePerMonth),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          if (p.pricePerMonth > 0)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4, left: 4),
                              child: Text('/month',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.lg),
                      ...p.perks.map(
                        (String perk) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(Icons.check_circle_outline,
                                  size: 15, color: AppColors.success),
                              const SizedBox(width: Gap.sm),
                              Expanded(
                                child: Text(perk,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: current
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(42)),
                                child: const Text('Current plan'),
                              )
                            : FilledButton(
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(42)),
                                onPressed: () {
                                  app.setSubscription(p.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Switched to ${p.name}')),
                                  );
                                },
                                child: Text('Switch to ${p.name}'),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

/// 25 — Notifications.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    if (app.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'No notifications',
        message: 'Plan updates and delivery alerts will appear here.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: app.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 720,
          child: Column(
            children: <Widget>[
              ...app.notifications.map(
                (AppNotification n) => Padding(
                  padding: const EdgeInsets.only(bottom: Gap.sm),
                  child: NsCard(
                    color: n.unread ? AppColors.surface : AppColors.background,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Icon(n.icon,
                              size: 19, color: AppColors.primary),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: n.unread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    relative(n.at),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }
}

/// 26 — Wallet.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Wallet'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Gap.xl),
              decoration: BoxDecoration(
                gradient: AppColors.leafGradient,
                borderRadius: BorderRadius.circular(Radii.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Available balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    money(app.walletBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: Gap.lg),
                  Wrap(
                    spacing: Gap.sm,
                    children: <double>[500, 1000, 2000]
                        .map(
                          (double v) => ActionChip(
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            label: Text('+ ${money(v)}'),
                            onPressed: () {
                              app.topUpWallet(v);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('${money(v)} added to wallet')),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.xl),
            const SectionHeader(title: 'Transactions'),
            NsCard(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < app.walletTxns.length; i++) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Icon(
                              app.walletTxns[i].amount >= 0
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: app.walletTxns[i].amount >= 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(app.walletTxns[i].title,
                                    style: const TextStyle(fontSize: 13.5)),
                                Text(
                                  shortDate(app.walletTxns[i].at),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${app.walletTxns[i].amount >= 0 ? "+" : "−"} ${money(app.walletTxns[i].amount.abs())}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: app.walletTxns[i].amount >= 0
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != app.walletTxns.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

/// 27 — Referral.
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.profile),
        ),
        title: const Text('Invite friends'),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: Gap.lg),
              const Icon(Icons.card_giftcard,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: Gap.lg),
              Text(
                'Give ₹150, get ₹150',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Gap.sm),
              const Text(
                'Your friend gets ₹150 off their first weekly basket. You get '
                '₹150 in your wallet once it is delivered.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: Gap.xl),
              NsCard(
                child: Column(
                  children: <Widget>[
                    const Text('Your code',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: Gap.sm),
                    Text(
                      app.referralCode,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: Gap.lg),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: app.referralCode));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 17),
                      label: const Text('Copy code'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              NsCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          const Text('2',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const Text('Friends joined',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 34, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(money(300),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success)),
                          const Text('Earned',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }
}

/// 28 — Profile.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: Gap.sm),
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(
                    app.name.isNotEmpty ? app.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: Gap.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(app.name,
                          style:
                              Theme.of(context).textTheme.headlineSmall),
                      Text(
                        app.phone.isEmpty ? 'Guest session' : '+91 ${app.phone}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const SectionHeader(title: 'Your household'),
            NsCard(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < app.family.length; i++) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.md),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.surfaceMuted,
                            child: Text(
                              app.family[i].name.isEmpty
                                  ? '?'
                                  : app.family[i].name[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forest),
                            ),
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(app.family[i].name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  app.family[i].ageGroup.label,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != app.family.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Gap.xl),
            const SectionHeader(title: 'Account'),
            NsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _MenuRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Your orders',
                    onTap: () => context.go(Routes.orders),
                  ),
                  const Divider(),
                  _MenuRow(
                    icon: Icons.location_on_outlined,
                    label: 'Addresses',
                    onTap: () => context.go(Routes.address),
                  ),
                  const Divider(),
                  _MenuRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    onTap: () => context.go(Routes.wallet),
                  ),
                  const Divider(),
                  _MenuRow(
                    icon: Icons.card_giftcard,
                    label: 'Invite friends',
                    onTap: () => context.go(Routes.referral),
                  ),
                  const Divider(),
                  _MenuRow(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Membership',
                    onTap: () => context.go(Routes.subscription),
                  ),
                  const Divider(),
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => context.go(Routes.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: () {
                app.signOut();
                context.go(Routes.welcome);
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.forest),
      title: Text(label, style: const TextStyle(fontSize: 14.5)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}

/// 29 — Settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.profile),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Notifications'),
              NsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      title: const Text('Push notifications',
                          style: TextStyle(fontSize: 14.5)),
                      subtitle: const Text('Plan updates and delivery alerts',
                          style: TextStyle(fontSize: 12.5)),
                      value: app.pushEnabled,
                      onChanged: (bool v) =>
                          app.updateSetting(() => app.pushEnabled = v),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('WhatsApp updates',
                          style: TextStyle(fontSize: 14.5)),
                      subtitle: const Text('Order status on WhatsApp',
                          style: TextStyle(fontSize: 12.5)),
                      value: app.whatsappEnabled,
                      onChanged: (bool v) =>
                          app.updateSetting(() => app.whatsappEnabled = v),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Email receipts',
                          style: TextStyle(fontSize: 14.5)),
                      value: app.emailEnabled,
                      onChanged: (bool v) =>
                          app.updateSetting(() => app.emailEnabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'Preferences'),
              NsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Language',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.sm,
                      children: <String>['English', 'తెలుగు', 'हिन्दी']
                          .map(
                            (String l) => ChoiceChip(
                              label: Text(l),
                              selected: app.language == l,
                              showCheckmark: false,
                              onSelected: (_) =>
                                  app.updateSetting(() => app.language = l),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: Gap.xl),
                    const Text('Weekly budget',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: app.weeklyBudget,
                      min: 500,
                      max: 5000,
                      divisions: 45,
                      label: money(app.weeklyBudget),
                      onChanged: app.setWeeklyBudget,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.xl),
              const SectionHeader(title: 'About'),
              NsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    _MenuRow(
                        icon: Icons.description_outlined,
                        label: 'Terms of service',
                        onTap: () {}),
                    const Divider(),
                    _MenuRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy policy',
                        onTap: () {}),
                    const Divider(),
                    _MenuRow(
                        icon: Icons.support_agent_outlined,
                        label: 'Contact support',
                        onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
              const Center(
                child: Text('NayaSantha v0.1.0',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: Gap.section),
            ],
          ),
        ),
      ),
    );
  }
}
