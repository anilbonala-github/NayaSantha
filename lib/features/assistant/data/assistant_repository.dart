import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../domain/chat_models.dart';

/// AI assistant chat over the backend (Vol2 §7, §10 Gemini).
class AssistantRepository {
  AssistantRepository(this._client);
  final ApiClient _client;

  Future<SendResult> send({String? conversationId, required String message}) async {
    try {
      final data = await _client.post('/ai/messages', body: {
        if (conversationId != null) 'conversationId': conversationId,
        'message': message,
      });
      return SendResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  Future<List<ChatMessage>> history(String conversationId) async {
    try {
      final data = await _client.get('/ai/conversations/$conversationId/messages') as List;
      return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }
}
