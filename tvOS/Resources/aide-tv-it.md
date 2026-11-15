# Per iniziare

## Benvenuti {#tv-bienvenue}

Kastideo è un **lettore**: non fornisce alcun canale, film o abbonamento. Aggiungete la vostra sorgente, poi tutto si comanda con il telecomando.

La schermata iniziale mostra grandi riquadri **Diretta**, **Film** e **Serie** (e **I miei video** se avete un server Jellyfin, Emby o Plex), poi dei pulsanti: **Riprendi**, **Recenti**, **Preferiti**, **Guida TV**, **Cerca**, **Impostazioni** e **Aiuto**. Le stesse sezioni sono nella barra in alto.

> Questo aiuto è specifico per Apple TV. La guida completa di Kastideo (Mac, iPhone, iPad, Windows, Linux, Android) si consulta nell'app su quei dispositivi.

## Aggiungere una sorgente {#tv-sources}

Digitare un indirizzo e una password con il telecomando è scomodo: Kastideo propone tre soluzioni.

1. **Da un telefono (codice QR)**: **Impostazioni > Sorgenti > Aggiungi da un telefono**. Inquadrate il codice QR con un telefono o aprite l'indirizzo mostrato su un computer della stessa rete Wi-Fi, compilate il modulo e inserite il **codice a 4 cifre** visualizzato sullo schermo. Questa schermata deve restare aperta durante l'inserimento.
2. **Da un iPhone o un iPad**: in Kastideo sull'iPhone, **Impostazioni > Backup > Invia all'Apple TV** trasmette in un colpo solo sorgenti, preferiti e impostazioni (stessa rete Wi-Fi, stesso codice a 4 cifre).
3. **Con la tastiera**: **Impostazioni > Sorgenti > Aggiungi una sorgente con la tastiera…**

Tipi di sorgenti: abbonamento **Xtream Codes**, playlist **M3U** (indirizzo) e server **Jellyfin, Emby, Plex** (sezione **I miei video**). La sincronizzazione iCloud non esiste su Apple TV.

Per modificare, aggiornare o eliminare una sorgente: **Impostazioni > Sorgenti**, poi la sorgente.

# Usare Kastideo

## Il telecomando {#tv-telecommande}

- **Superficie touch / frecce**: spostarsi; **clic**: confermare.
- **Tasto Menu (indietro)**: tornare indietro; nel lettore interrompe la riproduzione.
- **Riproduci / Pausa**: mette in pausa o riprende.
- **Pressione prolungata su una locandina o un canale**: apre un piccolo menu (aggiungere o rimuovere dai preferiti). Su un episodio: segnare come visto o non visto.
- **Nel lettore**: ↑ / ↓ cambiano canale in diretta, ← torna indietro di 10 s e → avanza di 30 s in un film o un episodio, un **clic** apre le opzioni.

## Diretta e zapping {#tv-direct}

Aprite **Diretta**: i canali sono ordinati per categoria (pulsante **Categoria**) e il pulsante di visualizzazione sceglie l'interfaccia **Classica**, **Cinema** o **TV**. L'interfaccia **TV** funziona come un televisore: zapping per numero e ultimo canale avviato all'apertura (regolabile).

Durante la riproduzione, ↑ / ↓ cambiano canale. In base a **Impostazioni > Riproduzione > Zapping**, un clic conferma la scelta nell'elenco (**con conferma**) oppure il cambio è **immediato**. Nelle opzioni del lettore: **Ultimo canale** (ritorno al precedente) e **Vai al canale n.…**.

## Guida TV e replay {#tv-guide}

La scheda **Guida TV** mostra una griglia di 3 ore. Fate clic su un programma: **Guarda il canale**, oppure **Rivedi questo programma** quando il fornitore conserva le trasmissioni passate (replay). L'impostazione **Impostazioni > Guida TV > All'apertura della guida** sceglie tra **Adesso** e **Ultima posizione**.

> La guida proviene dal fornitore; se è incompleta si usa una guida di riserva.

## Film e serie {#tv-films}

