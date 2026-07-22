import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/notification_models.dart';

/// In-app notification reads/writes for the signed-in customer (Vol2A §13).
class NotificationRepository {
  NotificationRepository(this._client);
  final ApiClient _client;

  Future<List<AppNotification>> list() async {
    try {
      final data = await _client.get('/notifications') as List;
      return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final data = await _client.get('/notifications/unread-count') as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
