import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/router/routes.dart';
import '../data/models.dart';

/// Chat state for the in-app AI assistant.
///
/// [_reply] is a deterministic stand-in. To go live, replace its body with a
/// call to your backend (`POST /api/ai/chat`), which should hold the Gemini
/// API key server-side — never ship a model key inside the mobile app.
///
/// Replies are structured rather than plain text: a body, an optional numbered
/// list, and an optional action. That shape is what makes "Add ingredients to
/// cart" possible, and it is the contract the real endpoint should return too.
class AssistantState extends ChangeNotifier {
  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      text: 'Hi, I am your NayaSantha assistant. I can plan meals, adjust your '
          'basket or find a recipe from what is already in your pantry. What '
          'would you like to do?',
      fromUser: false,
      at: DateTime.now(),
    ),
  ];

  bool _thinking = false;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get thinking => _thinking;

  static const List<String> quickPrompts = <String>[
    'Plan a healthy dinner for 4',
    'Create a meal plan',
    'What can I cook with my pantry?',
    'Suggest a budget plan',
  ];

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    _messages.add(
      ChatMessage(text: text.trim(), fromUser: true, at: DateTime.now()),
    );
    _thinking = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    _messages.add(_reply(text));
    _thinking = false;
    notifyListeners();
  }

  void clear() {
    _messages.removeRange(1, _messages.length);
    notifyListeners();
  }

  ChatMessage _reply(String input) {
    final String q = input.toLowerCase();
    final DateTime now = DateTime.now();

    if (q.contains('dinner') || q.contains('lunch') || q.contains('cook')) {
      return ChatMessage(
        text: 'Here is a dinner for 4 built around what you already have:',
        fromUser: false,
        at: now,
        bullets: const <String>[
          'Tomato rice',
          'Mixed vegetable curry',
          'Cucumber and onion salad',
          'Curd',
        ],
        action: const ChatAction(
          label: 'Add ingredients to cart',
          icon: Icons.add_shopping_cart,
          productIds: <String>[
            'p_tomato',
            'p_rice',
            'p_potato',
            'p_capsicum',
            'p_curd',
          ],
        ),
      );
    }

    if (q.contains('pantry') || q.contains('expire') || q.contains('have')) {
      return ChatMessage(
        text: 'Two things need using in the next three days: 400 g tomatoes '
            'and 1 L milk. A tomato rasam tonight and a banana smoothie '
            'tomorrow clears both.',
        fromUser: false,
        at: now,
        action: const ChatAction(
          label: 'Open pantry',
          icon: Icons.kitchen_outlined,
          route: Routes.pantry,
        ),
      );
    }

    if (q.contains('meal') || q.contains('plan') || q.contains('week')) {
      return ChatMessage(
        text: 'I built a 21-meal plan for the week. It keeps every member '
            'inside their nutrition targets, avoids peanut for Aarav, and '
            'comes to \u20B91,286 — \u20B9214 under your weekly budget.',
        fromUser: false,
        at: now,
        action: const ChatAction(
          label: 'Review the plan',
          icon: Icons.auto_awesome,
          route: Routes.weeklyPlan,
        ),
      );
    }

    if (q.contains('budget') || q.contains('save') || q.contains('cheap')) {
      return ChatMessage(
        text: 'Three changes would save about \u20B9180 this week:',
        fromUser: false,
        at: now,
        bullets: const <String>[
          'Buy tomatoes now, prices are down 18%',
          'Drop one litre of milk, you have surplus',
          'Switch to the 5 kg atta pack',
        ],
        action: const ChatAction(
          label: 'See budget insights',
          icon: Icons.insights_outlined,
          route: Routes.budget,
        ),
      );
    }

    if (q.contains('order') || q.contains('deliver') || q.contains('track')) {
      return ChatMessage(
        text: 'Your order is out for delivery and about 25 minutes away. '
            'Ramesh is bringing it.',
        fromUser: false,
        at: now,
        action: const ChatAction(
          label: 'Track order',
          icon: Icons.local_shipping_outlined,
          route: '/track/NS125687',
        ),
      );
    }

    return ChatMessage(
      text: 'I can help with weekly planning, recipes from your pantry, budget '
          'adjustments and order questions. Try asking me to plan dinner for '
          'four, or what to cook before something spoils.',
      fromUser: false,
      at: now,
    );
  }
}
