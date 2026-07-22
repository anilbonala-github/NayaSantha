import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => NotificationRepository(ref.watch(apiClientProvider)));

final notificationsProvider = FutureProvider<List<AppNotification>>(
    (ref) => ref.watch(notificationRepositoryProvider).list());

/// Unread badge count for the app-bar bell. Falls back to 0 on error/loading.
final unreadCountProvider = FutureProvider<int>(
    (ref) => ref.watch(notificationRepositoryProvider).unreadCount());
