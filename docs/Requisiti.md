# Requisiti — Dispensa

## Scopo

Gestire una dispensa alimentare: monitorare la quantità di cibo presente e le date di scadenza, per ottimizzare i costi e ridurre gli sprechi.

## Glossario

| Termine | Significato |
|---|---|
| **Dispensa** | L'insieme delle strutture di una casa. È l'unità che in futuro si condivide con altre persone. Si possono avere più Dispense. |
| **Ubicazione** | Dove si trova una struttura: cucina, cantina, salone, giardino… |
| **Struttura** | Frigorifero, congelatore, dispensa, estraibile, scaffale, ecc. |
| **Prodotto** | La "scheda" riutilizzabile: nome, marca, codice a barre, etichette, immagine, valori predefiniti della confezione. |
| **Articolo** | L'oggetto fisico presente in una struttura: quantità, parti rimaste, date. Più articoli possono riferirsi allo stesso prodotto (es. tre cartoni di latte con scadenze diverse). |
| **Etichetta** | Categoria o hashtag, assegnata al Prodotto ed ereditata dai suoi articoli. |
| **Storico** | Articoli usciti dalla dispensa (consumati o buttati), conservati per statistiche su costi e sprechi. |

## Stato dello sviluppo

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | Modello dati; gestione di Dispense, Ubicazioni e Strutture | ✅ Completata |
| 2 | Articoli e Prodotti: aggiungere, modificare, spostare, prelevare, buttare, storico | ✅ Completata |
| 3 | Navigazione a schede ed elenco di tutti gli articoli; icone dei prodotti; etichette, ricerca, filtri, ordinamento | In corso |
| 4 | Tabelle con colonne configurabili e filtri salvati | Da fare |
| 5 | Immagini e scanner di codici a barre/QR | Da fare |
| 6 | Notifiche locali per gli articoli in scadenza | Da fare |
| 7 | Sincronizzazione iCloud e condivisione (con account a pagamento) | Da fare |

### Fase 3: avanzamento

1. ✅ Ritocchi: date facoltative su una riga nel modulo dell'articolo; riga dell'articolo compatta (nome, parti e scadenza su una riga, due righe solo se non ci stanno).
2. ✅ Navigazione a schede (Strutture, Articoli, Prodotti, Storico), menu della dispensa nel titolo, elenco di tutti gli articoli, scheda del prodotto; navigazione affidabile sul Mac.
3. Icone dei prodotti — da fare. Da decidere: emoji (proposta) o simboli di sistema (SF Symbols).
4. Etichette, ricerca, filtri, ordinamento — da fare. Da decidere: categoria e hashtag distinti o un solo tipo; colore subito o dopo; filtri su tutte le date o solo sulla scadenza.

### Da provare a mano

Queste funzioni compilano e la loro logica è coperta da test, ma nessun test UI le usa:

- spostamento di alcune parti in un'altra struttura;
- azioni rapide scorrendo le righe e menu contestuali;
- selezione multipla nello storico e "Rimetti in dispensa" di un articolo con più parti;
- domanda sullo storico esistente quando lo si disattiva;
- tutta l'app su iPad (le schede possono diventare una barra laterale, come sul Mac).

Sul Mac la navigazione tra le schede e l'apertura dei dettagli sono coperte da un test UI dedicato (`NavigazioneMacUITests`); il resto dell'app sul Mac va provato a mano.

## Gestione Dispense, Ubicazioni e Strutture

- Più Dispense; per ognuna si può attivare o disattivare lo storico.
- Aggiungere, modificare ed eliminare strutture di una Dispensa.
- Tipologie di struttura: frigorifero, congelatore, dispensa, estraibile, scaffale, altro (con nome libero).
- Caratteristiche di una struttura: numero di ripiani, numero di cassetti, note, ubicazione.
- Immagine della struttura (priorità bassa, fase 5).

Decisioni prese:

- Le strutture sono raggruppate per ubicazione; quelle senza ubicazione sono in fondo.
- Se non si indica il nome, la struttura prende il nome del tipo (es. "Frigorifero").
- Le ubicazioni non possono avere nomi duplicati (maiuscole e accenti non contano); vengono suggerite quelle comuni.
- Eliminando un'ubicazione, le sue strutture restano senza ubicazione.
- Eliminando una struttura, i suoi articoli presenti vengono eliminati; quelli nello storico restano.
- Eliminando una dispensa si elimina tutto il suo contenuto.
- Al primo avvio non si creano dati automaticamente (eviterà duplicati con la sincronizzazione).
- L'app mostra una dispensa alla volta, in quattro schede: Strutture, Articoli, Prodotti, Storico (su iPhone barra in basso; su iPad e Mac barra laterale). Le ubicazioni si gestiscono da un pulsante nella scheda Strutture.
- La dispensa si cambia, crea, modifica ed elimina dal menu con il suo nome nel titolo (es. "Casa ▾"). L'app ricorda l'ultima dispensa aperta; una dispensa appena creata si apre subito.
- In tutti gli elenchi il click (o tocco) su una riga apre il dettaglio in sola lettura; la modifica è un'azione esplicita: pulsante "Modifica" nel dettaglio, menu contestuale o scorrimento della riga. Fanno eccezione lo storico (il click seleziona, per eliminare più articoli insieme) e le ubicazioni (si rinominano dal menu contestuale).

