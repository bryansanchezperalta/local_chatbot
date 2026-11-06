/// A pre-written conversation: no AI, no free text. The host app writes it.
class ChatbotScript {
  const ChatbotScript({required this.start, required this.steps});

  /// Id of the step shown when the chat opens.
  final String start;

  /// Every step by id.
  final Map<String, ChatbotStep> steps;

  ChatbotStep operator [](String id) {
    final step = steps[id];
    if (step == null) throw ArgumentError.value(id, 'id', 'No step with this id');
    return step;
  }
}

/// One assistant message with the options the user can tap.
class ChatbotStep {
  const ChatbotStep({
    required this.message,
    this.options = const [],
    this.action,
    this.highlight,
  });

  final String message;
  final List<ChatbotOption> options;

  /// Passed to `onAction` when the step is shown (e.g. open a screen).
  final String? action;

  /// Id of the [ChatbotHighlight] to outline while the step is shown.
  final String? highlight;
}

/// A button under a message. Tapping it shows [label] as the user's reply.
class ChatbotOption {
  const ChatbotOption(this.label, {this.next, this.action});

  final String label;

  /// Step to go to. `null` closes the chat.
  final String? next;

  /// Passed to `onAction` when tapped.
  final String? action;
}
