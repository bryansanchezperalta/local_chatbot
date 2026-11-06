import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_chatbot/local_chatbot.dart';

const script = ChatbotScript(start: 'home', steps: {
  'home': ChatbotStep(message: 'Ciao! Cosa vuoi fare?', options: [
    ChatbotOption('Registrare un iscritto', next: 'tessera'),
    ChatbotOption('Chiudi'),
  ]),
  'tessera': ChatbotStep(
    message: 'Primo passo: la tessera.',
    action: 'open:nuovo_iscritto',
    options: [ChatbotOption('Fatto, avanti', next: 'nome', action: 'tessera_ok')],
  ),
  'nome': ChatbotStep(message: 'Scrivi nome e cognome.', highlight: 'nome', options: [
    ChatbotOption('Torna indietro', next: 'tessera'),
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
      expect(c.messages.single.text, 'Ciao! Cosa vuoi fare?');
      expect(c.options.map((o) => o.label), ['Registrare un iscritto', 'Chiudi']);
    });

    test('choosing records the reply, runs step and option actions, moves on', () {
      c.open();
      c.choose(c.options.first);
      expect(actions, ['open:nuovo_iscritto']);
      c.choose(c.options.single);
      expect(actions, ['open:nuovo_iscritto', 'tessera_ok']);
      expect(c.messages.where((m) => m.fromUser).map((m) => m.text), ['Registrare un iscritto', 'Fatto, avanti']);
      expect(c.highlight, 'nome');
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
      expect(quiet.highlight, 'nome');
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
      child: const Center(child: ChatbotHighlight(id: 'nome', child: SizedBox(width: 100, height: 20))),
    );
    expect(find.text('Ciao! Cosa vuoi fare?'), findsNothing);

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);

    await tester.tap(find.text('Registrare un iscritto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatto, avanti'));
    await tester.pumpAndSettle();
    expect(find.text('Scrivi nome e cognome.'), findsOneWidget);
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
    expect(find.text('Ciao!'), findsOneWidget);
    expect(find.text('Chiudi'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });

  testWidgets('zero stream duration shows message and options at once', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(streamCharDuration: Duration.zero));
    c.open();
    await tester.pump();
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });

  testWidgets('window keeps its height and scrolls when the chat is long', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(windowHeight: 150, windowBorderWidth: 0));
    final window = find.ancestor(of: find.text('Assistente'), matching: find.byType(ClipRRect));
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
    expect(find.text('Assistente'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Assistente'), findsNothing);
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
    await tester.tap(find.bySemanticsLabel('Apri Assistente'));
    await tester.pumpAndSettle();
    expect(c.isOpen, isTrue);
    expect(find.text('?'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Chiudi Assistente'));
    await tester.pumpAndSettle();
    expect(c.isOpen, isFalse);
    expect(find.text('Assistente'), findsNothing);

    c.open();
    await tester.pumpAndSettle();
    final header = find.ancestor(of: find.text('Assistente'), matching: find.byType(Row));
    await tester.tap(find.descendant(of: header, matching: find.text('×')));
    await tester.pumpAndSettle();
    expect(c.isOpen, isFalse);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('custom title and help icon', (tester) async {
    final c = await pumpChatbot(tester, theme: const ChatbotTheme(title: 'Aiuto', helpIcon: 'i'));
    expect(find.text('i'), findsOneWidget);
    expect(find.bySemanticsLabel('Apri Aiuto'), findsOneWidget);
    c.open();
    await tester.pumpAndSettle();
    expect(find.text('Aiuto'), findsOneWidget);
  });

  testWidgets('reduce motion opens the window and shows the text at once', (tester) async {
    final c = await pumpChatbot(tester, reduceMotion: true);
    c.open();
    await tester.pump();
    expect(tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value, 1);
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });

  testWidgets('streaming text exposes the whole message to screen readers; older messages stay whole', (tester) async {
    final c = await pumpChatbot(tester);
    c.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Ciao! Cosa vuoi fare?'), findsNothing);
    expect(find.bySemanticsLabel('Ciao! Cosa vuoi fare?'), findsOneWidget);

    await tester.pumpAndSettle();
    c.choose(c.options.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);
    expect(find.text('Registrare un iscritto'), findsOneWidget);
    expect(find.text('Primo passo: la tessera.'), findsNothing);
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
        tester.getSize(find.ancestor(of: find.text('Chiudi'), matching: find.byType(Container)).first);

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
      expect(tester.widget<Text>(find.text('Chiudi')).textAlign, TextAlign.center);
      expect(find.text('›'), findsNothing);
    });
  });

  testWidgets('only the matching highlight is outlined, and only while open', (tester) async {
    final c = await pumpChatbot(
      tester,
      child: const Column(children: [
        ChatbotHighlight(id: 'nome', child: SizedBox(width: 100, height: 20)),
        ChatbotHighlight(id: 'altro', child: SizedBox(width: 100, height: 20)),
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
    expect(outline('nome'), findsOneWidget);
    expect(outline('altro'), findsNothing);

    c.close();
    await tester.pumpAndSettle();
    expect(outline('nome'), findsNothing);
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
    expect(find.text('Assistente'), findsNothing);

    next.open();
    await tester.pumpAndSettle();
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);
  });
}
