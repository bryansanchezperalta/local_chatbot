# local_chatbot

A local assistant for Flutter apps that replaces an FAQ and walks people through a task step by step. It uses no AI and has no free-text input. The app writes the questions and answers in advance, and the user picks answers with buttons.

The package has no look of its own. Every colour, font, corner, border, shadow, spacing and the shape of the options comes from `ChatbotTheme`.

## Use

```dart
final chatbot = ChatbotController(
  script: const ChatbotScript(start: 'home', steps: {
    'home': ChatbotStep(message: 'Ciao! Cosa vuoi fare?', options: [
      ChatbotOption('Registrare un iscritto', next: 'tessera'),
      ChatbotOption('Altri argomenti', next: 'altro'),
    ]),
    'tessera': ChatbotStep(
      message: "Ti ho aperto «Nuovo iscritto». L'iscritto ha una tessera?",
      action: 'open:nuovo_iscritto', // your app opens the screen
      options: [ChatbotOption('Sì', next: 'nome'), ChatbotOption('No', next: 'nome')],
    ),
    'nome': ChatbotStep(
      message: 'Scrivi nome e cognome come sul documento.',
      highlight: 'nome', // outlines ChatbotHighlight(id: 'nome')
      options: [ChatbotOption('Fatto, avanti', next: 'fine')],
    ),
    'fine': ChatbotStep(message: 'Fatto!', options: [ChatbotOption('Chiudi')]),
    'altro': ChatbotStep(message: '…', options: [ChatbotOption('Torna indietro', next: 'home')]),
  }),
  onAction: (action) { /* navigate, prefill, … */ },
);

MaterialApp(
  builder: (context, child) => Chatbot(
    controller: chatbot,
    theme: const ChatbotTheme(optionShape: ChatbotOptionShape.row),
    child: child!,
  ),
);
```

Wrap any field you want the assistant to point at:

```dart
ChatbotHighlight(id: 'nome', child: TextField(...))
```

## Script rules

- `ChatbotOption.next == null` closes the chat.
- A step's `action` runs when the step is shown. An option's `action` runs when the option is tapped. Both go to `onAction`.
- An unknown step id throws an `ArgumentError`.

## Theme

`ChatbotTheme` settings, grouped by part:

| Part | Settings |
|---|---|
| Window | `windowColor`, `windowBorderColor`, `windowBorderWidth`, `windowRadius`, `windowShadowColor`, `windowShadowBlur`, `windowWidth`, `windowHeight` |
| Header | `headerColor`, `headerTitleColor`, `headerCloseColor`, `headerTitleSize`, `title` |
| Messages | `messageGap`, `messagePadding` |
| Bubbles | `assistantBubbleColor`, `assistantTextColor`, `userBubbleColor`, `userTextColor`, `bubbleRadius`, `bubbleTailRadius` |
| Options | `optionShape` (`pill`, `row`, `button`), `optionColor`, `optionBorderColor`, `optionBorderWidth`, `optionTextColor`, `optionRadius`, `optionPaddingH`, `optionPaddingV` |
| Help button | `helpButtonColor`, `helpIconColor`, `helpButtonRadius`, `helpButtonSize`, `helpIcon` |
| Highlight | `highlightColor`, `highlightWidth`, `highlightRadius` |
| Font | `fontFamily`, `regularWeight`, `strongWeight`, `textSize` |

The defaults match "Esempio 1" of the design. The design is in `design/local_chatbot.figcraft`: each of its "Assistente" variables maps to one of these settings.
