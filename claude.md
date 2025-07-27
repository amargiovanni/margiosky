# Progetto: "SkyIvory" - Un client Bluesky per iOS ispirato a Ivory

Questo documento contiene le specifiche per lo sviluppo di un'applicazione iOS nativa utilizzando Flutter. L'obiettivo è creare un client per il social network Bluesky che replichi fedelmente l'interfaccia utente (UI) e l'esperienza utente (UX) dell'acclamata app "Ivory" di Tapbots.

## 1. Panoramica e Obiettivi

*   **Piattaforma Target:** iOS (iPhone).
*   **Framework:** Flutter.
*   **Servizio Backend:** Bluesky Social (protocollo AT).
*   **Ispirazione UI/UX:** Ivory for Mastodon di Tapbots [1].
*   **Obiettivo primario:** Offrire agli utenti di Bluesky un'esperienza premium, veloce e curata nei minimi dettagli, simile a quella che Ivory offre per Mastodon [2].

## 2. Stack Tecnologico

L'applicazione dovrà essere sviluppata interamente in Flutter. Per l'interazione con il protocollo AT e le API di Bluesky, si dovranno utilizzare i seguenti pacchetti Dart ufficiali e altamente raccomandati:

*   **`bluesky`**: Il pacchetto principale per interagire con tutti gli endpoint dell'API di Bluesky (`app.bsky.*`) [3]. Fornisce modelli di dati type-safe e metodi per tutte le operazioni necessarie.
*   **`bluesky_text`**: Un pacchetto di supporto essenziale per analizzare e creare "facets" (rich text) nei post. Rileverà automaticamente menzioni, link e hashtag, semplificando la creazione di post formattati [4][5].
*   **`atproto`**: Dipendenza del pacchetto `bluesky`, gestisce le funzionalità di base del protocollo AT [5].

## 3. Design e User Experience (Ispirato a Ivory)

L'interfaccia deve essere una replica quasi identica di Ivory, prestando attenzione ai seguenti aspetti [6]:

*   **Estetica Pulita e Minimale:** Spazi bianchi generosi, tipografia leggibile e un design che non distrae dal contenuto.
*   **Barra di Navigazione Inferiore (Tab Bar):** La navigazione principale avverrà tramite una tab bar inferiore con icone per le sezioni chiave:
    *   Timeline
    *   Menzioni
    *   Ricerca
    *   Profilo Utente
*   **Scrolling Fluido:** Le performance di scrolling della timeline devono essere eccezionali, senza scatti o "salti" di posizione, una caratteristica distintiva di Ivory [7].
*   **Suoni e Feedback Aptico:** Implementare suoni discreti e feedback aptici per azioni comuni (like, refresh, etc.), un altro marchio di fabbrica di Tapbots.
*   **Temi:** Offrire almeno un tema chiaro e uno scuro, con la possibilità di passare automaticamente in base alle impostazioni di sistema.

## 4. Implementazione delle Funzionalità (Passo-Passo)

### 4.1. Autenticazione Sicura con App Password

Bluesky utilizza un sistema di "App Password" per consentire l'accesso a client di terze parti senza esporre la password principale dell'utente [8][9].

*   **Flusso di Login:**
    1.  L'utente inserisce il proprio handle Bluesky (es. `nomeutente.bsky.social`).
    2.  L'utente inserisce una **App Password** generata dalle impostazioni del suo account Bluesky [10][11].
    3.  L'app utilizza la funzione `createSession` del pacchetto `bluesky` per autenticarsi [12][4].
    4.  La sessione (che include i token JWT) deve essere salvata in modo sicuro sul dispositivo per gli accessi futuri.

### 4.2. Timeline Principale ("Following")

Questa è la schermata principale dell'app.

*   **Fetch dei Dati:** Utilizzare l'endpoint `app.bsky.feed.getTimeline` per recuperare la timeline dell'utente autenticato [13]. La timeline è un feed in ordine cronologico inverso dei post degli account seguiti [14].
*   **Paginazione:** Implementare l'infinite scrolling. L'API `getTimeline` restituisce un `cursor` che deve essere utilizzato nella richiesta successiva per caricare i post più vecchi [14].
*   **Visualizzazione Post:** Ogni cella della timeline deve mostrare l'avatar dell'autore, il nome, l'handle, il testo del post e i contatori per risposte, repost e like.

### 4.3. Visualizzazione dei Profili Utente

Quando un utente tocca un avatar o un nome utente, deve essere presentata la schermata del profilo.

*   **Fetch dei Dati:** Utilizzare `app.bsky.actor.getProfile` per ottenere i dettagli di un singolo attore (utente) [15][16].
*   **Componenti della Schermata:**
    *   Immagine di copertina e avatar.
    *   Nome visualizzato, handle.
    *   Biografia dell'utente.
    *   Statistiche: numero di post, follower, following.
    *   Pulsanti per "Seguire" / "Non seguire più".
    *   Una timeline dei post specifici di quell'utente (usando `app.bsky.feed.getAuthorFeed`).

### 4.4. Interazioni con i Post

Le azioni principali devono essere facilmente accessibili da ogni post.

*   **Like e Repost:** Utilizzare i metodi dedicati del SDK di Bluesky, come `like` e `repost`, che gestiscono la creazione dei record ATProto corrispondenti [17].
*   **Citazione (Quote Post):** Per citare un post, è necessario creare un nuovo post che contenga un "embed". L'embed deve essere di tipo `app.bsky.embed.record` e contenere l'URI e il CID del post che si sta citando [18]. L'API `app.bsky.feed.getQuotes` può essere usata per vedere chi ha citato un post [19].
*   **Risposta (Reply):** Una risposta è un nuovo post che contiene un riferimento (`reply`) al post padre e alla radice della conversazione [18].

### 4.5. Funzionalità Aggiuntive Ispirate a Ivory

*   **Visualizzazione Media:** Supporto completo per la visualizzazione di immagini singole e multiple allegate ai post.
*   **Filtri e Mute:** Implementare un potente sistema di filtri, una delle feature più amate di Ivory [20]. Permettere agli utenti di silenziare utenti, parole chiave (con supporto opzionale per espressioni regolari) e hashtag.
*   **Supporto Multi-Account:** L'architettura dell'app deve prevedere la possibilità di gestire più account Bluesky contemporaneamente [1].

## 5. Struttura del Codice e Best Practice

*   **State Management:** Utilizzare un approccio di gestione dello stato robusto come BLoC o Riverpod per gestire lo stato dell'applicazione in modo pulito e scalabile.
*   **Architettura:** Adottare un'architettura pulita (Clean Architecture) per separare la logica di business dall'interfaccia utente e dai servizi dati.
*   **Widget Riutilizzabili:** Creare componenti widget personalizzati e riutilizzabili per elementi come le celle dei post, i pulsanti di interazione e le viste del profilo, per garantire coerenza e manutenibilità.
