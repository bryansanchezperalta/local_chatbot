## 0.0.2

- Assistant messages appear one letter at a time; speed set by `ChatbotTheme.streamCharDuration` (`Duration.zero` = off). The list follows the typing only while it is scrolled to the end.
- The window has a fixed height (`ChatbotTheme.windowHeight`) and the message list scrolls.
- Screens can answer the chatbot themselves with `ChatbotHandlers` (`actions`, `checks`).
- `Chatbot.margin` and `Chatbot.gap` place the help button and the window freely.
- MIT license.
- Options can check that the user really did the step: `ChatbotOption.check` and `otherwise`, answered by `ChatbotController.onCheck`.
- Default UI strings are now English: title "Assistant", semantics labels "Open …" / "Close …".
- The chat window opens and closes with an animation: by default it grows out of the help button. Set `openDuration`, `openCurve`, `closeCurve` and `windowTransition` in `ChatbotTheme`.

## 0.0.1

- First version: script of pre-written steps, controller, chat window, help button, field highlight, full theme.
