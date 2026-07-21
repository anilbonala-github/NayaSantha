/// A single chat turn in the AI assistant.
class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role; // USER | ASSISTANT
  final String content;

  bool get isUser => role == 'USER';

  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(role: j['role'] as String, content: j['content'] as String);
}

/// Result of sending a message: the (possibly new) conversation + the reply.
class SendResult {
  const SendResult({required this.conversationId, required this.reply, required this.aiPowered});
  final String conversationId;
  final String reply;
  final bool aiPowered;

  factory SendResult.fromJson(Map<String, dynamic> j) => SendResult(
        conversationId: j['conversationId'] as String,
        reply: j['reply'] as String,
        aiPowered: j['aiPowered'] as bool? ?? false,
      );
}
