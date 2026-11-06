# local_chatbot

A local assistant for Flutter apps that replaces an FAQ and walks people through a task step by step. It uses no AI and has no free-text input. The app writes the questions and answers in advance, and the user picks answers with buttons.

The package has no look of its own. Every colour, font, corner, border, shadow, spacing and the shape of the options comes from `ChatbotTheme`.

## Use

```dart
final chatbot = ChatbotController(
  script: const ChatbotScript(start: 'home', steps: {
    'home': ChatbotStep(message: 'Hi! What do you want to do?', options: [
      ChatbotOption('Register a member', next: 'card'),
      ChatbotOption('Other topics', next: 'other'),
    ]),
    'card': ChatbotStep(
      message: 'I opened "New member". Does the member have a card?',
      action: 'open:new_member', // your app opens the screen
      options: [ChatbotOption('Yes', next: 'name'), ChatbotOption('No', next: 'name')],
    ),
    'name': ChatbotStep(
      message: 'Write first and last name as on the ID.',
      highlight: 'name', // outlines ChatbotHighlight(id: 'name')
      options: [ChatbotOption('Done, next', next: 'end')],
    ),
    'end': ChatbotStep(message: 'Done!', options: [ChatbotOption('Close')]),
    'other': ChatbotStep(message: '…', options: [ChatbotOption('Go back', next: 'home')]),
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
ChatbotHighlight(id: 'name', child: TextField(...))
```

## Script rules

- `ChatbotOption.next == null` closes the chat.
- A step's `action` runs when the step is shown. An option's `action` runs when the option is tapped. Both go to `onAction`.
- An option's `check` asks `onCheck` whether the user really did the step. If `onCheck` returns `false`, the chat goes to `otherwise` instead of `next`, and the option's `action` does not run. `check` and `otherwise` go together. A `check` without `onCheck` throws a `StateError`.

```dart
ChatbotOption('Done, next', next: 'end', check: 'name_filled', otherwise: 'name_missing'),
// …
onCheck: (check) => check == 'name_filled' && nameField.text.trim().isNotEmpty,
```

- An unknown step id throws an `ArgumentError`.

## Screens that answer

`Chatbot` sits above the app's screens and cannot see them. A screen can answer for itself while it is on display: wrap it in `ChatbotHandlers`. Its `actions` and `checks` win over `onAction` and `onCheck`, and stop when the screen leaves the tree.

```dart
ChatbotHandlers(
  actions: {'open:new_member': () => Navigator.push(context, newMemberRoute)},
  checks: {'name_filled': () => nameField.text.trim().isNotEmpty},
  child: ...,
)
```

## Position

`margin` sets the help button's distance from the right and bottom edges, for example to clear a floating action button. `gap` is the space between the button and the window.

```dart
Chatbot(margin: const EdgeInsets.only(right: 16, bottom: 88), gap: 16, ...)
```

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
| Animation | `streamCharDuration`, `openDuration`, `openCurve`, `closeCurve`, `windowTransition` |
| Highlight | `highlightColor`, `highlightWidth`, `highlightRadius` |
| Font | `fontFamily`, `regularWeight`, `strongWeight`, `textSize` |

By default the window grows out of the help button and fades in. `windowTransition` replaces that animation; it gets the open animation (0 closed, 1 open), the centre of the help button and the window:

```dart
ChatbotTheme(
  openDuration: const Duration(milliseconds: 300),
  windowTransition: (animation, origin, window) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
    child: window,
  ),
)
```

With "reduce motion" on, the window opens and closes at once.

The defaults match "Example 1" of the design. The design is in `design/local_chatbot.figcraft`: each of its "Assistente" variables maps to one of these settings.
