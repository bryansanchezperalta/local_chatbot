import 'package:flutter/foundation.dart';

import 'script.dart';

/// One line in the conversation.
class ChatbotMessage {
  const ChatbotMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

/// Conversation state. Create one per app, or let [Chatbot] create it.
class ChatbotController extends ChangeNotifier {
  ChatbotController({required this.script, this.onAction});

  final ChatbotScript script;

  /// Runs the host app's actions (open a screen, ...).
  final void Function(String action)? onAction;

  final List<ChatbotMessage> _messages = [];
  ChatbotStep? _step;
  bool _open = false;

  bool get isOpen => _open;
  List<ChatbotMessage> get messages => List.unmodifiable(_messages);

  /// Options of the current step; empty when closed.
  List<ChatbotOption> get options => _step?.options ?? const [];

  /// Highlight id of the current step, if any.
  String? get highlight => _open ? _step?.highlight : null;

  /// Opens the chat on the script's start step, with a fresh conversation.
  void open() {
    _messages.clear();
    _open = true;
    _show(script.start);
  }

  void close() {
    _open = false;
    _step = null;
    notifyListeners();
  }

  void toggle() => _open ? close() : open();

  /// Taps [option] of the current step.
  void choose(ChatbotOption option) {
    if (!options.contains(option)) {
      throw ArgumentError.value(option.label, 'option', 'Not an option of the current step');
    }
    _messages.add(ChatbotMessage(option.label, fromUser: true));
    if (option.action != null) onAction?.call(option.action!);
    final next = option.next;
    if (next == null) return close();
    _show(next);
  }

  void _show(String id) {
    final step = script[id];
    _step = step;
    _messages.add(ChatbotMessage(step.message, fromUser: false));
    if (step.action != null) onAction?.call(step.action!);
    notifyListeners();
  }
}
