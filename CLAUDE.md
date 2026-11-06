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
- Step UI in corso, pagina "Proposta". Il socio ha chiesto che sia personalizzabile tutto, anche la forma delle opzioni: niente varianti di stile da scegliere.
  - Un solo design legato alle variabili "Assistente" (colori, font, angoli, bordi, ombre, spazi, titolo, forma opzione).
  - Componente "Opzione" con proprietà Forma = Pillola / Riga / Pulsante, legata alla variabile Opzione/Forma.
  - Le 3 righe sono 3 esempi di impostazioni (modi Esempio 1/2/3), con i font Figtree, Roboto e PT Sans. In fondo c'è la tabella "Cosa si può personalizzare". In attesa di approvazione.
