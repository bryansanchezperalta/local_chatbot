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

/// Wraps the host screen (needs a Material ancestor, e.g. put it as Scaffold body): draws the help button and, when open, the chat window
/// in the bottom-right corner.
class Chatbot extends StatefulWidget {
  const Chatbot({
    super.key,
    required this.controller,
    this.theme = const ChatbotTheme(),
    this.margin = const EdgeInsets.all(16),
    this.gap = 16,
    required this.child,
  });

  final ChatbotController controller;
  final ChatbotTheme theme;

  /// Distance of the help button from the screen's right and bottom edges
  /// (e.g. to clear a floating action button). Left and top are ignored.
  final EdgeInsets margin;

  /// Space between the help button and the window above it.
  final double gap;
  final Widget child;

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, value: widget.controller.isOpen ? 1 : 0);
  late final CurvedAnimation _curved = CurvedAnimation(parent: _anim, curve: widget.theme.openCurve);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(Chatbot old) {
    super.didUpdateWidget(old);
    if (old.controller == widget.controller) return;
    old.controller.removeListener(_sync);
    widget.controller.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _curved.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _anim.duration = reduce ? Duration.zero : widget.theme.openDuration;
    widget.controller.isOpen ? _anim.forward() : _anim.reverse();
  }

  static Widget _grow(Animation<double> a, Alignment origin, Widget window) => FadeTransition(
    opacity: a,
    child: ScaleTransition(scale: a, alignment: origin, child: window),
  );

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final c = widget.controller;
    final m = widget.margin;
    final g = widget.gap;
    final s = t.helpButtonSize;
    // Window and button share the right edge; the button sits [g] below the window.
    final origin = FractionalOffset((t.windowWidth - s / 2) / t.windowWidth, (t.windowHeight + g + s / 2) / t.windowHeight);
    _curved
      ..curve = t.openCurve
      ..reverseCurve = t.closeCurve;
    return _Scope(
      controller: c,
      theme: t,
      child: ListenableBuilder(
        listenable: Listenable.merge([c, _anim]),
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (!_anim.isDismissed)
              Positioned(
                right: m.right,
                bottom: m.bottom + g + s,
                child: (t.windowTransition ?? _grow)(_curved, origin, _Window(controller: c, theme: t)),
              ),
            Positioned(
              right: m.right,
              bottom: m.bottom,
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
      label: controller.isOpen ? 'Close ${t.title}' : 'Open ${t.title}',
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
          child: Text(
            controller.isOpen ? '×' : t.helpIcon,
            style: t.text(t.helpIconColor, size: t.helpButtonSize * 0.45),
          ),
        ),
      ),
    );
  }
}

class _Window extends StatefulWidget {
  const _Window({required this.controller, required this.theme});
  final ChatbotController controller;
  final ChatbotTheme theme;

  @override
  State<_Window> createState() => _WindowState();
}

class _WindowState extends State<_Window> {
  /// Last assistant message whose typing has finished.
  ChatbotMessage? _streamed;

  /// Last message seen: a new one means the user chose, so follow again.
  ChatbotMessage? _seen;

  /// True while the list sits at its end; scrolling away turns it off.
  bool _follow = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _follow = _scroll.position.extentAfter < 1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() => _scroll.jumpTo(_scroll.position.maxScrollExtent);

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final controller = widget.controller;
    final last = controller.messages.lastOrNull;
    final instant = t.streamCharDuration == Duration.zero || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final streaming = !instant && last != null && !last.fromUser && last != _streamed;
    if (last != _seen) {
      _seen = last;
      _follow = true;
      if (instant) WidgetsBinding.instance.addPostFrameCallback((_) => _scroll.hasClients ? _toEnd() : null);
    }
    final radius = BorderRadius.circular(t.windowRadius);
    return Container(
      width: t.windowWidth,
      height: t.windowHeight,
      decoration: BoxDecoration(
        color: t.windowColor,
        borderRadius: radius,
        border: t.windowBorderWidth > 0 ? Border.all(color: t.windowBorderColor, width: t.windowBorderWidth) : null,
        boxShadow: [BoxShadow(color: t.windowShadowColor, blurRadius: t.windowShadowBlur, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: t.headerColor,
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t.title, style: t.text(t.headerTitleColor, strong: true, size: t.headerTitleSize)),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
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
            Expanded(
              // While typing, follow the text unless the user scrolled away; options appearing never scroll.
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  if (streaming && _follow) _toEnd();
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Padding(
                    padding: EdgeInsets.all(t.messagePadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final m in controller.messages)
                          _Bubble(
                            key: ObjectKey(m),
                            message: m,
                            theme: t,
                            onStreamed: streaming && m == last ? () => setState(() => _streamed = m) : null,
                          ),
                        if (!streaming)
                          for (final o in controller.options)
                            _Option(option: o, theme: t, onTap: () => controller.choose(o)),
                      ].expand((w) => [w, SizedBox(height: t.messageGap)]).toList()..removeLast(),
                    ),
                  ),
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
  const _Bubble({super.key, required this.message, required this.theme, this.onStreamed});
  final ChatbotMessage message;
  final ChatbotTheme theme;

  /// Non-null: type the text out, then call this.
  final VoidCallback? onStreamed;

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
        child: _StreamText(
          text: message.text,
          style: t.text(user ? t.userTextColor : t.assistantTextColor),
          charDuration: t.streamCharDuration,
          onDone: onStreamed,
        ),
      ),
    );
  }
}

