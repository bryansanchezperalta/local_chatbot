import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'script.dart';
import 'theme.dart';

class _Scope extends InheritedNotifier<ChatbotController> {
  const _Scope({required ChatbotController controller, required this.theme, required super.child})
      : super(notifier: controller);
  final ChatbotTheme theme;

  @override
  bool updateShouldNotify(_Scope old) => super.updateShouldNotify(old) || theme != old.theme;
}

/// Wraps the host app: draws the help button and, when open, the chat window
/// in the bottom-right corner.
class Chatbot extends StatefulWidget {
  const Chatbot({
    super.key,
    required this.controller,
    this.theme = const ChatbotTheme(),
    this.margin = 16,
    required this.child,
  });

  final ChatbotController controller;
  final ChatbotTheme theme;
  final double margin;
  final Widget child;

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final c = widget.controller;
    return _Scope(
      controller: c,
      theme: t,
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (c.isOpen)
              Positioned(
                right: widget.margin,
                bottom: widget.margin * 2 + t.helpButtonSize,
                child: _Window(controller: c, theme: t),
              ),
            Positioned(
              right: widget.margin,
              bottom: widget.margin,
              child: _HelpButton(controller: c, theme: t),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.controller, required this.theme});
  final ChatbotController controller;
  final ChatbotTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Semantics(
      button: true,
      label: controller.isOpen ? 'Chiudi ${t.title}' : 'Apri ${t.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: controller.toggle,
        child: Container(
          width: t.helpButtonSize,
          height: t.helpButtonSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.helpButtonColor,
            borderRadius: BorderRadius.circular(t.helpButtonRadius),
            boxShadow: [BoxShadow(color: t.windowShadowColor, blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Text(controller.isOpen ? '×' : t.helpIcon,
              style: t.text(t.helpIconColor, size: t.helpButtonSize * 0.45)),
        ),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({required this.controller, required this.theme});
  final ChatbotController controller;
  final ChatbotTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final radius = BorderRadius.circular(t.windowRadius);
    return Container(
      width: t.windowWidth,
      constraints: BoxConstraints(maxHeight: t.windowMaxHeight),
      decoration: BoxDecoration(
        color: t.windowColor,
        borderRadius: radius,
        border: t.windowBorderWidth > 0 ? Border.all(color: t.windowBorderColor, width: t.windowBorderWidth) : null,
        boxShadow: [BoxShadow(color: t.windowShadowColor, blurRadius: t.windowShadowBlur, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: t.headerColor,
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Expanded(child: Text(t.title, style: t.text(t.headerTitleColor, strong: true, size: t.headerTitleSize))),
                  Semantics(
                    button: true,
                    label: 'Chiudi',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: controller.close,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('×', style: t.text(t.headerCloseColor, size: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                reverse: true,
                padding: EdgeInsets.all(t.messagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final m in controller.messages) _Bubble(message: m, theme: t),
                    for (final o in controller.options)
                      _Option(option: o, theme: t, onTap: () => controller.choose(o)),
                  ].expand((w) => [w, SizedBox(height: t.messageGap)]).toList()..removeLast(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.theme});
  final ChatbotMessage message;
  final ChatbotTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final user = message.fromUser;
    final r = Radius.circular(t.bubbleRadius);
    final tail = Radius.circular(t.bubbleTailRadius);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: user ? t.userBubbleColor : t.assistantBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: user ? r : tail,
            bottomRight: user ? tail : r,
          ),
        ),
        child: Text(message.text, style: t.text(user ? t.userTextColor : t.assistantTextColor)),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.option, required this.theme, required this.onTap});
  final ChatbotOption option;
  final ChatbotTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final style = t.text(t.optionTextColor, strong: true);
    final shape = t.optionShape;
    final label = Text(option.label, style: style, textAlign: shape == ChatbotOptionShape.button ? TextAlign.center : null);
    final box = Container(
      padding: EdgeInsets.symmetric(horizontal: t.optionPaddingH, vertical: t.optionPaddingV),
      decoration: BoxDecoration(
        color: t.optionColor,
        borderRadius: BorderRadius.circular(t.optionRadius),
        border: t.optionBorderWidth > 0 ? Border.all(color: t.optionBorderColor, width: t.optionBorderWidth) : null,
      ),
      child: switch (shape) {
        ChatbotOptionShape.pill => label,
        ChatbotOptionShape.row => Row(children: [Expanded(child: label), Text('›', style: style)]),
        ChatbotOptionShape.button => label,
      },
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: shape == ChatbotOptionShape.pill ? Align(alignment: Alignment.centerLeft, child: box) : box,
      ),
    );
  }
}

/// Wrap a field of the host app so the chatbot can outline it during a step
/// whose `highlight` equals [id]. Must sit under [Chatbot].
class ChatbotHighlight extends StatelessWidget {
  const ChatbotHighlight({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_Scope>();
    assert(scope != null, 'ChatbotHighlight must be under a Chatbot widget');
    if (scope?.notifier?.highlight != id) return child;
    final t = scope!.theme;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: t.highlightColor, width: t.highlightWidth),
        borderRadius: BorderRadius.circular(t.highlightRadius),
      ),
      child: child,
    );
  }
}
