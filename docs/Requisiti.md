# Requisiti — Dispensa

## Scopo

Gestire una dispensa alimentare: monitorare la quantità di cibo presente e le date di scadenza, per ottimizzare i costi e ridurre gli sprechi.

## Glossario

| Termine | Significato |
|---|---|
| **Dispensa** | L'insieme delle strutture di una casa. È l'unità che in futuro si condivide con altre persone. Si possono avere più Dispense. |
| **Ubicazione** | Dove si trova una struttura: cucina, cantina, salone, giardino… |
| **Struttura** | Frigorifero, congelatore, dispensa, estraibile, scaffale, ecc. |
| **Prodotto** | La "scheda" riutilizzabile: nome, marca, codice a barre, etichette, immagine, valori predefiniti. |
| **Articolo** | L'oggetto fisico presente in una struttura: quantità, parti rimaste, date. Più articoli possono riferirsi allo stesso prodotto (es. tre cartoni di latte con scadenze diverse). |
| **Etichetta** | Categoria o hashtag, assegnata al Prodotto ed ereditata dai suoi articoli. |
| **Storico** | Articoli usciti dalla dispensa (consumati o buttati), conservati per statistiche su costi e sprechi. |

## Gestione Dispense e Strutture

- Aggiungere, modificare ed eliminare strutture di una Dispensa.
- Tipologie di struttura: frigorifero, congelatore, dispensa, estraibile, scaffale, altro (con nome libero).
- Caratteristiche di una struttura: numero di ripiani, numero di cassetti, note, ubicazione.
- Immagine della struttura (priorità bassa).

## Gestione Articoli

- Aggiungere, modificare, rimuovere articoli e spostarli da una struttura a un'altra.
- Quantità per parte (es. 1 kg, 1 l) e confezioni composte da più parti (es. scatola di biscotti con 6 pacchi, cassa di bottiglie).
- Prelievo **solo a parti intere** (es. 1 pacco su 6). Non si preleva una quantità parziale di una parte.
- Date opzionali e modificabili: inserimento (predefinita: data di inserimento nell'app), produzione/confezionamento, scadenza.
- Una o più categorie/hashtag (tramite il Prodotto).
- Codici a barre e QR code (scanner solo su iPhone/iPad; su Mac inserimento manuale).
- Immagine (priorità bassa).

- Spostamento anche parziale: spostando solo alcune parti, la confezione si divide e le parti spostate diventano un nuovo articolo con le stesse date.
- Un Prodotto si può eliminare solo se non ha articoli presenti; i suoi articoli nello storico vengono eliminati insieme (con avviso).
- Un articolo è "in scadenza" (evidenziato in arancione) quando mancano 3 giorni o meno; scaduto (rosso) quando la data è passata. Il numero di giorni diventerà un'impostazione nella fase 6.
- Si possono aggiungere più confezioni uguali in una volta (diventano articoli separati).

### Uscita dalla dispensa e storico

- Quando un articolo si svuota è **consumato**. Si può anche **buttare** indicando il motivo (scaduto, avariato, altro).
- Prelevando o buttando parti, quando le parti rimaste arrivano a 0 l'articolo esce: lo stato finale dipende dall'ultima operazione, mentre `partiButtate` conserva il conteggio esatto dello spreco.
- Gli articoli usciti vanno nello storico, se è abilitato. Un articolo uscito per errore si può rimettere in dispensa.
- Un articolo inserito per sbaglio si elimina senza passare dallo storico.
- Disattivando lo storico in una dispensa che ne ha già, l'app chiede se eliminare quello esistente.
- Lo storico si può cancellare in parte o del tutto.
- Lo storico si può disattivare (impostazione della Dispensa): in quel caso gli articoli usciti vengono eliminati.

## Visualizzazione e filtri

- Tutti i dati sono mostrati come elenchi.
- Elenco di tutte le strutture; articoli di tutte le strutture, di una o di più strutture.
- Filtri per tipologia, etichetta e date (tutti i campi data).
- Ordinamento degli elenchi.
- Colonne configurabili (mostrare, nascondere, spostare). Su iPad e Mac si usa una tabella; su iPhone si scelgono le informazioni mostrate in ogni riga.
- Filtri salvati e richiamabili; una vista predefinita per ogni tipo di elenco.
- Ricerca per nome, etichetta, codice.

## Condivisione (futura, richiede account Apple a pagamento)

- Condividere una Dispensa tra persone (es. famiglia): chi la crea invita le altre persone e dà loro accesso.
- Dati salvati su iCloud e sincronizzati.
- Il modello dati è già compatibile con CloudKit e tutti i dati partono dalla Dispensa, che sarà l'oggetto condiviso. Da verificare se SwiftData supporta la condivisione o se servirà Core Data / CloudKit diretto.

## Aspetto

- App nativa per iPhone, iPad e Mac.
- Grafica coerente con le linee guida Apple (Human Interface Guidelines).

## Fasi di sviluppo

1. Modello dati; gestione di Dispense, Ubicazioni e Strutture.
2. Articoli e Prodotti: aggiungere, modificare, spostare, prelevare, storico.
3. Etichette, ricerca, filtri, ordinamento.
4. Tabelle con colonne configurabili e filtri salvati.
5. Immagini e scanner di codici a barre/QR.
6. Notifiche locali per gli articoli in scadenza.
7. Sincronizzazione iCloud e condivisione (con account a pagamento).
