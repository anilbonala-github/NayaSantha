import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/chat_models.dart';
import 'assistant_providers.dart';

/// AI assistant chat (Vol2 §7), powered by Gemini via the backend.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  static const _starters = <String>[
    'What should I cook this week?',
    'Suggest a budget-friendly veg basket',
    "What's in season right now?",
    'How does the guaranteed maximum work?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    ref.read(assistantChatProvider.notifier).send(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantChatProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: <Widget>[
          Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
          SizedBox(width: 6),
          Text('AI Assistant'),
        ]),
      ),
      body: Column(children: <Widget>[
        Expanded(
          child: state.messages.isEmpty
              ? _welcome()
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(Gap.lg),
                  itemCount: state.messages.length + (state.sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= state.messages.length) return const _TypingBubble();
                    return _Bubble(message: state.messages[i]);
                  },
                ),
        ),
        _inputBar(state.sending),
      ]),
    );
  }

  Widget _welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const SizedBox(height: Gap.xl),
        const Icon(Icons.auto_awesome, size: 40, color: AppColors.primary),
        const SizedBox(height: Gap.md),
        Text('Hi! I can help you plan your week',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Gap.sm),
        const Text('Ask about meals, products, your budget or how NayaSantha works.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: Gap.lg),
        Wrap(spacing: Gap.sm, runSpacing: Gap.sm, children: _starters
            .map((s) => ActionChip(
                  label: Text(s),
                  backgroundColor: AppColors.surfaceMuted,
                  onPressed: () => _send(s),
                ))
            .toList()),
      ]),
    );
  }

  Widget _inputBar(bool sending) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Row(children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Ask the assistant…',
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.pill), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 10),
              ),
              onSubmitted: sending ? null : _send,
            ),
          ),
          const SizedBox(width: Gap.sm),
          IconButton.filled(
            onPressed: sending ? null : () => _send(_controller.text),
            icon: const Icon(Icons.send),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.sm),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: user ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Text(message.content,
            style: TextStyle(color: user ? Colors.white : AppColors.textPrimary, height: 1.35)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.sm),
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(Radii.lg)),
        child: const SizedBox(
            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