/// Types [text] out one character at a time when [onDone] is set; otherwise shows it whole.
class _StreamText extends StatefulWidget {
  const _StreamText({required this.text, required this.style, required this.charDuration, this.onDone});
  final String text;
  final TextStyle style;
  final Duration charDuration;
  final VoidCallback? onDone;

  @override
  State<_StreamText> createState() => _StreamTextState();
}

class _StreamTextState extends State<_StreamText> with SingleTickerProviderStateMixin {
  late final Characters _chars = widget.text.characters;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: widget.charDuration * _chars.length,
  );

  @override
  void initState() {
    super.initState();
    if (widget.onDone != null) _anim.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onDone == null) return Text(widget.text, style: widget.style);
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) =>
            Text(_chars.take((_anim.value * _chars.length).ceil()).toString(), style: widget.style),
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
    final label = Text(
      option.label,
      style: style,
      textAlign: shape == ChatbotOptionShape.button ? TextAlign.center : null,
    );
    final box = Container(
      padding: EdgeInsets.symmetric(horizontal: t.optionPaddingH, vertical: t.optionPaddingV),
      decoration: BoxDecoration(
        color: t.optionColor,
        borderRadius: BorderRadius.circular(t.optionRadius),
        border: t.optionBorderWidth > 0 ? Border.all(color: t.optionBorderColor, width: t.optionBorderWidth) : null,
      ),
      child: switch (shape) {
        ChatbotOptionShape.pill => label,
        ChatbotOptionShape.row => Row(
          children: [
            Expanded(child: label),
            Text('›', style: style),
          ],
        ),
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

/// Lets a host screen answer the chatbot while it is on display: [actions]
/// (e.g. open a screen from here) and [checks] (e.g. is this field filled in?)
/// win over the controller's `onAction` and `onCheck`. Must sit under [Chatbot].
class ChatbotHandlers extends StatefulWidget {
  const ChatbotHandlers({super.key, this.actions = const {}, this.checks = const {}, required this.child});
  final Map<String, VoidCallback> actions;
  final Map<String, bool Function()> checks;
  final Widget child;

  @override
  State<ChatbotHandlers> createState() => _ChatbotHandlersState();
}

class _ChatbotHandlersState extends State<ChatbotHandlers> {
  ChatbotController? _controller;
  Map<String, VoidCallback> _actions = const {};
  Map<String, bool Function()> _checks = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<_Scope>();
    assert(scope != null, 'ChatbotHandlers must be under a Chatbot widget');
    _register(scope?.notifier);
  }

  @override
  void didUpdateWidget(ChatbotHandlers old) {
    super.didUpdateWidget(old);
    _register(_controller);
  }

  @override
  void dispose() {
    _register(null);
    super.dispose();
  }

  void _register(ChatbotController? controller) {
    final old = _controller;
    // Removes only its own entries: another screen may have taken the same id since.
    if (old != null) {
      _actions.forEach((id, f) => old.actions[id] == f ? old.actions.remove(id) : null);
      _checks.forEach((id, f) => old.checks[id] == f ? old.checks.remove(id) : null);
    }
    _controller = controller;
    _actions = widget.actions;
    _checks = widget.checks;
    controller?.actions.addAll(_actions);
    controller?.checks.addAll(_checks);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
