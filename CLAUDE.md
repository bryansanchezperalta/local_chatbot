# local_chatbot: project memory

Public Flutter package, a personal project of the partner (not Aura). Public repository on the personal GitHub account, not `auraconsultants`. A single public repository: code and design together.

## Language
All written text in this repository is in English: code comments, doc comments, `.md` files, commit messages, UI default strings, test data. Talk to the partner in Italian, but never write Italian into a file.

## Brief (2026-11-06)
- A local assistant that replaces the FAQ and helps people use a program.
- No artificial intelligence: pre-written questions and answers, picked with buttons. No free text input.
- It opens from a button, asks what you want to do, takes you to the right screen and guides you step by step to the end.
- Used by gym-toolbox and other software: each app integrates it as a package.
- Everything customizable from the app that uses it: shapes, content, texts, actions, colors, fonts. No visual identity of its own, no logo.

## Design: status
- File: `design/local_chatbot.figcraft`, page "Sketch". The design file itself is still in Italian.
- Approved: dialogue map and proposal A (classic chat: window at bottom right, bubbles, options as buttons).
- Proposals B and C discarded and deleted.
- The "Altre domande" button became "Altri argomenti" (other topics): it opens another list of pre-written entries.
- Example used in the sketch: gym-toolbox, "Registrare un iscritto" (register a member).
- UI approved (2026-11-06), page "UI". Everything customizable, including the shape of the options: no style variants to pick from.
  - One design bound to the "Assistente" variables (colors, fonts, corners, borders, shadows, spacing, title, option shape).
  - "Opzione" component with property Forma = Pillola / Riga / Pulsante, bound to the variable Opzione/Forma.
  - The 3 rows are 3 example settings (modes Esempio 1/2/3), with the fonts Figtree, Roboto and PT Sans. At the bottom is the table "Cosa si può personalizzare".
  - Known limit: the Riga and Pulsante options are fixed at 216 wide and do not follow the variable Finestra/Larghezza.
- Project without a client: drafts are deleted right after approval.

## Code: status
- Flutter package 0.0.1 in `lib/`: `ChatbotScript`/`ChatbotStep`/`ChatbotOption` (script), `ChatbotController`, `Chatbot` (Help button + window at bottom right), `ChatbotHighlight`, `ChatbotHandlers`, `ChatbotTheme` (all settings of the design; default = Example 1).
- Assistant messages appear one letter at a time (stream style). Options appear only when the message is complete. Speed: `ChatbotTheme.streamCharDuration` (20 ms, `Duration.zero` = off). With "reduce motion" on, the text appears at once.
- The window opens and closes with an animation: by default it grows from the Help button and fades in (similar to Hero). Customize with `openDuration` (250 ms, `Duration.zero` = off), `openCurve`, `closeCurve` and `windowTransition` (replaces the whole animation). With "reduce motion" on it opens at once.
- The window has a fixed height (`ChatbotTheme.windowHeight`, 420) and the message list scrolls. The first messages sit at the top. While a message is typing the list follows the text, like AI chats, only if it is at the end: if the user scrolls away it stays still. Options appearing never scroll the list. Choosing an option turns the follow back on.
- In code the Riga and Pulsante options follow the window width: the design limit does not exist.
- An option can have a `check` (id) and `otherwise` (step): the host app answers with `onCheck` (true = done). If it fails, the chat goes to `otherwise` and the option's action does not run. The example checks that first and last name are filled in.
- A screen can answer the chatbot itself with `ChatbotHandlers` (`actions`, `checks`): they win over `onAction`/`onCheck` while the screen is on display. Found trying it on gym-toolbox: the chatbot sits above the Navigator and cannot see the screens.
- `Chatbot.margin` is `EdgeInsets` (right and bottom used), `Chatbot.gap` is the space between button and window. Found on gym-toolbox: the help button covered the floating action buttons.
- Default UI strings are English (`title` "Assistant", semantics labels "Open …"/"Close …").
- Flutter SDK on this computer: `~/flutter/bin/flutter` (not in PATH).
- `LICENSE` is MIT (2026, Bryan Sanchez Peralta).

## Method: TDD (decided 2026-11-06)
Every new development (feature, behavior change, bug fix) starts with the test:
1. **Red**: write the test of the wanted behavior and run it. It must fail for the right reason (the feature is missing or the behavior is wrong), not because of a syntax error.
2. **Green**: write the minimum code that makes that test pass. Run all tests.
3. **Refactor**: simplify the code, with tests always green.
- No code in `lib/` without a red test that requires it.
- A bug found is fixed by first writing a test that reproduces it (red).
- In the last message, say the test was red before and green after.
- Tests in `test/local_chatbot_test.dart`; for widgets use the `pumpChatbot` helper.
- Commands: `~/flutter/bin/flutter test` and `~/flutter/bin/flutter analyze`.
