import 'package:flutter/material.dart';
import 'package:local_chatbot/local_chatbot.dart';

void main() => runApp(const DemoApp());

const _script = ChatbotScript(start: 'home', steps: {
  'home': ChatbotStep(message: 'Ciao! Cosa vuoi fare?', options: [
    ChatbotOption('Registrare un iscritto', next: 'nome'),
    ChatbotOption('Altri argomenti', next: 'altro'),
  ]),
  'nome': ChatbotStep(
    message: 'Scrivi nome e cognome come sul documento.',
    highlight: 'nome',
    options: [ChatbotOption('Fatto, avanti', next: 'fine')],
  ),
  'fine': ChatbotStep(message: 'Fatto!', options: [ChatbotOption('Chiudi')]),
  'altro': ChatbotStep(
    message: 'Altri argomenti.',
    options: [ChatbotOption('Torna indietro', next: 'home')],
  ),
});

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final _chatbot = ChatbotController(script: _script, onAction: debugPrint);

  @override
  Widget build(BuildContext context) => MaterialApp(
        builder: (context, child) => Chatbot(controller: _chatbot, child: child!),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ChatbotHighlight(
                id: 'nome',
                child: TextField(decoration: InputDecoration(labelText: 'Nome e cognome')),
              ),
            ),
          ),
        ),
      );
}
