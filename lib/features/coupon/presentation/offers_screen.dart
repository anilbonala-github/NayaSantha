import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/coupon_models.dart';
import 'coupon_providers.dart';

/// Dynamic offers: coupons from /coupons. Copy a code, then apply it on the
/// final bill at checkout. Deals live here rather than scattered across banners.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  static const Map<String, Color> _tints = <String, Color>{
    'leaf': AppColors.leaf,
    'carrot': AppColors.carrot,
    'info': AppColors.info,
    'turmeric': AppColors.turmeric,
    'success': AppColors.success,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(couponsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(couponsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: PageBody(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(title: 'Offers for you'),
              const Text(
                'Copy a code, then apply it on your final bill before you pay.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Gap.lg),
              async.when(
                loading: () => const Padding(
                    padding: EdgeInsets.all(Gap.section),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => NsCard(
                  borderColor: AppColors.danger,
                  child: Row(children: <Widget>[
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                        child: Text(e is ApiFailure
                            ? e.userMessage
                            : 'Could not load offers.')),
                    TextButton(
                        onPressed: () => ref.invalidate(couponsProvider),
                        child: const Text('Retry')),
                  ]),
                ),
                data: (coupons) => coupons.isEmpty
                    ? const EmptyState(
                        icon: Icons.local_offer_outlined,
                        title: 'No offers right now',
                        message:
                            'We add new coupons through the week — check back soon.',
                      )
                    : Column(
                        children: coupons
                            .map((c) => _OfferCard(coupon: c))
                            .toList(),
                      ),
              ),
              const SizedBox(height: Gap.xl),
              NsCard(
                color: AppColors.surfaceMuted,
                borderColor: AppColors.surfaceMuted,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.card_giftcard,
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: Gap.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Invite a friend, both get Rs 50',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text(
                            'Credited to your wallet when their referral is applied.',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.referral),
                      child: const Text('Invite'),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final Color tint = OffersScreen._tints[coupon.tint] ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: NsCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(Icons.local_offer_outlined, size: 21, color: tint),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(coupon.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (coupon.description != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      coupon.description!,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                  const SizedBox(height: Gap.sm),
                  Wrap(
                    spacing: Gap.sm,
                    runSpacing: Gap.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (coupon.summary != null)
                        StatusChip(label: coupon.summary!, color: tint),
                      if (coupon.newUsersOnly)
                        const StatusChip(
                            label: 'New households', color: AppColors.info),
                      if (coupon.minBasket > 0)
                        StatusChip(
                            label: 'Min ${money(coupon.minBasket)}',
                            color: AppColors.warning),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding:
                              const EdgeInsets.symmetric(horizontal: Gap.md),
                          foregroundColor: AppColors.forest,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: coupon.code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${coupon.code} copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: Text(coupon.code),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
