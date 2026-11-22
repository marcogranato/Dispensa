# Requisiti — Dispensa

## Scopo

Gestire una dispensa alimentare: monitorare la quantità di cibo presente e le date di scadenza, per ottimizzare i costi e ridurre gli sprechi.

## Glossario

| Termine | Significato |
|---|---|
| **Dispensa** | L'insieme delle strutture di una casa. È l'unità che in futuro si condivide con altre persone. Si possono avere più Dispense. |
| **Ubicazione** | Dove si trova una struttura: cucina, cantina, salone, giardino… |
| **Struttura** | Frigorifero, congelatore, dispensa, estraibile, scaffale, ecc. |
| **Prodotto** | La "scheda" riutilizzabile: nome, marca, codice a barre, categoria, emoji, descrizione, note, etichette, immagine, valori predefiniti della confezione. Si riconosce da **nome + marca**. |
| **Categoria** | Classificazione dei prodotti in un albero di massimo 3 livelli: categoria ▸ sottocategoria ▸ tipologia (es. Pasta e riso ▸ Pasta secca ▸ Pasta di semola). |
| **Articolo** | L'oggetto fisico presente in una struttura: quantità, parti rimaste, date. Più articoli possono riferirsi allo stesso prodotto (es. tre cartoni di latte con scadenze diverse). |
| **Etichetta** | Hashtag (es. #senzaglutine) con un colore facoltativo, assegnato al Prodotto ed ereditato dai suoi articoli. |
| **Storico** | Articoli usciti dalla dispensa (consumati o buttati), conservati per statistiche su costi e sprechi. |

## Stato dello sviluppo

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | Modello dati; gestione di Dispense, Ubicazioni e Strutture | ✅ Completata |
| 2 | Articoli e Prodotti: aggiungere, modificare, spostare, prelevare, buttare, storico | ✅ Completata |
| 3 | Navigazione a schede ed elenco di tutti gli articoli; classificazione e dettagli dei prodotti (categorie, emoji); etichette, ricerca, filtri, ordinamento | ✅ Completata |
| 4 | Tabelle con colonne configurabili e filtri salvati | Da fare |
| 5 | Immagini e scanner di codici a barre/QR; più codici a barre per prodotto (da valutare) | Da fare |
| 6 | Notifiche locali per gli articoli in scadenza | Da fare |
| 7 | Sincronizzazione iCloud e condivisione (con account a pagamento) | Da fare |

### Fase 3: avanzamento

1. ✅ Ritocchi: date facoltative su una riga nel modulo dell'articolo; riga dell'articolo compatta (nome, parti e scadenza su una riga, due righe solo se non ci stanno).
2. ✅ Navigazione a schede (Strutture, Articoli, Prodotti, Storico), menu della dispensa nel titolo, elenco di tutti gli articoli, scheda del prodotto; navigazione affidabile sul Mac.
3. ✅ Classificazione e dettagli dei prodotti (al posto delle sole "icone dei prodotti"; si è scelta l'emoji):
   1. albero delle categorie (massimo 3 livelli) con la scheda della categoria;
   2. modulo del prodotto a sezioni: categoria, descrizione, note, emoji, tipo di parte; quantità totale e multipack calcolati;
   3. prodotti riconosciuti da nome + marca; categoria scelta anche nel modulo dell'articolo;
   4. Categorie (dalla scheda Prodotti) e Ubicazioni (dalla scheda Strutture) aperte come schermate, ognuna con la sua scheda;
   5. emoji davanti al nome nelle righe di articoli, prodotti, storico e categorie; selettore di emoji a griglia nei moduli;
   6. scheda Prodotti divisa per categoria principale e ricerca che trova anche le categorie.
4. ✅ Etichette, ricerca, filtri, ordinamento (deciso: un'etichetta è solo un hashtag, con il colore subito; filtri su tutte le date):
   1. etichette con colore, con la loro schermata (dalla scheda Prodotti) e il selettore nel modulo del prodotto;
   2. una sola ricerca per le tre schede: nome, marca, categoria, etichetta, codice e, per gli articoli, struttura; "#" cerca solo nelle etichette;
   3. filtri nelle schede Articoli e Storico;
   4. ordinamento in Articoli, Storico, Prodotti e nella scheda della struttura.

Prossima: la fase 4, da pianificare.

### Da provare a mano

Queste funzioni compilano e la loro logica è coperta da test, ma nessun test UI le usa:

- spostamento di alcune parti in un'altra struttura;
- azioni rapide scorrendo le righe e menu contestuali;
- selezione multipla nello storico e "Rimetti in dispensa" di un articolo con più parti;
- domanda sullo storico esistente quando lo si disattiva;
- selettore di emoji (foglio su iPhone, finestrella sul Mac, "Altra emoji" dalla tastiera);
- selettore delle etichette nel modulo del prodotto e palette dei colori;
- foglio dei filtri, in particolare le date "Dal/Al", e menu "Ordina" con i suoi criteri;
- tutta l'app su iPad (le schede possono diventare una barra laterale, come sul Mac).

Sul Mac la navigazione tra le schede e l'apertura dei dettagli sono coperte da un test UI dedicato (`NavigazioneMacUITests`), da rilanciare: dopo l'arrivo delle emoji nelle righe non è ancora stato eseguito. Il resto dell'app sul Mac va provato a mano, in particolare la navigazione di Categorie e Ubicazioni (clic sulle righe, "+", Indietro, cambio di scheda), "Elimina prodotto", la scheda Prodotti divisa per categoria, le etichette, i filtri e il menu "Ordina".

### Difetti noti

- Nel modulo dell'articolo, cambiando nome o marca, la categoria scelta a mano viene sostituita da quella del prodotto con lo stesso nome.

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
- L'app mostra una dispensa alla volta, in quattro schede: Strutture, Articoli, Prodotti, Storico (su iPhone barra in basso; su iPad e Mac barra laterale). Le ubicazioni si aprono come schermata da un pulsante nella scheda Strutture; ogni ubicazione ha la sua scheda con le strutture che contiene.
- La dispensa si cambia, crea, modifica ed elimina dal menu con il suo nome nel titolo (es. "Casa ▾"). L'app ricorda l'ultima dispensa aperta; una dispensa appena creata si apre subito.
- In tutti gli elenchi il click (o tocco) su una riga apre il dettaglio in sola lettura; la modifica è un'azione esplicita: pulsante "Modifica" nel dettaglio, menu contestuale o scorrimento della riga. Fa eccezione lo storico (il click seleziona, per eliminare più articoli insieme).

## Gestione Prodotti e Articoli

- Aggiungere, modificare, rimuovere articoli e spostarli da una struttura a un'altra.
- Quantità per parte (es. 1 kg, 1 l) e confezioni composte da più parti (es. scatola di biscotti con 6 pacchi, cassa di bottiglie).
- Prelievo **solo a parti intere** (es. 1 pacco su 6). Non si preleva una quantità parziale di una parte.
- Date opzionali e modificabili: inserimento (predefinita: oggi), produzione/confezionamento, scadenza.
- Una categoria facoltativa e uno o più hashtag (tramite il Prodotto).
- Codici a barre e QR code (scanner solo su iPhone/iPad, fase 5; su Mac inserimento manuale). Per ora il codice si scrive a mano nel prodotto.
- Immagine (priorità bassa, fase 5).

Decisioni prese:

- Aggiungendo un articolo, il prodotto si sceglie scrivendo il nome: vengono suggeriti i prodotti esistenti; se il nome è nuovo, il prodotto viene creato automaticamente con la confezione indicata come valori predefiniti.
- Si possono aggiungere più confezioni uguali in una volta (diventano articoli separati).
- Spostamento anche parziale: spostando solo alcune parti, la confezione si divide e le parti spostate diventano un nuovo articolo con le stesse date.
- Un Prodotto si può eliminare solo se non ha articoli presenti; i suoi articoli nello storico vengono eliminati insieme (con avviso).
- Gli articoli di una struttura sono all'inizio ordinati per scadenza (prima i più urgenti, senza data in fondo); l'ordine si può cambiare.
- La scheda Articoli mostra gli articoli di tutte le strutture, con la struttura in cui si trovano, ricerca, filtri e ordinamento; da lì si possono anche aggiungere articoli, scegliendo la struttura nel modulo.
- La scheda di un prodotto mostra categoria, marca, codice, confezione, descrizione, note e gli articoli presenti di quel prodotto con la loro struttura.
- Nel modulo dell'articolo le date facoltative (produzione, scadenza) stanno su una riga: "Aggiungi" se mancano, altrimenti la data e un pulsante per toglierla.
- Un articolo è "in scadenza" (arancione) quando mancano 3 giorni o meno, "scaduto" (rosso) quando la data è passata. Il numero di giorni diventerà un'impostazione nella fase 6. Lo stato è indicato anche da un'icona, non solo dal colore.

### Categorie e dettagli dei prodotti

- Un prodotto si riconosce da **nome + marca**: Penne rigate Barilla e Penne rigate De Cecco sono due prodotti diversi. Non possono esistere due prodotti con lo stesso nome e la stessa marca.
- Un prodotto nuovo con lo stesso nome di uno esistente ne prende l'emoji; nel modulo dell'articolo vengono proposti anche la sua categoria e il tipo di parte.
- Le categorie formano un albero di massimo 3 livelli (categoria ▸ sottocategoria ▸ tipologia). Il prodotto si collega al nodo più preciso; la categoria è facoltativa. Due categorie con lo stesso genitore non possono avere lo stesso nome.
- Categorie e prodotti possono avere un'emoji, scelta da una griglia o scritta a mano. Senza emoji si usa quella della categoria più vicina che ne ha una.
- La quantità totale della confezione e il fatto che sia un "multipack" (più parti) sono calcolati, mai salvati.
- Eliminando una categoria si eliminano anche le sue sottocategorie; i prodotti passano alla categoria superiore (o restano senza categoria).
- Le categorie si aprono dalla scheda Prodotti; la scheda di una categoria mostra sottocategorie e prodotti, compresi quelli delle sottocategorie.
- La scheda Prodotti è divisa per categoria principale, in ordine alfabetico, con "Senza categoria" in fondo; nella riga compare la sottocategoria.
- Rimandati: un albero di categorie preimpostato (a una fase successiva; per ora, solo nelle versioni di sviluppo, "Aggiungi categorie di prova"); più codici a barre per lo stesso prodotto (da valutare nella fase 5).

### Etichette, ricerca, filtri e ordinamento

- **Etichette:** il nome si salva senza "#" e senza spazi; due etichette della stessa dispensa non possono avere lo stesso nome (maiuscole e accenti non contano). Il colore è facoltativo (senza colore il gettone è grigio). Le etichette si gestiscono dalla scheda Prodotti e si assegnano nel modulo del prodotto; eliminandone una usata, l'app chiede conferma e la toglie dai prodotti.
- **Ricerca** (uguale nelle schede Articoli, Prodotti e Storico): trova il testo nel nome, nella marca, nella categoria del prodotto o in una superiore, nelle etichette e, per gli articoli, nel nome della struttura; il codice a barre va scritto per intero. Un testo che inizia con "#" cerca solo nelle etichette ("#cola" trova #colazione, non la Coca-Cola). Maiuscole e accenti non contano.
- **Filtri** (schede Articoli e Storico): strutture, tipo di struttura, categorie, etichette, stato di scadenza, date di inserimento, produzione e scadenza; nello storico anche esito (consumato o buttato) e data di uscita.
  - Dentro un gruppo basta una delle scelte (frigorifero O dispensa); tra gruppi devono valere tutte (frigorifero E scaduti).
  - Una categoria comprende le sue sottocategorie.
  - Le date si confrontano a giorni interi, estremi compresi; un articolo senza quella data è escluso.
  - Con filtri attivi, la prima riga dell'elenco li conta e permette di azzerarli.
- **Ordinamento** (pulsante "Ordina"): si sceglie il criterio e il verso.
  - Articoli: scadenza (iniziale, dalla più vicina), nome, data di inserimento, struttura. Scheda della struttura: gli stessi, tranne la struttura. Storico: data di uscita (iniziale, dalla più recente), nome, scadenza. Prodotti: nome (iniziale), data di creazione, articoli presenti; l'ordine vale dentro ogni sezione di categoria.
  - Le date mancanti (e gli articoli senza struttura) vanno sempre in fondo; a parità si ordina per scadenza e poi per nome.
  - Cambiando criterio, il verso torna quello naturale (date di uscita e di creazione dalla più recente, articoli presenti dal numero più alto, il resto in crescente).
- Filtri e ordine non si salvano: tornano quelli iniziali cambiando dispensa o chiudendo l'app. Filtri salvati e viste predefinite sono della fase 4.

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

Già disponibile (fase 3): elenco degli articoli di tutte le strutture (scheda Articoli); ricerca, filtri e ordinamento come descritti in "Etichette, ricerca, filtri e ordinamento".

Resta per la fase 4: colonne configurabili, filtri salvati e richiamabili, vista predefinita per ogni elenco, filtri anche nella scheda della struttura e nei Prodotti.

## Condivisione (futura, richiede account Apple a pagamento)

- Condividere una Dispensa tra persone (es. famiglia): chi la crea invita le altre persone e dà loro accesso.
- Dati salvati su iCloud e sincronizzati.
- Il modello dati è già compatibile con CloudKit e tutti i dati partono dalla Dispensa, che sarà l'oggetto condiviso. Da verificare se SwiftData supporta la condivisione o se servirà Core Data / CloudKit diretto.

## Aspetto

- App nativa per iPhone, iPad e Mac (versione minima iOS 26 / macOS 26, da iPhone 13 in su).
- Grafica coerente con le linee guida Apple (Human Interface Guidelines).
- Interfaccia in italiano, predisposta per altre lingue (catalogo `Localizable.xcstrings`).