**Film** e **Serie** appaiono in griglia **Classica** o in **Cinema** (banner e righe per categoria). Fate clic su una locandina per aprire la scheda: trama e cast (con una chiave TMDB), poi **Riproduci**. Per una serie scegliete stagione ed episodio; l'episodio successivo può partire automaticamente.

La **ricerca** cerca tra canali, film e serie.

## Il lettore {#tv-lecteur}

Un **clic** durante la riproduzione apre le **Opzioni**:

- aggiungere o rimuovere dai **preferiti**;
- **Timer di spegnimento**: interrompe la riproduzione dopo alcuni minuti;
- **Tracce audio** e **Sottotitoli**;
- **Velocità di riproduzione** (film ed episodi);
- in diretta: **Ultimo canale** e **Vai al canale n.**;
- per una serie: **Episodio successivo**.

Un banner informativo appare per qualche secondo (canale, programma in corso).

## Preferiti, ripresa e «visto» {#tv-favoris}

- **Preferiti**: pressione prolungata su una locandina o un canale, oppure le **Opzioni** del lettore. L'elenco è nel pulsante **Preferiti** della schermata iniziale.
- **Riprendi**: film ed episodi iniziati riprendono da dove vi eravate fermati (regolabile in **Impostazioni > Riproduzione**). Con Jellyfin, Emby e Plex la ripresa è condivisa con il server.
- **Visto**: un episodio visto è segnato; pressione prolungata per cambiare.
- **Recenti**: gli ultimi contenuti guardati.

# Impostazioni

## Lingua e visualizzazione {#tv-reglages}

- **Lingua**: **Impostazioni > Lingua dell'app**. «Sistema» segue la lingua dell'Apple TV; potete scegliere francese, inglese, spagnolo, tedesco, italiano, portoghese (Portogallo) o portoghese (Brasile). Il cambio è immediato.
- **Pagina iniziale**: per Diretta, Film e Serie, la prima categoria, i preferiti, i recenti, l'ultima consultata o una categoria precisa.
- **Visualizzazione**: Classica, Cinema o TV, separatamente per diretta, film e serie.
- **Categorie**: mostrare o nascondere categorie; canali per adulti (nascosti per impostazione predefinita).
- **Riproduzione**: zapping, **Buffer** (Veloce, Bilanciato, Stabile: scegliete Stabile se l'immagine a scatti), ripresa dei film e decodifica software.

## Locandine e trame (TMDB) {#tv-tmdb}

Locandine, trame, cast e tendenze provengono da **TMDB**, un servizio gratuito. Serve una **chiave API** personale: create un account gratuito su themoviedb.org, aprite **Impostazioni > API**, poi inserite la chiave in **Impostazioni > TMDB**. Senza chiave, Kastideo funziona con le informazioni del fornitore.

# Risoluzione dei problemi

## Se un canale non parte {#tv-depannage}

1. Attendete qualche secondo: alcuni canali impiegano tempo ad avviarsi.
2. Provate un altro canale, poi tornate indietro.
3. Il vostro abbonamento potrebbe consentire **una sola connessione alla volta**: chiudete Kastideo sugli altri dispositivi.
4. Disattivate un'eventuale **VPN** sulla rete.
5. Immagine bloccata o a scatti: **Impostazioni > Riproduzione > Decodifica sempre via software**, oppure **Buffer: Stabile**.
6. Contenuti vuoti: **Impostazioni > Sorgenti > Aggiorna tutto**.

Per capire un problema preciso, il **Registro di riproduzione** si consulta su Mac, iPhone o iPad.

## Avvertenza legale e privacy {#tv-legal}

Kastideo non fornisce, ospita né vende alcun contenuto: siete responsabili della legalità delle vostre sorgenti. L'avvertenza completa è in **Impostazioni > Info > Avvertenza legale**.

Kastideo non raccoglie alcun dato: sorgenti e impostazioni restano sull'Apple TV e le credenziali sono inviate solo ai servizi che configurate (il vostro fornitore, i vostri server, TMDB se inserite una chiave). Informativa completa: https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md
