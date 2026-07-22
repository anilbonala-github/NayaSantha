import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../domain/notification_models.dart';
import 'notification_providers.dart';

/// Dynamic notifications inbox (Vol2A §13). Backed by /notifications.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              _refresh(ref);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _error(context, ref, e),
          data: (items) => items.isEmpty
              ? ListView(children: const <Widget>[
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications yet',
                    message: 'Order confirmations, Sunday market updates and price alerts will appear here.',
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(Gap.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Gap.sm),
                  itemBuilder: (context, i) => _NotificationTile(
                    n: items[i],
                    onTap: () => _open(context, ref, items[i]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.read) {
      await ref.read(notificationRepositoryProvider).markRead(n.id);
      _refresh(ref);
    }
    if (n.orderId != null && context.mounted) {
      context.push('${Routes.orderBill}/${n.orderId}');
    }
  }

  Widget _error(BuildContext context, WidgetRef ref, Object e) {
    final msg = e is ApiFailure ? e.userMessage : 'Could not load notifications.';
    return ListView(children: <Widget>[
      const SizedBox(height: 120),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: Gap.md),
        FilledButton(onPressed: () => _refresh(ref), child: const Text('Retry')),
      ])),
    ]);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  static const Map<String, (IconData, Color)> _style = <String, (IconData, Color)>{
    'ORDER_CONFIRMED': (Icons.check_circle_outline, AppColors.forest),
    'MARKET_UPDATE': (Icons.storefront_outlined, AppColors.info),
    'PRICE_EXCEPTION': (Icons.warning_amber_rounded, AppColors.danger),
    'PAYMENT_COMPLETE': (Icons.receipt_long_outlined, AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final style = _style[n.type] ?? (Icons.notifications_none, AppColors.textSecondary);
    return NsCard(
      color: n.read ? AppColors.surface : AppColors.surfaceMuted,
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: style.$2.withValues(alpha: 0.12),
          child: Icon(style.$1, size: 18, color: style.$2),
        ),
        const SizedBox(width: Gap.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Text(n.title,
                style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800))),
            if (!n.read)
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.tomato, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 3),
          Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
          const SizedBox(height: 4),
          Text(_ago(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}
