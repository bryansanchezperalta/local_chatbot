# local_chatbot: memoria di progetto

Package Flutter pubblico, progetto personale del socio (non Aura). Repository pubblico sull'account GitHub personale, non `auraconsultants`. Un solo repository pubblico: codice e design insieme.

## Brief (2026-11-06)
- Assistente locale che sostituisce le domande frequenti e aiuta a usare un programma.
- Senza intelligenza artificiale: domande e risposte già scritte, scelte con i pulsanti. Non si scrive testo libero.
- Si apre da un pulsante, chiede cosa vuoi fare, porta alla schermata giusta e guida passo per passo fino alla fine.
- Lo usano gym-toolbox e altri software: ogni app lo integra come package.
- Tutto personalizzabile dall'app che lo usa: forme, contenuti, testi, azioni, colori, font. Nessuna identità visiva propria, nessun logo.

## Design: stato
- File: `design/local_chatbot.figcraft`, pagina "Sketch".
- Approvato: mappa del dialogo e proposta A (chat classica: finestra in basso a destra, bolle, opzioni come pulsanti).
- Proposte B e C scartate ed eliminate.
- Il pulsante "Altre domande" è diventato "Altri argomenti": apre un altro elenco di voci già scritte.
- Esempio usato nello sketch: gym-toolbox, "Registrare un iscritto".
- UI approvata (2026-11-06), pagina "UI". Tutto personalizzabile, anche la forma delle opzioni: niente varianti di stile da scegliere.
  - Un solo design legato alle variabili "Assistente" (colori, font, angoli, bordi, ombre, spazi, titolo, forma opzione).
  - Componente "Opzione" con proprietà Forma = Pillola / Riga / Pulsante, legata alla variabile Opzione/Forma.
  - Le 3 righe sono 3 esempi di impostazioni (modi Esempio 1/2/3), con i font Figtree, Roboto e PT Sans. In fondo c'è la tabella "Cosa si può personalizzare".
  - Limite noto: le opzioni Riga e Pulsante sono larghe 216 fisse e non seguono la variabile Finestra/Larghezza.
- Progetto senza cliente: le bozze si eliminano subito dopo l'approvazione.

## Codice: stato
- Package Flutter 0.0.1 in `lib/`: `ChatbotScript`/`ChatbotStep`/`ChatbotOption` (copione), `ChatbotController`, `Chatbot` (pulsante Aiuto + finestra in basso a destra), `ChatbotHighlight`, `ChatbotTheme` (tutte le impostazioni del design; default = Esempio 1).
- I messaggi dell'assistente compaiono una lettera alla volta (stile stream). Le opzioni appaiono solo a messaggio finito. Velocità: `ChatbotTheme.streamCharDuration` (20 ms, `Duration.zero` = spento). Con "riduci animazioni" attivo il testo appare subito.
- La finestra si apre e si chiude con un'animazione: per default cresce dal pulsante Aiuto e appare in dissolvenza (simile a Hero). Si personalizza con `openDuration` (250 ms, `Duration.zero` = spento), `openCurve`, `closeCurve` e `windowTransition` (sostituisce tutta l'animazione). Con "riduci animazioni" attivo si apre subito.
- La finestra ha altezza fissa (`ChatbotTheme.windowHeight`, 420) e la lista dei messaggi scorre. I primi messaggi stanno in alto. Quando la lista è lunga resta visibile l'ultimo messaggio.
- Nel codice le opzioni Riga e Pulsante seguono la larghezza della finestra: il limite del design non c'è.
- Flutter SDK su questo computer: `~/flutter/bin/flutter` (non nel PATH).
- `LICENSE` è ancora il segnaposto di `flutter create`: la licenza va scelta dal socio.

## Metodo: TDD (deciso 2026-11-06)
Ogni nuovo sviluppo (funzione, modifica di comportamento, correzione di un errore) si fa con il test per primo:
1. **Rosso**: si scrive il test del comportamento voluto e lo si esegue. Deve fallire per il motivo giusto (manca la funzione o il comportamento è sbagliato), non per un errore di sintassi.
2. **Verde**: si scrive il minimo codice che fa passare quel test. Si eseguono tutti i test.
3. **Pulizia**: si semplifica il codice, con i test sempre verdi.
- Non si scrive codice in `lib/` senza un test rosso che lo richieda.
- Un errore trovato si corregge scrivendo prima un test che lo riproduce (rosso).
- Nell'ultimo messaggio si dice che il test era rosso prima e verde dopo.
- Test in `test/local_chatbot_test.dart`; per i widget si usa l'helper `pumpChatbot`.
- Comandi: `~/flutter/bin/flutter test` e `~/flutter/bin/flutter analyze`.
