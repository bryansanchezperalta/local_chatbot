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
  ChatbotController({required this.script, this.onAction, this.onCheck});

  final ChatbotScript script;

  /// Runs the host app's actions (open a screen, ...).
  final void Function(String action)? onAction;

  /// Answers an option's `check`: `true` if the user really did it (e.g. filled in a field).
  final bool Function(String check)? onCheck;

  /// Actions and checks of the screens on display, usually added by `ChatbotHandlers`.
  /// They win over [onAction] and [onCheck].
  final Map<String, VoidCallback> actions = {};
  final Map<String, bool Function()> checks = {};

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
    final check = option.check;
    if (check != null && !checks.containsKey(check) && onCheck == null) {
      throw StateError('Option "${option.label}" has a check but onCheck is not set');
    }
    _messages.add(ChatbotMessage(option.label, fromUser: true));
    if (check != null && !(checks[check]?.call() ?? onCheck!(check))) return _show(option.otherwise!);
    if (option.action != null) _run(option.action!);
    final next = option.next;
    if (next == null) return close();
    _show(next);
  }

  void _show(String id) {
    final step = script[id];
    _step = step;
    _messages.add(ChatbotMessage(step.message, fromUser: false));
    if (step.action != null) _run(step.action!);
    notifyListeners();
  }

  void _run(String action) {
    final own = actions[action];
    own != null ? own() : onAction?.call(action);
  }
}