## Gestione Prodotti e Articoli

- Aggiungere, modificare, rimuovere articoli e spostarli da una struttura a un'altra.
- Quantità per parte (es. 1 kg, 1 l) e confezioni composte da più parti (es. scatola di biscotti con 6 pacchi, cassa di bottiglie).
- Prelievo **solo a parti intere** (es. 1 pacco su 6). Non si preleva una quantità parziale di una parte.
- Date opzionali e modificabili: inserimento (predefinita: oggi), produzione/confezionamento, scadenza.
- Una o più categorie/hashtag (tramite il Prodotto, fase 3).
- Codici a barre e QR code (scanner solo su iPhone/iPad, fase 5; su Mac inserimento manuale). Per ora il codice si scrive a mano nel prodotto.
- Immagine (priorità bassa, fase 5).

Decisioni prese:

- Aggiungendo un articolo, il prodotto si sceglie scrivendo il nome: vengono suggeriti i prodotti esistenti; se il nome è nuovo, il prodotto viene creato automaticamente con la confezione indicata come valori predefiniti.
- Si possono aggiungere più confezioni uguali in una volta (diventano articoli separati).
- Spostamento anche parziale: spostando solo alcune parti, la confezione si divide e le parti spostate diventano un nuovo articolo con le stesse date.
- Un Prodotto si può eliminare solo se non ha articoli presenti; i suoi articoli nello storico vengono eliminati insieme (con avviso).
- Gli articoli di una struttura sono ordinati per scadenza (prima i più urgenti, senza data in fondo).
- La scheda Articoli mostra gli articoli di tutte le strutture, ordinati per scadenza, con la struttura in cui si trovano e la ricerca per nome; da lì si possono anche aggiungere articoli, scegliendo la struttura nel modulo.
- La scheda di un prodotto mostra marca, codice, confezione e gli articoli presenti di quel prodotto con la loro struttura.
- Nel modulo dell'articolo le date facoltative (produzione, scadenza) stanno su una riga: "Aggiungi" se mancano, altrimenti la data e un pulsante per toglierla.
- Un articolo è "in scadenza" (arancione) quando mancano 3 giorni o meno, "scaduto" (rosso) quando la data è passata. Il numero di giorni diventerà un'impostazione nella fase 6. Lo stato è indicato anche da un'icona, non solo dal colore.

### Uscita dalla dispensa e storico

- Quando un articolo si svuota è **consumato**. Si può anche **buttare** indicando il motivo (scaduto, avariato, altro); il motivo proposto è "Scaduto" se la data è passata.
- Prelevando o buttando parti, quando le parti rimaste arrivano a 0 l'articolo esce: lo stato finale dipende dall'ultima operazione, mentre il conteggio delle parti buttate conserva lo spreco esatto.
- Gli articoli usciti vanno nello storico, se è abilitato; altrimenti vengono eliminati.
- Un articolo uscito per errore si può rimettere in dispensa scegliendo parti e struttura (direttamente, se ha una sola parte e la sua struttura esiste ancora).
- Un articolo inserito per sbaglio si elimina senza passare dallo storico.
- Lo storico si può cancellare in parte (singoli articoli o selezione multipla) o del tutto.
- Disattivando lo storico in una dispensa che ne ha già, l'app chiede se eliminare quello esistente o conservarlo.

## Visualizzazione e filtri (fasi 3–4)

- Tutti i dati sono mostrati come elenchi.
- Elenco di tutte le strutture; articoli di tutte le strutture, di una o di più strutture.
- Filtri per tipologia, etichetta e date (tutti i campi data).
- Ordinamento degli elenchi.
- Colonne configurabili (mostrare, nascondere, spostare). Su iPad e Mac si usa una tabella; su iPhone si scelgono le informazioni mostrate in ogni riga.
- Filtri salvati e richiamabili; una vista predefinita per ogni tipo di elenco.
- Ricerca per nome, etichetta, codice.

Già disponibile: elenco degli articoli di tutte le strutture (scheda Articoli) con ricerca per nome; ricerca per nome, marca o codice nel catalogo prodotti; ricerca per nome nello storico.

## Condivisione (futura, richiede account Apple a pagamento)

- Condividere una Dispensa tra persone (es. famiglia): chi la crea invita le altre persone e dà loro accesso.
- Dati salvati su iCloud e sincronizzati.
- Il modello dati è già compatibile con CloudKit e tutti i dati partono dalla Dispensa, che sarà l'oggetto condiviso. Da verificare se SwiftData supporta la condivisione o se servirà Core Data / CloudKit diretto.

## Aspetto

- App nativa per iPhone, iPad e Mac (versione minima iOS 26 / macOS 26, da iPhone 13 in su).
- Grafica coerente con le linee guida Apple (Human Interface Guidelines).
- Interfaccia in italiano, predisposta per altre lingue (catalogo `Localizable.xcstrings`).
