import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_chatbot/local_chatbot.dart';

const script = ChatbotScript(start: 'home', steps: {
  'home': ChatbotStep(message: 'Hi! What do you want to do?', options: [
    ChatbotOption('Register a member', next: 'card'),
    ChatbotOption('Close'),
  ]),
  'card': ChatbotStep(
    message: 'First step: the card.',
    action: 'open:new_member',
    options: [ChatbotOption('Done, next', next: 'name', action: 'card_ok')],
  ),
  'name': ChatbotStep(message: 'Write first and last name.', highlight: 'name', options: [
    ChatbotOption('Go back', next: 'card'),
  ]),
});

/// Pumps a [Chatbot] over [child] and returns its controller.
Future<ChatbotController> pumpChatbot(
  WidgetTester tester, {
  ChatbotTheme theme = const ChatbotTheme(),
  Widget child = const SizedBox(),
  bool reduceMotion = false,
}) async {
  final c = ChatbotController(script: script);
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Chatbot(controller: c, theme: theme, child: child),
    ),
  ));
  return c;
}

void main() {
  group('ChatbotController', () {
    late List<String> actions;
    late ChatbotController c;
    setUp(() {
      actions = [];
      c = ChatbotController(script: script, onAction: actions.add);
    });

    test('open shows the start step', () {
      c.open();
      expect(c.isOpen, isTrue);
      expect(c.messages.single.text, 'Hi! What do you want to do?');
      expect(c.options.map((o) => o.label), ['Register a member', 'Close']);
    });

    test('choosing records the reply, runs step and option actions, moves on', () {
      c.open();
      c.choose(c.options.first);
      expect(actions, ['open:new_member']);
      c.choose(c.options.single);
      expect(actions, ['open:new_member', 'card_ok']);
      expect(c.messages.where((m) => m.fromUser).map((m) => m.text), ['Register a member', 'Done, next']);
      expect(c.highlight, 'name');
    });

    test('option without next closes and clears highlight', () {
      c.open();
      c.choose(c.options.last);
      expect(c.isOpen, isFalse);
      expect(c.options, isEmpty);
      expect(c.highlight, isNull);
    });

    test('reopening starts a fresh conversation', () {
      c.open();
      c.choose(c.options.first);
      c.close();
      c.open();
      expect(c.messages, hasLength(1));
    });

    test('rejects an option of another step', () {
      c.open();
      expect(() => c.choose(const ChatbotOption('x')), throwsArgumentError);
    });

    test('toggle opens, then closes', () {
      c.toggle();
      expect(c.isOpen, isTrue);
      c.toggle();
      expect(c.isOpen, isFalse);
      expect(c.messages, hasLength(1), reason: 'closing keeps the conversation until the next open');
    });

    test('actions without onAction are ignored', () {
      final quiet = ChatbotController(script: script)..open();
      quiet.choose(quiet.options.first);
      quiet.choose(quiet.options.single);
      expect(quiet.highlight, 'name');
    });

    group('option check', () {
      const checked = ChatbotScript(start: 'name', steps: {
        'name': ChatbotStep(message: 'Write the name.', options: [
          ChatbotOption('Done, next', next: 'end', action: 'name_ok', check: 'name_filled', otherwise: 'missing'),
        ]),
        'missing': ChatbotStep(message: 'The name is still empty.'),
        'end': ChatbotStep(message: 'Done!'),
      });
      late bool filled;
      late List<String> checks;
      ChatbotController checking() => ChatbotController(
            script: checked,
            onAction: actions.add,
            onCheck: (check) {
              checks.add(check);
              return filled;
            },
          )..open();
      setUp(() => checks = []);

      test('passing check runs the action and goes to next', () {
        filled = true;
        final c = checking();
        c.choose(c.options.single);
        expect(checks, ['name_filled']);
        expect(actions, ['name_ok']);
        expect(c.messages.last.text, 'Done!');
      });

      test('failing check skips the action and goes to otherwise', () {
        filled = false;
        final c = checking();
        c.choose(c.options.single);
        expect(actions, isEmpty);
        expect(c.messages.map((m) => m.text), ['Write the name.', 'Done, next', 'The name is still empty.']);
      });

      test('a check without onCheck fails loudly', () {
        final c = ChatbotController(script: checked)..open();
        expect(() => c.choose(c.options.single), throwsStateError);
      });
    });

    test('unknown step id fails loudly', () {
      final bad = ChatbotController(script: const ChatbotScript(start: 'nope', steps: {}));
      expect(bad.open, throwsArgumentError);
    });
  });

  testWidgets('help button opens the chat, tapping an option advances and highlights', (tester) async {
    await pumpChatbot(
      tester,
      theme: const ChatbotTheme(optionShape: ChatbotOptionShape.row),
      child: const Center(child: ChatbotHighlight(id: 'name', child: SizedBox(width: 100, height: 20))),
    );
    expect(find.text('Hi! What do you want to do?'), findsNothing);

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);

    await tester.tap(find.text('Register a member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done, next'));
    await tester.pumpAndSettle();
    expect(find.text('Write first and last name.'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ChatbotHighlight), matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
  });

  testWidgets('assistant message streams in; options wait for it', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(streamCharDuration: Duration(milliseconds: 10)));
    c.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hi! W'), findsOneWidget);
    expect(find.text('Close'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('zero stream duration shows message and options at once', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(streamCharDuration: Duration.zero));
    c.open();
    await tester.pump();
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('window keeps its height and scrolls when the chat is long', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(windowHeight: 150, windowBorderWidth: 0));
    final window = find.ancestor(of: find.text('Assistant'), matching: find.byType(ClipRRect));
    c.open();
    await tester.pumpAndSettle();
    expect(tester.getSize(window).height, 150);

    for (var i = 0; i < 3; i++) {
      c.choose(c.options.first);
      await tester.pumpAndSettle();
      c.choose(c.options.first);
      await tester.pumpAndSettle();
    }
    expect(tester.getSize(window).height, 150);
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
    expect(scroll.reverse, isTrue);
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('window animates open from the help button and stays until it has closed', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(openDuration: Duration(milliseconds: 100)));
    c.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition));
    expect(scale.scale.value, inExclusiveRange(0, 1));
    expect((scale.alignment as FractionalOffset).dy, greaterThan(1));

    await tester.pumpAndSettle();
    c.close();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Assistant'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Assistant'), findsNothing);
  });

  testWidgets('custom window transition replaces the default', (tester) async {
    final c = await pumpChatbot(
      tester,
      theme: ChatbotTheme(windowTransition: (a, origin, window) => SizeTransition(sizeFactor: a, child: window)),
    );
    c.open();
    await tester.pumpAndSettle();
    expect(find.byType(SizeTransition), findsOneWidget);
    expect(find.byType(ScaleTransition), findsNothing);
  });

  testWidgets('help button and header close button both close the chat', (tester) async {
    final c = await pumpChatbot(tester);
    await tester.tap(find.bySemanticsLabel('Open Assistant'));
    await tester.pumpAndSettle();
    expect(c.isOpen, isTrue);
    expect(find.text('?'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Close Assistant'));
    await tester.pumpAndSettle();
    expect(c.isOpen, isFalse);
    expect(find.text('Assistant'), findsNothing);

    c.open();
    await tester.pumpAndSettle();
    final header = find.ancestor(of: find.text('Assistant'), matching: find.byType(Row));
    await tester.tap(find.descendant(of: header, matching: find.text('×')));
    await tester.pumpAndSettle();
    expect(c.isOpen, isFalse);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('custom title and help icon', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(title: 'Help', helpIcon: 'i'));
    expect(find.text('i'), findsOneWidget);
    expect(find.bySemanticsLabel('Open Help'), findsOneWidget);
    c.open();
    await tester.pumpAndSettle();
    expect(find.text('Help'), findsOneWidget);
  });

  testWidgets('reduce motion opens the window and shows the text at once', (tester) async {
    final c = await pumpChatbot(tester, reduceMotion: true);
    c.open();
    await tester.pump();
    expect(tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value, 1);
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('streaming text exposes the whole message to screen readers; older messages stay whole', (tester) async {
    final c = await pumpChatbot(tester);
    c.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hi! What do you want to do?'), findsNothing);
    expect(find.bySemanticsLabel('Hi! What do you want to do?'), findsOneWidget);

    await tester.pumpAndSettle();
    c.choose(c.options.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);
    expect(find.text('Register a member'), findsOneWidget);
    expect(find.text('First step: the card.'), findsNothing);
  });

  group('option shape', () {
    // Window 300 wide, no border, padding 10: the content is 280 wide.
    const base = ChatbotTheme(windowWidth: 300, windowBorderWidth: 0, messagePadding: 10);
    ChatbotTheme shaped(ChatbotOptionShape shape) => ChatbotTheme(
          windowWidth: base.windowWidth,
          windowBorderWidth: base.windowBorderWidth,
          messagePadding: base.messagePadding,
          optionShape: shape,
        );
    Size optionSize(WidgetTester tester) =>
        tester.getSize(find.ancestor(of: find.text('Close'), matching: find.byType(Container)).first);

    testWidgets('pill is as wide as its text', (tester) async {
      final c = await pumpChatbot(tester, theme: shaped(ChatbotOptionShape.pill));
      c.open();
      await tester.pumpAndSettle();
      expect(optionSize(tester).width, lessThan(280));
      expect(find.text('›'), findsNothing);
    });

    testWidgets('row fills the window width and has a chevron', (tester) async {
      final c = await pumpChatbot(tester, theme: shaped(ChatbotOptionShape.row));
      c.open();
      await tester.pumpAndSettle();
      expect(optionSize(tester).width, 280);
      expect(find.text('›'), findsNWidgets(2));
    });

    testWidgets('button fills the window width with centred text', (tester) async {
      final c = await pumpChatbot(tester, theme: shaped(ChatbotOptionShape.button));
      c.open();
      await tester.pumpAndSettle();
      expect(optionSize(tester).width, 280);
      expect(tester.widget<Text>(find.text('Close')).textAlign, TextAlign.center);
      expect(find.text('›'), findsNothing);
    });
  });

  testWidgets('only the matching highlight is outlined, and only while open', (tester) async {
    final c = await pumpChatbot(
      tester,
      child: const Column(children: [
        ChatbotHighlight(id: 'name', child: SizedBox(width: 100, height: 20)),
        ChatbotHighlight(id: 'other', child: SizedBox(width: 100, height: 20)),
      ]),
    );
    Finder outline(String id) => find.descendant(
          of: find.byWidgetPredicate((w) => w is ChatbotHighlight && w.id == id),
          matching: find.byType(DecoratedBox),
        );
    c
      ..open()
      ..choose(c.options.first)
      ..choose(c.options.single);
    await tester.pumpAndSettle();
    expect(outline('name'), findsOneWidget);
    expect(outline('other'), findsNothing);

    c.close();
    await tester.pumpAndSettle();
    expect(outline('name'), findsNothing);
  });

  testWidgets('swapping the controller follows the new one', (tester) async {
    final old = await pumpChatbot(tester);
    final next = ChatbotController(script: script);
    // Same tree as pumpChatbot, so the Chatbot is updated, not rebuilt.
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Chatbot(controller: next, child: const SizedBox()),
      ),
    ));
    old.open();
    await tester.pumpAndSettle();
    expect(find.text('Assistant'), findsNothing);

    next.open();
    await tester.pumpAndSettle();
    expect(find.text('Hi! What do you want to do?'), findsOneWidget);
  });
}
