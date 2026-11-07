import 'package:flutter/material.dart';
import 'package:local_chatbot/local_chatbot.dart';

void main() => runApp(const DemoApp());

const _back = ChatbotOption('Back to other topics', next: 'other');
const _home = ChatbotOption('Back to the start', next: 'home');

const _script = ChatbotScript(
  start: 'home',
  steps: {
    'home': ChatbotStep(
      message:
          'Hi! I can guide you through the most common tasks, one step at a time. '
          'Pick what you want to do and I will take you to the right screen. '
          'You can scroll up at any time to read again what I wrote. '
          'Each guide opens the screen you need, outlines the field to fill in and waits for you before moving on. '
          'If you choose the wrong topic, every step has a button that brings you back here. '
          'Nothing you do in this chat changes your data: only what you type in the program is saved. '
          'The guides follow the order the staff at the desk use most often, but you can stop at any point and close the window. '
          'When you open the assistant again, it starts from the beginning.',
      options: [
        ChatbotOption('Register a member', next: 'name'),
        ChatbotOption('Renew a membership', next: 'renew'),
        ChatbotOption('Book a class', next: 'book'),
        ChatbotOption('Print a receipt', next: 'receipt'),
        ChatbotOption('Other topics', next: 'other'),
      ],
    ),
    'name': ChatbotStep(
      message:
          'First step: write first and last name exactly as they appear on the ID document. '
          'Do not use nicknames or abbreviations, because the name is printed on the card and on every receipt. '
          'If the person has two surnames, write both, separated by a space. '
          'When you are done, tap "Done, next" and I will check that the field is filled in.',
      highlight:
          'name '
          'The program also uses the name to look for duplicates: if a member with the same first and last name already exists, '
          'it shows a warning before saving, so you can check that it is not the same person registered twice. '
          'Accents and capital letters do not matter for the search, but write them correctly anyway, '
          'because the name on the card is printed exactly as you type it. '
          'For minors, write the name of the child here and the name of the parent in the next screen.',
      options: [
        ChatbotOption('Done, next', next: 'photo', check: 'name', otherwise: 'name_missing'),
        ChatbotOption('Why do you need the full name?', next: 'name_why'),
        _home,
      ],
    ),
    'name_why': ChatbotStep(
      message:
          'The full name links the member to the medical certificate and to the payments. '
          'Two members with the same short name would get mixed up in the reports at the end of the month, '
          'and fixing it later means editing every receipt by hand.',
      options: [ChatbotOption('Got it, back to the name', next: 'name')],
    ),
    'name_missing': ChatbotStep(
      message: 'The name is still empty. Write first and last name in the highlighted field, then tap "Done, next".',
      highlight: 'name',
      options: [ChatbotOption('Done, next', next: 'photo', check: 'name', otherwise: 'name_missing')],
    ),
    'photo': ChatbotStep(
      message:
          'Second step: the photo. Ask the person to stand in front of a light wall, without hat or sunglasses. '
          'The photo appears at the entrance turnstile, so the staff must recognise the face at a glance. '
          'You can skip this step and add the photo later from the member page. '
          'Hold the camera at eye level and keep the face in the middle of the frame. '
          'If the photo is dark or blurry, take it again: a bad photo is worse than no photo, '
          'because the staff would not trust it. The program crops the picture to a square on its own, '
          'so leave some space around the head. The photo is stored only on this computer and never sent online.',
      options: [
        ChatbotOption('Photo taken', next: 'certificate'),
        ChatbotOption('Skip for now', next: 'certificate'),
        _home,
      ],
    ),
    'certificate': ChatbotStep(
      message:
          'Third step: the medical certificate. Check the expiry date on the paper and type it in the field. '
          'Without a valid certificate the turnstile does not open, even if the membership is paid. '
          'Thirty days before the expiry the program shows a warning on the home screen. '
          'There are two kinds of certificate: the basic one, valid for most courses, and the sports one, '
          'required for competitions and for some intense classes. Pick the right kind from the list above the date. '
          'If you are not sure which one the person has, look at the header of the paper: the sports certificate '
          'always shows the name of the sport. Keep the paper or scan it, as the program only stores the date.',
      options: [
        ChatbotOption('Date entered', next: 'end'),
        ChatbotOption('The person does not have it yet', next: 'certificate_later'),
      ],
    ),
    'certificate_later': ChatbotStep(
      message:
          'No problem: save the member without the date. The member page will show a red badge '
          'until someone enters the certificate. Remind the person to bring it at the next visit.',
      options: [ChatbotOption('Ok, finish', next: 'end')],
    ),
    'end': ChatbotStep(
      message: 'Done! The member is saved. You can find them in the member list, sorted by last name.',
      options: [_home, ChatbotOption('Close')],
    ),
    'renew': ChatbotStep(
      message:
          'To renew a membership open the member page, tap "Memberships" and then "Renew". '
          'The new period starts the day after the old one ends, so no day is lost if the member renews early. '
          'If the membership has already expired, the new period starts today. '
          'Before confirming, the program shows a summary with the start date, the end date and the price. '
          'Read it with the member: once confirmed, the renewal creates a receipt and cannot be undone, '
          'only cancelled by the manager. If the member pays in instalments, choose "Instalments" in the payment field '
          'and the program will remind you of each due date on the home screen.',
      options: [
        ChatbotOption('What about discounts?', next: 'renew_discount'),
        _home,
        ChatbotOption('Close'),
      ],
    ),
    'renew_discount': ChatbotStep(
      message:
          'Discounts are set by the manager in Settings, Prices. During the renewal pick the discount from the list: '
          'the final price updates at once and the receipt shows both the full price and the discount.',
      options: [_home, ChatbotOption('Close')],
    ),
    'book': ChatbotStep(
      message:
          'Open the calendar, tap the class and then "Add participant". Search the member by last name. '
          'When the class is full the program puts the member on the waiting list and notifies them '
          'if a place frees up.',
      options: [_home, ChatbotOption('Close')],
    ),
    'receipt': ChatbotStep(
      message:
          'Every payment creates a receipt. Open the member page, tap "Payments", pick the payment and tap "Print". '
          'If the printer does not answer, check that it is on and that it is the default printer of the computer.',
      options: [_home, ChatbotOption('Close')],
    ),
    'other': ChatbotStep(
      message: 'Here are other topics. Each one is a short explanation, not a guided task.',
      options: [
        ChatbotOption('Opening hours', next: 'hours'),
        ChatbotOption('Backups', next: 'backup'),
        ChatbotOption('Staff accounts', next: 'staff'),
        ChatbotOption('Privacy and data', next: 'privacy'),
        _home,
      ],
    ),
    'hours': ChatbotStep(
      message:
          'Opening hours are set in Settings, Gym. The turnstile stays closed outside these hours, '
          'except for staff accounts.',
      options: [_back, _home],
    ),
    'backup': ChatbotStep(
      message:
          'The program saves a copy of all data every night at 2:00. Copies are kept for thirty days. '
          'To restore one, ask the manager: it replaces all current data with the data of that day, '
          'so everything entered after that day is lost.',
      options: [_back, _home],
    ),
    'staff': ChatbotStep(
      message:
          'Each person at the desk should have their own account. This way every receipt shows who made it, '
          'and when someone leaves you only disable their account.',
      options: [_back, _home],
    ),
    'privacy': ChatbotStep(
      message:
          'Member data stays on this computer. Nothing is sent online, and this assistant does not use '
          'artificial intelligence: all answers are written in advance.',
      options: [_back, _home],
    ),
  },
);

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
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'First and last name'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
