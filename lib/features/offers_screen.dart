import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../core/widgets/product_widgets.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';

class Offer {
  const Offer({
    required this.code,
    required this.title,
    required this.detail,
    required this.expiresIn,
    required this.tint,
  });

  final String code;
  final String title;
  final String detail;
  final String expiresIn;
  final Color tint;
}

/// Offers. Deals live here rather than being scattered through the catalogue,
/// so the discount a customer is owed is never hidden behind a banner.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  static const List<Offer> _offers = <Offer>[
    Offer(
      code: 'FIRSTWEEK',
      title: 'Rs 150 off your first weekly basket',
      detail: 'Applies to baskets over Rs 799. New households only.',
      expiresIn: 'Ends in 12 days',
      tint: AppColors.leaf,
    ),
    Offer(
      code: 'FRESH20',
      title: '20% off fruits and vegetables',
      detail: 'On orders placed before Sunday 9 PM. Max discount Rs 200.',
      expiresIn: 'Ends Sunday',
      tint: AppColors.carrot,
    ),
    Offer(
      code: 'PLUSFREE',
      title: 'One month of Santha Plus, free',
      detail: 'Free delivery and priority slots. Cancel any time.',
      expiresIn: 'Ends in 5 days',
      tint: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Product> discounted = MockData.products
        .where((Product p) => p.discountPercent >= 10)
        .toList();

    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 1080,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Offers for you'),
            ..._offers.map((Offer o) => _OfferCard(offer: o)),
            const SizedBox(height: Gap.xl),
            SectionHeader(
              title: 'Discounted this week (${discounted.length})',
              actionLabel: 'All categories',
              onAction: () => context.go(Routes.categories),
            ),
            if (discounted.isEmpty)
              const EmptyState(
                icon: Icons.local_offer_outlined,
                title: 'No price drops right now',
                message:
                    'We surface deals as vendors update prices, usually on '
                    'Monday mornings.',
              )
            else
              ProductGrid(
                products: discounted,
                onOpen: (Product p) => context.go(Routes.productPath(p.id)),
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
                        Text('Invite a friend, both get Rs 150',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(
                          'Credited to your wallet once their first basket is '
                          'delivered.',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(Routes.referral),
                    child: Text('Invite (${app.referralCode})'),
                  ),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
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
                color: offer.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Icon(Icons.local_offer_outlined,
                  size: 21, color: offer.tint),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(offer.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    offer.detail,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4),
                  ),
                  const SizedBox(height: Gap.sm),
                  Row(
                    children: <Widget>[
                      StatusChip(label: offer.expiresIn, color: AppColors.warning),
                      const SizedBox(width: Gap.sm),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: Gap.md),
                          foregroundColor: AppColors.forest,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: offer.code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${offer.code} copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: Text(offer.code),
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
