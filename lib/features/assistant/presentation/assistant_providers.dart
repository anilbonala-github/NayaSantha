import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/assistant_repository.dart';
import '../domain/chat_models.dart';

final assistantRepositoryProvider = Provider<AssistantRepository>(
    (ref) => AssistantRepository(ref.watch(apiClientProvider)));

class ChatState {
  const ChatState({this.messages = const <ChatMessage>[], this.conversationId, this.sending = false});
  final List<ChatMessage> messages;
  final String? conversationId;
  final bool sending;

  ChatState copyWith({List<ChatMessage>? messages, String? conversationId, bool? sending}) =>
      ChatState(
        messages: messages ?? this.messages,
        conversationId: conversationId ?? this.conversationId,
        sending: sending ?? this.sending,
      );
}

class AssistantChatNotifier extends StateNotifier<ChatState> {
  AssistantChatNotifier(this._repo) : super(const ChatState());
  final AssistantRepository _repo;

  Future<void> send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || state.sending) return;
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'USER', content: msg)],
      sending: true,
    );
    try {
      final result = await _repo.send(conversationId: state.conversationId, message: msg);
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ASSISTANT', content: result.reply)],
        conversationId: result.conversationId,
        sending: false,
      );
    } on ApiFailure catch (f) {
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ASSISTANT', content: f.userMessage)],
        sending: false,
      );
    }
  }
}

final assistantChatProvider =
    StateNotifierProvider<AssistantChatNotifier, ChatState>((ref) =>
        AssistantChatNotifier(ref.watch(assistantRepositoryProvider)));
