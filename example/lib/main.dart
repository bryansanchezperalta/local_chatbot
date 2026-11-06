import 'package:flutter/material.dart';
import 'package:local_chatbot/local_chatbot.dart';

void main() => runApp(const DemoApp());

const _script = ChatbotScript(start: 'home', steps: {
  'home': ChatbotStep(message: 'Hi! What do you want to do?', options: [
    ChatbotOption('Register a member', next: 'name'),
    ChatbotOption('Other topics', next: 'other'),
  ]),
  'name': ChatbotStep(
    message: 'Write first and last name as on the ID.',
    highlight: 'name',
    options: [ChatbotOption('Done, next', next: 'end', check: 'name', otherwise: 'name_missing')],
  ),
  'name_missing': ChatbotStep(
    message: 'The name is still empty. Write first and last name, then tap "Done, next".',
    highlight: 'name',
    options: [ChatbotOption('Done, next', next: 'end', check: 'name', otherwise: 'name_missing')],
  ),
  'end': ChatbotStep(message: 'Done!', options: [ChatbotOption('Close')]),
  'other': ChatbotStep(
    message: 'Other topics.',
    options: [ChatbotOption('Go back', next: 'home')],
  ),
});

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final _name = TextEditingController();
  late final _chatbot = ChatbotController(
    script: _script,
    onAction: debugPrint,
    onCheck: (check) => check == 'name' && _name.text.trim().isNotEmpty,
  );

  @override
  void dispose() {
    _name.dispose();
    _chatbot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Chatbot(
            controller: _chatbot,
            child: Center(
              child: SizedBox(
                width: 300,
                child: ChatbotHighlight(
                  id: 'name',
                  child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'First and last name')),
                ),
              ),
            ),
          ),
        ),
      );
}
