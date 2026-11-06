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

    test('unknown step id fails loudly', () {
      final bad = ChatbotController(script: const ChatbotScript(start: 'nope', steps: {}));
      expect(bad.open, throwsArgumentError);
    });
  });

  testWidgets('help button opens the chat, tapping an option advances and highlights', (tester) async {
    final c = ChatbotController(script: script);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Chatbot(
        controller: c,
        theme: const ChatbotTheme(optionShape: ChatbotOptionShape.row),
        child: const Center(child: ChatbotHighlight(id: 'nome', child: SizedBox(width: 100, height: 20))),
      ),
    ));
    expect(find.text('Ciao! Cosa vuoi fare?'), findsNothing);

    await tester.tap(find.text('?'));
    await tester.pump();
    expect(find.text('Ciao! Cosa vuoi fare?'), findsOneWidget);

    await tester.tap(find.text('Registrare un iscritto'));
    await tester.pump();
    await tester.tap(find.text('Fatto, avanti'));
    await tester.pump();
    expect(find.text('Scrivi nome e cognome.'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ChatbotHighlight), matching: find.byType(DecoratedBox)),
      findsOneWidget,
    );
  });
}
