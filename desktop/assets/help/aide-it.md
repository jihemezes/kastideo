# Primi passi

## Benvenuto {#bienvenue}

Kastideo riunisce in un'unica interfaccia i tuoi **canali live, film e serie IPTV**, i tuoi **video personali** (disco, chiavetta USB, NAS, Jellyfin, Emby, Plex) e **YouTube**. Kastideo **non fornisce alcun contenuto**: sei tu ad aggiungere le tue sorgenti.

<!--mac-->
![La schermata Home](img:home)

1. Torna alla Home, da qualsiasi punto.
2. Una sola ricerca per canali, film e serie.
3. Il pulsante **?**: la guida, aperta sulla pagina corrispondente alla schermata in cui ti trovi.
<!--/mac-->
<!--pc-->
![La schermata Home](img:homepc)

1. Il pulsante **?**: la guida, aperta sulla pagina corrispondente alla schermata in cui ti trovi.
2. **Registro di riproduzione**: lo strumento di diagnostica.
3. **Impostazioni**: sorgenti, aspetto, registrazioni…
4. Una sola ricerca per canali, film e serie, poi i riquadri e le scorciatoie ([dettagli della schermata Home](help:accueil)).
<!--/pc-->

### Avvio rapido

<!--mac-->
1. Al primo avvio, fai clic su **Aggiungi una sorgente** (oppure **Impostazioni ⌘,** > **Sorgenti** > **Aggiungi**).
<!--/mac-->
<!--pc-->
1. Apri le **Impostazioni** (l'ingranaggio nella Home, oppure **Ctrl+,**) > **Sorgenti** > **Aggiungi una sorgente**.
<!--/pc-->
2. Scegli il tipo di sorgente: [Xtream Codes](help:xtream), [playlist M3U](help:m3u), [Cartelle](help:dossiers) oppure un server [Jellyfin, Emby o Plex](help:serveurs).
3. Compila i dati richiesti e fai clic su **Aggiungi**: Kastideo carica i canali, i film, le serie e la [guida TV](help:guide).
4. Torna alla **Home** e apri **Diretta**, **Film** o **Serie**.

### Ottenere aiuto

<!--mac-->
- Il pulsante **?** nella barra degli strumenti apre la guida sulla pagina corrispondente alla schermata corrente.
- Menu **Aiuto > Guida di Kastideo** oppure **⌘?**.
<!--/mac-->
<!--pc-->
- Il pulsante **?** nella Home e nelle schermate principali apre la guida.
<!--/pc-->
- Il campo **Cerca** in alto nella guida cerca in tutte le pagine.
- Qualcosa non va? Consulta le [domande frequenti](help:faq) e poi la [risoluzione dei problemi](help:depannage).

> Vuoi guardare YouTube? Vedi [YouTube](help:youtube). Per importare i tuoi abbonamenti: [passo dopo passo](help:youtube-import).

## Domande frequenti {#faq}

### Dove trovo i canali da aggiungere?
Kastideo non fornisce né canali né abbonamenti. Il tuo fornitore IPTV ti dà un server, un nome utente e una password ([Xtream Codes](help:xtream)), oppure l'indirizzo di una playlist ([M3U](help:m3u)). Puoi anche riprodurre i tuoi file ([Cartelle](help:dossiers)).

### Come cambio la lingua di Kastideo?
Kastideo è disponibile in **francese, inglese, spagnolo, tedesco, italiano e portoghese** (Portogallo e Brasile). Per impostazione predefinita segue la lingua del tuo dispositivo; se tale lingua non è supportata, l'interfaccia viene mostrata in inglese. Per cambiarla: **Impostazioni > Generali > Lingua** (su iPhone, iPad e Apple TV, Kastideo segue la lingua del sistema: impostala nelle Impostazioni del dispositivo). La modifica viene applicata al successivo avvio di Kastideo.

### Un canale non parte o va a scatti
<!--mac-->Vedi [Se un canale non parte](help:chaine-ne-demarre-pas) e [Risoluzione dei problemi](help:depannage).<!--/mac--><!--pc-->Vedi [Risoluzione dei problemi](help:depannage).<!--/pc--> Molto spesso la causa è una **seconda connessione simultanea** sullo stesso abbonamento: vedi [Una sola connessione alla volta](help:connexion-unique).

### La guida TV è vuota o incompleta
Impostazioni > Sorgenti > **Ricarica la guida TV**, poi leggi [Guida TV](help:guide) e la [guida di riserva](help:guide-secours).

### Come posso guardare YouTube senza pubblicità?
Kastideo riproduce i video con il player ufficiale in **modalità di privacy avanzata**: nessun cookie di tracciamento, quindi di solito nessuna pubblicità personalizzata. **Non** è un blocco pubblicitario: vedi [Pubblicità, account e privacy](help:youtube-confidentialite).

### Come importo i miei abbonamenti YouTube?
YouTube non consente di collegare un account a un'app di terze parti: si usa un file che Google genera per te. Segui la [guida passo dopo passo](help:youtube-import).

### La ricerca su YouTube richiede una chiave
La ricerca usa **la tua** chiave API Google gratuita. La [guida passo dopo passo](help:youtube-cle) la spiega in pochi minuti. Senza chiave puoi comunque seguire i canali e riprodurre i link incollati.

### Come registro un programma?
Vedi [Registrare la TV in diretta](help:enregistrer) e [Programmare una registrazione](help:programmer).

### Come guardo un programma già trasmesso?
Se il tuo fornitore offre un archivio: vedi [Replay](help:replay).

### Come porto le mie impostazioni su un altro computer?
Vedi [Backup e trasferimento](help:sauvegarde).

# Sorgenti

## Xtream Codes {#xtream}

<!--mac-->
È il formato più diffuso tra i fornitori IPTV. Servono tre informazioni: l'indirizzo del **server** (per esempio `http://example.com:8080`), il tuo **nome utente** e la tua **password**.

- Il pulsante **Prova la connessione** verifica le tue credenziali e mostra lo stato dell'account, la data di scadenza e il numero di connessioni simultanee consentite.
- La password è memorizzata nel **portachiavi di macOS**, mai in chiaro sul disco.
- La guida TV del server viene usata automaticamente.
- Le serie si aprono in una pagina con le relative stagioni ed episodi.
<!--/mac-->

<!--pc-->
Indirizzo del server (es. http://example.com:8080), nome utente e password. La password è memorizzata nel deposito sicuro del sistema: Gestione credenziali su Windows, GNOME Keyring o KWallet su Linux.
<!--/pc-->

## Playlist M3U / M3U8 {#m3u}

<!--mac-->
- **Tramite URL**: incolla l'indirizzo della playlist fornito dal tuo fornitore.
- Se l'indirizzo ha la forma `get.php?username=…&password=…` (il caso più comune con i fornitori di abbonamenti), Kastideo lo riconosce e lo salva come **Xtream Codes**: il caricamento è molto più rapido, la guida TV è inclusa e la password resta nel portachiavi. Le sorgenti di questo tipo già salvate vengono convertite automaticamente.
- **Tramite file**: scegli un file `.m3u` o `.m3u8` sul tuo Mac. Kastideo conserva il permesso di accesso per poterlo aggiornare.
- Le categorie provengono dall'attributo `group-title`, i loghi da `tvg-logo` e il collegamento alla guida TV da `tvg-id`.
- Kastideo smista automaticamente le voci in Diretta, Film o Serie in base al loro indirizzo.
<!--/mac-->

<!--pc-->
Indirizzo della playlist o file su disco (**Scegli un file…**). Un indirizzo «get.php?username=…&password=…» viene riconosciuto e trasformato in una sorgente Xtream, molto più rapida e completa (schede, episodi, ultime novità).
<!--/pc-->

## Cartelle (disco, chiavetta USB, NAS) {#dossiers}

<!--mac-->
Per guardare i video memorizzati sul Mac, su un disco esterno, su una chiavetta USB o su un NAS:

1. Impostazioni > Sorgenti > **Aggiungi** > tipo **Cartelle (disco, USB, NAS)**.
2. **Aggiungi una cartella…**: scegli una o più cartelle (per esempio «Film» e «Serie»). Per un **NAS**, monta prima la condivisione nel Finder (**Vai > Connessione al server…**, per esempio `smb://nas.local/Videos`), poi sceglila tra i volumi.
3. **Aggiungi**: Kastideo analizza le cartelle e le relative sottocartelle.

I video vengono riconosciuti dal nome:

- **Film**: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», oppure una cartella «Amélie (2001)» che contiene il film. Compaiono in **Film**, categoria «Film · nome della cartella».
- **Serie**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», oppure una cartella «Kaamelott/Season 3/12 - Le Tourment.avi». Gli episodi sono raggruppati in una serie, con le sue stagioni, in **Serie**.
- **Altri video** (vacanze, fotocamera…): categoria **Video · nome della cartella**, in Film.

Le cartelle vengono analizzate a ogni avvio e poi ogni 20 minuti: un nuovo video compare da solo. Se il disco è scollegato o la condivisione disconnessa, un messaggio lo segnala sotto la sorgente e l'elenco precedente viene mantenuto. I **sottotitoli** posti accanto a un video («Inception (2010).srt», «Inception (2010).en.srt») vengono caricati durante la riproduzione.

Con una **chiave TMDB** (Impostazioni > Generali), film e serie ottengono automaticamente una **locandina e una trama**. Se il nome del file inganna la ricerca, fai clic con il tasto destro sulla locandina (o sul link in fondo alla pagina dei dettagli) > **Correggi la scheda…**: cerca il titolo giusto e selezionalo; la scelta viene ricordata.
<!--/mac-->

<!--pc-->
Impostazioni > Sorgenti > **Aggiungi una sorgente** > **Cartelle**, poi **Aggiungi una cartella…** (disco interno, disco o chiavetta USB) oppure digita un **percorso di rete** e fai clic su **+**: `\\NAS\Videos` o un'unità di rete (`Z:\`) su Windows, una condivisione montata (`/mnt/nas/videos`, `/media/…`) su Linux. Più cartelle possono formare un'unica sorgente. Su **Android TV** (e Android) è accettato anche un percorso **SMB**: `smb://NAS/Video` (o `\\NAS\Video`); inserisca utente e password della condivisione, o li lasci vuoti per l'accesso ospite. Solo SMB 2.1 o precedente.

- **Film** riconosciuti dal nome: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», cartella «Amélie (2001)». Categoria «Film · nome della cartella».
- **Serie**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», cartelle «Serie/Season 1/…». Gli episodi sono raggruppati per serie e stagione in **Serie**.
- **Altri video**: categoria **Video · nome della cartella** in Film.
- Analizzate a ogni avvio e poi ogni 20 minuti. Disco scollegato: un messaggio lo segnala e l'elenco precedente viene mantenuto. Le sottocartelle illeggibili («System Volume Information»…) vengono saltate.
- I **sottotitoli** posti accanto a un video («Film.srt», «Film.en.srt») vengono caricati durante la riproduzione.
- Con una **chiave TMDB**, **locandine e trame** vengono aggiunte automaticamente; tasto destro > **Correggi la scheda…** per scegliere il titolo giusto quando il nome del file inganna la ricerca.
<!--/pc-->

## Jellyfin, Emby e Plex {#serveurs}

<!--mac-->
### Jellyfin ed Emby

1. Impostazioni > Sorgenti > **Aggiungi** > **Jellyfin** o **Emby**.
2. **Cerca nella rete** trova i server di casa tua; fai clic sul tuo per compilare l'indirizzo. Altrimenti digitalo (per esempio `192.168.1.10`: viene aggiunta la porta 8096).
3. Il tuo **nome utente** e la tua **password** Jellyfin / Emby — **facoltativi**: lasciali vuoti se l'account non ne ha (anche una **chiave API** del pannello di controllo può sostituirli). **Prova la connessione** verifica l'indirizzo. Un indirizzo copiato dal browser («…:8096/web/index.html#!/home») viene ridotto a quello del server.
4. **Aggiungi**: viene verificato il nome utente, poi le librerie di film, serie e video del server compaiono in **Film** e **Serie** (categorie «nome della libreria · nome del server»), con le locandine e i dettagli del server.

La riproduzione è **diretta**, senza transcodifica da parte del server. La password e la sessione sono memorizzate nel portachiavi.

### Plex

1. Impostazioni > Sorgenti > **Aggiungi** > **Plex**.
2. **Accedi con Plex** apre plex.tv nel browser: accedi e autorizza Kastideo. Tornato in Kastideo, scegli il server del tuo account.
3. Puoi anche digitare l'indirizzo del server (porta 32400) e il suo **token** (X-Plex-Token). Il token è **facoltativo** se il server consente la rete locale senza autenticazione (Plex > Impostazioni > Rete > «Elenco di indirizzi IP e reti consentiti senza autenticazione»).
4. **Aggiungi**: le librerie di film e serie compaiono in **Film** e **Serie**.
<!--/mac-->

<!--pc-->
Impostazioni > Sorgenti > **Aggiungi una sorgente** > **Jellyfin**, **Emby** o **Plex**. **Cerca nella rete** trova i server di casa tua: fai clic sul tuo per compilare il modulo (altrimenti digita l'indirizzo; senza porta viene aggiunta la 8096 o la 32400).

- **Jellyfin / Emby**: nome utente e password — **facoltativi** se l'account non ne ha (oppure una **chiave API** del pannello di controllo). **Prova** verifica l'indirizzo; in caso di errore viene mostrata la risposta esatta del server.
- **Plex**: **Accedi con Plex** apre plex.tv nel browser; autorizza Kastideo, poi scegli il server del tuo account. Oppure digita l'indirizzo e il **token** (X-Plex-Token), facoltativo se il server consente la rete locale senza autenticazione.
- Le librerie compaiono in **Film** e **Serie** («nome della libreria · nome del server»), con locandine, dettagli, stagioni ed episodi del server. Riproduzione diretta, senza transcodifica.
- **Ripresa e «visto» condivisi nei due sensi**: la posizione viene inviata al server mentre guardi e viene recuperata quella degli altri tuoi dispositivi. Tasto destro > **Segna come visto / non visto**; badge **Visto** sulle locandine.

> Firewall di Windows: alla prima ricerca, consenti Kastideo nelle reti private affinché i server possano rispondere.
<!--/pc-->

## Ripresa e «visto» condivisi con i server {#reprise-serveurs}

<!--mac-->
Con Jellyfin, Emby e Plex, la posizione di riproduzione viene inviata al server mentre guardi: un film iniziato in Kastideo può essere ripreso sulla TV, e viceversa. Un film guardato fino alla fine viene segnato come **visto** sul server. Fai clic con il tasto destro su un film o un episodio > **Segna come visto / non visto** (anche per i file delle cartelle). Un badge **Visto** compare sulle locandine e un segno di spunta nell'elenco degli episodi.

> Ricerca nella rete: la prima volta, macOS chiede il permesso di accedere alla **rete locale**; accettalo (altrimenti Impostazioni di Sistema > Privacy e sicurezza > Rete locale).
<!--/mac-->

## Guida TV (XMLTV) {#guide}

<!--mac-->
Ogni sorgente può avere un indirizzo di guida TV in formato XMLTV (`.xml` o `.xml.gz`). Se lo lasci vuoto, Kastideo usa quello del server Xtream o quello indicato nella playlist (`url-tvg`). La guida viene conservata da 6 ore prima fino a 48 ore dopo.
<!--/mac-->

<!--pc-->
La guida fornita dal tuo fornitore viene caricata in background e conservata su disco. Il campo facoltativo **Guida TV (XMLTV)** di una sorgente permette di usare un'altra guida (.xml o .xml.gz).
<!--/pc-->

## Guida TV di riserva (xmltvfr.fr) {#guide-secours}

<!--mac-->
La guida del tuo fornitore può essere incompleta o temporaneamente vuota. Kastideo la completa con una **guida di riserva** gratuita di **xmltvfr.fr** (guida «Completa» per impostazione predefinita: circa 785 canali francesi e stranieri, 5 giorni, aggiornata ogni giorno):

- vengono completati solo i canali **senza programmi** presso il tuo fornitore; la guida del fornitore mantiene la priorità;
- i canali vengono associati **per nome**: «|FR| TF1 FHD» → TF1, «|FR| FRANCE 2 UHD» → France 2, «|FR| TF1 4K» → TF1 4K;
- la guida di riserva viene ricaricata ogni 12 ore. Se il fornitore invia una guida vuota o illeggibile, i programmi già noti vengono conservati e sotto la sorgente compare un messaggio.

**Scoprire da dove arriva la guida.** Sotto ogni sorgente, Impostazioni > Sorgenti mostra quanti programmi ha inviato il fornitore. Il pulsante **Ricarica la guida TV** (icona del calendario) riavvia il download della guida del fornitore e della guida di riserva. Le righe del fornitore che sono solo **separatori di categoria** («♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣») vengono ignorate; una versione 4K o FHD senza programmazione propria riutilizza quella della versione HD; i canali senza programmazione mostrano «Programma non disponibile». Il **Registro**, argomento **Guida TV**, dettaglia ogni tentativo: indirizzo richiesto, risposta del server (codice, dimensione, tempo), numero di canali e programmi ricevuti, periodo coperto, quanti dei tuoi canali sono collegati alla guida del fornitore, alla guida di riserva o a nessuna delle due e — se la guida non contiene nulla di utilizzabile — l'inizio della risposta del server.

Impostazioni > Generali > **Guida TV di riserva**: attivala o disattivala, scegli un'altra guida di xmltvfr.fr (Francia ~400 canali, DTT) oppure inserisci un qualsiasi indirizzo XMLTV, **Aggiorna ora**, e vedi quanti canali sono stati collegati ai tuoi.
<!--/mac-->

<!--pc-->
Impostazioni > Generali > **Guida TV**: una guida di riserva riempie i canali senza programmi nella guida del tuo fornitore, associandoli per nome. Scegli una guida di xmltvfr.fr o digita un indirizzo; **Ricarica la guida** scarica di nuovo tutto. Il pulsante **Registro della guida TV** apre il Registro sull'argomento *Guida TV*: indirizzo richiesto, risposta del fornitore (codice, dimensione, tempo), canali e programmi ricevuti, periodo coperto, quanti dei tuoi canali sono collegati al fornitore, alla guida di riserva o a nessuna guida e — se la guida è inutilizzabile — l'inizio della risposta del server. I programmi del fornitore vengono filtrati in base agli identificatori dei tuoi canali: se la guida contiene programmi ma nessuno per i tuoi canali, il registro mostra gli identificatori dei due lati.
<!--/pc-->

## Gestire le sorgenti {#gerer-sources}

<!--mac-->
Apri **Kastideo > Impostazioni… (⌘,)**, scheda **Sorgenti**, oppure fai clic sul pulsante **Sorgenti** nella barra degli strumenti.

- L'interruttore attiva o disattiva una sorgente senza eliminarla.
- I pulsanti permettono di aggiornare, modificare o eliminare una sorgente.
- In caso di errore, il messaggio compare in rosso sotto la sorgente e nella barra laterale compare un triangolo arancione.
<!--/mac-->

<!--pc-->
Impostazioni > **Sorgenti**: **modifica** una sorgente (pulsante a forma di matita: nome, server, nome utente, password, indirizzo della playlist, guida TV — preferiti, recenti e correzioni dei canali vengono conservati), aggiornala, eliminala, vedi lo stato della sua guida TV. Il pulsante a forma di **occhio** mostra la password (o la chiave TMDB) per poterla verificare. Le sorgenti si aggiornano all'avvio quando l'ultimo aggiornamento risale a più di 6 ore fa (regolabile). Se un aggiornamento restituisce una sezione vuota, quella precedente viene conservata.
<!--/pc-->

Mentre i canali, i film e le serie di un abbonamento vengono verificati o scaricati (e quando le liste vengono ricalcolate dopo una modifica delle categorie), in alto compare un banner **Aggiornamento del catalogo**. L'app può sembrare bloccata per qualche secondo, fino a un minuto con un catalogo grande: è normale e il banner scompare da solo.

# Navigare

## La schermata Home {#accueil}

<!--mac-->
![La schermata Home](img:home)

Kastideo si apre sulla schermata **Home**, dall'alto verso il basso:

- il **campo di ricerca**, che cerca canali, film e serie contemporaneamente; facendo clic su un risultato lo si apre;
- i grandi riquadri **Diretta**, **Film** e **Serie**, e **I miei video** non appena esiste una sorgente [Cartelle, Jellyfin, Emby o Plex](help:mes-videos); ogni riquadro mostra il numero di canali, film, serie o video;
- i pulsanti **Preferiti**, **Recenti**, **Guida TV**, **YouTube** e **Registrazioni** (un badge indica il numero di elementi, oppure delle registrazioni e dei download in sospeso);
- la riga **In TV ora**: chip per tema (Sport, Notizie, Film…) e **Stasera**, che aprono [la diretta per temi](help:direct-theme);
- la riga **Riprendi la visione**: i film e gli episodi che hai iniziato; un clic riprende da dove ti eri fermato;
- se qualcosa è in riproduzione, un banner **In riproduzione** permette di **tornarci** o di **fermarlo**.

Per tornare alla Home in qualsiasi momento: il pulsante **Home** (casa) in alto a sinistra nella barra degli strumenti, **⌘0**, la riga **Home** della barra laterale oppure il tasto **H** nell'interfaccia TV.

Il **numero di versione** è mostrato in modo discreto in basso a destra, accanto ai pulsanti **?** e **Offrimi un caffè**; facendo clic sulla versione si aprono le novità.
<!--/mac-->
<!--pc-->
![La schermata Home](img:homepc)

Kastideo si apre sulla schermata **Home**, dall'alto verso il basso:

- l'**intestazione**: logo, nome e, a destra, tre pulsanti: **Aiuto** (**F1**), **Registro di riproduzione** e **Impostazioni** (**Ctrl+,**); un piccolo indicatore ruota mentre le sorgenti si aggiornano;
- il **campo di ricerca**, che cerca canali, film e serie contemporaneamente; facendo clic su un risultato lo si apre;
- i grandi riquadri **Diretta**, **Film** e **Serie**, e **I miei video** non appena esiste una sorgente [Cartelle, Jellyfin, Emby o Plex](help:mes-videos); ogni riquadro mostra il numero di canali, film, serie o video;
- i pulsanti **Preferiti**, **Recenti**, **Guida TV**, **MultiVista**, **YouTube** e **Registrazioni** (un badge indica il numero di elementi, di canali in MultiVista, oppure delle registrazioni e dei download in sospeso);
- la riga **Riprendi la visione**: i film e gli episodi che hai iniziato; un clic riprende da dove ti eri fermato;
- se qualcosa è in riproduzione, un banner **In riproduzione** permette di **tornarci** o di **fermarlo**;
- se non è stata aggiunta alcuna sorgente, una scheda **Nessuna sorgente** propone **Aggiungi una sorgente**.

In basso a destra: il pulsante **Offrimi un caffè** (può essere nascosto in Impostazioni > Informazioni) e il numero di versione.

Per tornare alla Home in qualsiasi momento: la riga **Home** della barra laterale, **Ctrl+0** oppure il tasto **H** nell'interfaccia TV.

**Su telefoni e tablet Android**, la Home si adatta alla larghezza dello schermo: sotto circa 720 px (telefono, o tablet in verticale), i quattro riquadri passano su **due colonne** e l'intestazione si riduce. **Su Android TV**, i pulsanti si scelgono con il telecomando (contorno visibile) e **OK** apre.
<!--/pc-->

## I miei video {#mes-videos}

<!--mac-->
Non appena esiste una sorgente **Cartelle**, **Jellyfin**, **Emby** o **Plex**, nella schermata Home compare un riquadro **I miei video** (e una riga nella barra laterale, **⌘8**). Raccoglie i tuoi video, a parte l'IPTV:

- **In evidenza**: **Riprendi la riproduzione** (film ed episodi iniziati), **Aggiunti di recente**, **Film da guardare**, poi una riga di Film, Serie e Video;
- **Film**, **Serie**, **Video**: griglie con ricerca, filtri (**genere**, **anno**, **da vedere**) e ordinamento (titolo, aggiunti di recente, anno);
- **Cartelle**: sfoglia le tue cartelle e sottocartelle come nel Finder (percorso per risalire) e le librerie dei server;
- **Sorgenti**: tutte, oppure una sola (NAS, Emby, Plex…). Un triangolo arancione segnala un errore: clic destro > **Dettagli dell'errore…** mostra la richiesta e la **risposta esatta del server** (pulsante **Copia**), poi **Riprova**.

In **Film** e **Serie**, il selettore **Tutti / IPTV / I miei video** (barra laterale, sopra le categorie) sceglie cosa viene mostrato: solo IPTV (predefinito), solo i tuoi video, oppure entrambi mescolati. Le categorie dei tuoi video non vengono mai nascoste dall'impostazione dei paesi.
<!--/mac-->

<!--pc-->
Non appena esiste una sorgente **Cartelle**, **Jellyfin**, **Emby** o **Plex**, nella schermata Home compare un riquadro **I miei video** (scorciatoia **Ctrl+8**). Raccoglie i tuoi video, a parte l'IPTV:

- **In evidenza**: **Riprendi la riproduzione** (film ed episodi iniziati), **Aggiunti di recente**, **Film da guardare**, poi una riga di Film, Serie e Video;
- **Film**, **Serie**, **Video**: griglie con ricerca, filtri (**genere**, **anno**, **da vedere**) e ordinamento (titolo, aggiunti di recente, anno);
- **Cartelle**: sfoglia le tue cartelle e sottocartelle come in Esplora file (percorso per risalire) e le librerie dei server;
- **Sorgenti**: tutte, oppure una sola (NAS, Emby, Plex…). Un triangolo arancione segnala un errore: clic destro > **Dettagli dell'errore…** mostra la richiesta e la **risposta esatta del server**, poi **Riprova**.

In **Film** e **Serie**, il selettore **Tutti / IPTV / I miei video** (barra laterale, sopra le categorie) sceglie cosa viene mostrato: solo IPTV (predefinito), solo i tuoi video, oppure entrambi mescolati. Le categorie dei tuoi video non vengono mai nascoste dall'impostazione dei paesi.
<!--/pc-->

## Rimuovere un elemento da «Riprendi la visione» {#retirer-reprise}

<!--mac-->
Fai clic con il tasto destro su una miniatura in **Riprendi la visione** (home, interfaccia Cinema, I miei video; pressione prolungata su Android) per ottenere:

- **Rimuovi da «Riprendi la visione»**: la miniatura scompare dalla riga, ma la **posizione viene conservata**: quando riprodurrai di nuovo il film, riprenderà da dove l'avevi lasciato.
- **Svuota «Riprendi la visione»**: rimuove tutte le miniature dalla riga.

Un banner **Annulla** resta visibile per qualche secondo. Un elemento rimosso **torna** nella riga non appena lo guardi di nuovo; nel frattempo compare in «Visti di recente».
<!--/mac-->

## Ordinare e filtrare I miei video {#filtres-videos}

<!--pc-->
Su **Windows, Linux e Android**, la **freccia** inverte l'ordine e **Raggruppa per** dispone le locandine in **sezioni** (sorgente, categoria / cartella / album, tipo, anno, mese di aggiunta; più criteri insieme). Tutto viene ricordato.
<!--/pc-->

In **I miei video**, le viste **Film**, **Serie** e **Video** hanno una barra dei filtri. Le tue scelte vengono **ricordate** e ripristinate al successivo avvio. **Reimposta** cancella tutti i filtri (l'ordinamento viene mantenuto).

- **Sorgente**: quando sono state aggiunte più sorgenti (cartella locale, Emby, Jellyfin, Plex…), mostra solo una di esse. Nella vista «tutte le sorgenti», un **badge** su ogni locandina indica da dove proviene il film.
- **Genere**, **Anno**.
- **Paese** e **Lingua**: dalla scheda TMDB (o dal server Emby, Jellyfin o Plex).
- **Qualità**: **4K** (2160p, UHD), **HD** (1080p, 720p, Blu-ray, WEB-DL…) o altra, in base al nome del file.
- **Stato**: **Da vedere**, **In corso**, **Visto** o **Preferiti**.
- **Ordinamento**: titolo, aggiunti di recente, anno, **voto TMDB** o **durata**.

Voti, durate, paesi e lingue dei file nelle tue cartelle provengono da TMDB (è necessaria una [chiave TMDB](help:tmdb)): compaiono man mano che le schede vengono cercate, il che richiede qualche minuto la prima volta. Un film senza voto finisce in fondo quando si ordina per voto.

## Disposizione della finestra e barra laterale {#colonnes}

![Disposizione della finestra e barra laterale](img:layout)

<!--mac-->
Nell'interfaccia Classica, la finestra ha tre colonne:

- **Barra laterale**: Home, Diretta, Film, Serie, Preferiti, Recenti, Guida TV, poi le categorie della sezione scelta e lo stato delle tue sorgenti.
- **Elenco**: gli elementi della sezione o della categoria, con il programma in corso per i canali. Il campo **Cerca** filtra l'elenco senza distinguere maiuscole e accenti.
- **Player**: il video, con sotto il programma in corso, il suo avanzamento e i programmi successivi.

Facendo clic con il tasto destro su un elemento puoi aggiungerlo ai preferiti o copiare l'indirizzo del flusso.
<!--/mac-->

<!--pc-->
Selettore Diretta / Film / Serie, poi: tutti i canali o film, **Preferiti**, **Recenti** e, per la TV in diretta, **Temi**, **Guida TV** e **MultiVista**; **Registrazioni**; le **categorie**. In basso: la registrazione e il download in corso (avanzamento, tempo rimanente) e **Impostazioni**.
<!--/pc-->

## Tre interfacce a scelta {#interfaces}

<!--mac-->
Kastideo offre tre presentazioni, che scegli **separatamente per la diretta, i film, le serie e i preferiti / recenti**:

- **Classica**: le tre colonne descritte in [Disposizione della finestra e barra laterale](help:colonnes).
- **TV** (solo diretta): vedi [L'interfaccia TV](help:interface-tv).
- **Cinema**: un grande **banner «in evidenza»** che scorre (vedi [Il banner «in evidenza»](help:bandeau)), poi **righe orizzontali**: riprendi la visione, preferiti e una riga per categoria. Film e serie compaiono come locandine, i canali come miniature con il programma in corso. Un clic su un canale apre il player a schermo intero. Un clic sulla locandina di un **film** o di una **serie** apre prima la sua **pagina dei dettagli**: sfondo, locandina, anno, durata, generi, voto, trama, regista, cast (con foto), un pulsante **Torna a Film** (o Serie) in alto a sinistra, **Riproduci** / **Riprendi**, **Vedi gli episodi**, **Trailer**, **Scarica** e i pulsanti dei preferiti. Le informazioni provengono dal tuo fornitore IPTV; aggiungi una chiave **TMDB** gratuita (Impostazioni > Generali > Schede di film e serie) per ottenere pagine più ricche. **Indietro** (o Esc) torna al catalogo. In alto nella finestra, le schede **Diretta / Film / Serie / Guida / Preferiti / Recenti / Registrazioni** sostituiscono la barra laterale; la ricerca funziona come nella Classica. «Vedi tutto» apre un'intera categoria come griglia.

Per cambiare interfaccia:

- il pulsante **Interfaccia** nella barra degli strumenti (si applica al tipo di contenuto mostrato),
- il menu **Vista**: **⌥⌘1** Classica, **⌥⌘2** Cinema, **⌥⌘3** TV (diretta),
- oppure **Impostazioni > Aspetto**.

Per esempio: TV per la diretta e Cinema per film e serie. La sezione **Registrazioni** è sempre mostrata nell'interfaccia Classica. Per impostazione predefinita è Classica ovunque.
<!--/mac-->

<!--pc-->
Impostazioni > Aspetto > **Interfaccia per tipo di contenuto**:

- **Classica**: tre colonne (barra laterale, elenco con il programma in corso, player o dettagli a destra).
- **Cinema**: banner in evidenza, locandine o miniature in righe orizzontali, dettagli a pagina intera. Per la TV in diretta: righe «Sport in questo momento», «Notizie in diretta», «Stasera» per tema, preferiti, recenti, categorie; un clic apre il canale a schermo intero, **Indietro** (o Esc) lo ferma.
- **TV** (solo diretta): il canale a schermo intero, come un televisore (vedi [L'interfaccia TV](help:interface-tv)).
<!--/pc-->

## Il banner «in evidenza» (Cinema) {#bandeau}

<!--mac-->
In alto in Film e Serie, un **carosello a tutta larghezza** scorre una selezione: sfondo, locandina, titolo, anno, durata, generi, voto, trama e pulsanti **Riproduci** (o **Riprendi** / **Vedi gli episodi**), **Altre info** (la pagina dei dettagli) e **Trailer**. Mescola:

- le **tendenze TMDB** di questa settimana presenti nel tuo catalogo (chiave TMDB necessaria);
- le **ultime novità** del tuo fornitore;
- una **selezione da una categoria** a tua scelta (per esempio «Nuove uscite» o «Netflix»), oppure dall'intero catalogo a caso.

Lo scorrimento si ferma mentre il mouse è sul banner; frecce e puntini permettono di navigare. In **Diretta**, il banner mostra **cosa va in onda ora** sui tuoi canali preferiti e recenti, con l'avanzamento, il programma successivo e **Guarda**.

Impostazioni > Aspetto > **Banner «in evidenza»**: mostra o nascondi, altezza (compatta, normale, grande), velocità di scorrimento, sorgenti del carosello e categorie di film e serie.
<!--/mac-->

<!--pc-->
Scorre film o serie (le tendenze TMDB di questa settimana disponibili per te, le ultime novità, una selezione di categoria) oppure, per la TV in diretta, il programma in corso dei tuoi canali. Frecce al passaggio del mouse; si ferma mentre il mouse è sopra. Impostazioni > Aspetto > **Banner in evidenza**: mostra o nascondi, altezza, velocità, sorgenti.
<!--/pc-->

## Paesi e lingue (Cinema) {#pays}

<!--mac-->
I fornitori spesso mescolano più paesi (categorie «FR| …», «|PT| …», «ITALIA»…). Impostazioni > Aspetto > **Paesi e lingue (interfaccia Cinema)** elenca i paesi trovati nei nomi delle tue categorie, con il numero di elementi: spunta quelli che vuoi vedere. Le **ultime novità**, le **tendenze**, il **banner in evidenza** e le **righe delle categorie** dell'interfaccia Cinema mostrano allora solo quei paesi. **Mantieni le categorie senza paese** conserva categorie come «Azione» o «Novità». **Tutti i paesi** torna alla visualizzazione completa. Gli elenchi Classici e la ricerca restano completi.
<!--/mac-->

<!--pc-->
I fornitori spesso mescolano più paesi (categorie «FR| …», «|PT| …», «ITALIA»…). Impostazioni > Aspetto > **Paesi e lingue (interfaccia Cinema)** elenca i paesi trovati nei nomi delle tue categorie, con il numero di elementi: scegli quelli da mostrare. Le **ultime novità**, le **tendenze**, il **banner in evidenza** e le **righe delle categorie** dell'interfaccia Cinema mostrano allora solo quei paesi. **Mantieni le categorie senza paese** conserva categorie come «Azione» o «Novità». **Tutti** torna alla visualizzazione completa. Gli elenchi e la ricerca restano completi.
<!--/pc-->

## L'interfaccia TV (diretta) {#interface-tv}

<!--mac-->
Il canale riempie l'intero fotogramma, come su un televisore. La prima volta che compare, Kastideo riprende l'ultimo canale che hai guardato.

- **Pannello dei canali**: tasto **←**, **Invio**, oppure sposta il mouse sul bordo sinistro. Elenca i canali con numero, logo, programma in corso e avanzamento. Il menu in alto filtra per **Tutti / Preferiti / Recenti / categoria**, e il campo **Cerca** filtra per nome. Si chiude da solo dopo qualche secondo (**→** o **Esc** per chiuderlo subito).
- **Zapping**: **↑ / ↓** canale precedente / successivo nell'elenco mostrato, **B** torna al canale precedente.
- **Numero del canale**: digita le cifre (per esempio **1** poi **2**); il canale si apre dopo 1,6 s oppure con **Invio**. Se il tuo fornitore non numera i canali, il numero si riferisce alla posizione nell'elenco mostrato.
- **Banner informativo**: mostrato per cinque secondi a ogni cambio di canale (logo, numero, programma in corso, orari, programma successivo, ora). **I** o **→** lo mostra o lo nasconde.
- Altri tasti: **F** preferito, **M** muto, **Spazio** pausa (diretta in differita).
- Doppio clic sull'immagine oppure **⌘↩**: schermo intero; la barra degli strumenti viene nascosta.
- I tasti della tastiera non funzionano mentre si digita nel campo di ricerca. Le schede in alto nella finestra permettono di passare a Film, Serie ecc.
<!--/mac-->

<!--pc-->
- **↑ / ↓**: canale precedente / successivo; **digita un numero** (fino a 4 cifre).
- **←** o bordo sinistro: **pannello dei canali** (filtro, ricerca, programma in corso).
- **→** o **I**: **banner informativo** (programma in corso e successivo).
- **B**: canale precedente — **F**: preferito — **M**: audio — **Spazio**: pausa — **G**: guida TV — **H**: home.
<!--/pc-->

## La guida TV a griglia {#guide-grille}

<!--pc-->
Impostazioni > Generale > Pagina iniziale > **All'apertura della guida**: **Adesso** (ora attuale) o **Ultima posizione** (ora e categoria dell'ultima visita). Nella scheda di una serie, **Visto / non visto** segna una stagione o l'intera serie.
<!--/pc-->

<!--mac-->
La sezione **Guida TV** (barra laterale, scheda **Guida TV** delle interfacce Cinema e TV, **⌘7**, oppure il tasto **G** nell'interfaccia TV). I canali sono nelle righe, le ore nelle colonne; la linea rossa indica l'ora corrente.

- **‹ ›** spostano la griglia, **Ora** torna all'ora corrente, il menu della data salta a un altro giorno (le 19 per i giorni successivi).
- Scegli l'intervallo di tempo mostrato (**2 h / 3 h / 6 h**), filtra per **preferiti**, **recenti** o **categoria**, oppure cerca un canale.
- Fai clic su un programma: descrizione, pulsante **Guarda**, **Registra** (programma in corso) o **Programma la registrazione** (programma futuro). Un punto rosso indica una registrazione programmata.
- I giorni passati (menu della data, sezione **Rivedi**) e i programmi contrassegnati con ↺ consentono il **replay** (vedi [Replay](help:replay)).
- Fai clic sul nome di un canale per guardarlo. Vengono elencati solo i canali che hanno programmi: se la griglia è vuota, controlla l'indirizzo della guida nelle impostazioni della sorgente.
<!--/mac-->

<!--pc-->
Home, barra laterale della diretta, **Ctrl+7** oppure il tasto G nell'interfaccia TV. Canali nelle righe, ore nelle colonne, una linea rossa all'ora corrente; **‹ Ora ›**, selettore del giorno, intervallo 2 h / 3 h / 6 h, filtro (tutti, preferiti, recenti, tema, categoria) e ricerca. Un clic su un programma ne apre i dettagli: **Guarda**, **Registra**, **Programma la registrazione** (punto rosso nella griglia) oppure **Avvisami quando inizia** (campanella). Su un programma passato di un canale con replay (↺): **Rivedi** oppure **Salva questo replay**; i giorni passati sono nel menu della data.
<!--/pc-->

## La TV in diretta per temi {#direct-theme}

<!--mac-->
La sezione **Temi** della barra laterale (sotto Diretta) ordina la TV in diretta per **tema** — Sport, Auto e Moto (motorismo), Film, Serie, Notizie, Documentari, Natura / Caccia e Pesca, Bambini, Intrattenimento, Cucina e Casa, Musica, Generalista, Regionale (regioni di France 3, TV locali), Internazionale (canali stranieri), Religione, Radio — senza le categorie che hai nascosto. Tre modalità:

- **Ora**: ciò che va in onda ora, ordinato in base al **genere del programma** nella guida TV (un film su un canale generalista compare in «Film»), con l'avanzamento. I canali **senza dati di guida** sono comunque elencati quando il loro **nome basta per classificarli** (beIN Sports → Sport…): mostrano il loro nome, senza avanzamento.
- **Stasera**: programmi che iniziano **tra le 20 e le 23**. Clic destro su un programma futuro > **Avvisami quando inizia**.
- **Canali**: canali ordinati per specialità. Il tema viene dedotto automaticamente dal nome del canale (beIN, Eurosport → Sport; BFM, LCI → Notizie…) e poi dai suoi programmi abituali; clic destro > **Tema del canale** per correggerlo.

Ogni canale compare **una sola volta**, anche se il tuo fornitore lo offre in più versioni (4K, FHD, HD, SD): Kastideo sceglie la versione adatta alla **tua connessione** (impostazione **Automatica** in Impostazioni > Generali > Riproduzione > Versione del canale) — scende di versione dopo una riproduzione instabile e risale dopo tre fluide. Clic destro > **Versione** per sceglierne un'altra.

I temi sono proposti anche altrove: righe «Sport in onda ora», «Film in onda ora»… in alto in Diretta nell'interfaccia **Cinema**, un filtro **Temi** nel pannello dei canali dell'interfaccia **TV** e nella **Guida TV**, e chip «In TV ora» (e «Stasera») nella schermata **Home**.

In **Sport**, una seconda riga filtra per **disciplina**: Calcio, Rugby, Tennis, Pallacanestro, Sport da combattimento, Golf, Ciclismo, Pallamano, Motorismo, Sport invernali, Ippica, Atletica e nuoto (dai titoli, generi e descrizioni dei programmi).

**Contenuti per adulti**: i canali e i contenuti il cui nome contiene «|XX|» (o che si trovano in una categoria per adulti) sono **nascosti ovunque** per impostazione predefinita. Per mostrarli, insieme al tema **Adulti**: Impostazioni > Generali > Riproduzione > **Mostra i contenuti per adulti**. Un **codice PIN** facoltativo a 4 cifre protegge questa impostazione: una volta definito (Impostazioni > Contenuti per adulti > Codice PIN, in tutte le versioni Android, Windows e Linux), viene richiesto per mostrare o nascondere i contenuti per adulti e per modificarlo o rimuoverlo. È incluso nell'esportazione della configurazione. Su Android TV il codice si inserisce con il **tastierino numerico** del telecomando, o con ▲ ▼ ◀ ▶.

**Avvisi sui programmi** (pulsante 🔔 della vista Temi): Kastideo ti avvisa due minuti prima dell'inizio di un programma il cui titolo contiene una parola scelta («PSG», «Formula 1»…), di un tema sui tuoi canali preferiti, oppure di un programma specifico. Compaiono una notifica e un banner **Guarda**.
<!--/mac-->

<!--pc-->
Barra laterale > **Temi**: **In questo momento**, **Stasera** (20–23) o **Canali**, filtrati per tema (Sport, Notizie, Film, Bambini, Documentari…) e, per lo sport, per disciplina. Una versione per canale (FHD, HD o SD in base alla tua connessione). Clic destro: versione del canale, **tema del canale** (per correggere la classificazione), preferiti, modifica del canale.
<!--/pc-->

# Riproduzione

## L'essenziale {#lecture}

<!--pc-->
Su **Windows, Linux e Android**, il menu **⋯** della barra del lettore offre **velocità** (film, episodi), **tracce audio**, **sottotitoli** e **formato dell'immagine** (adatta, riempi lo schermo, 16:9, 4:3). In diretta, **◀◀ / ▶▶** passano al canale precedente o successivo della categoria e la barra mostra il **programma in corso** con l'avanzamento e il successivo. Per un episodio compaiono **Successivo** ed **Episodi…**, e l'episodio seguente parte da solo alla fine (disattivabile in Impostazioni > Generale > Riproduzione).
<!--/pc-->

<!--mac-->
Kastideo riproduce tutti i contenuti con il motore **VLC**: MPEG-TS (.ts) in diretta, HLS (.m3u8), MP4, MKV, AVI…

- La riproduzione parte non appena selezioni un canale, un film o un episodio.
- Durante l'apertura vengono mostrati il logo e il nome del canale. Il badge **«Pronto in x s»** mostra poi il tempo di avvio (si può disattivare nelle impostazioni).
- I controlli compaiono quando passi il mouse sul video: riproduci / pausa, indietro di 10 s e avanti di 30 s per film ed episodi, barra di avanzamento, volume (fino al 200%) e modalità cinema.
- Un clic sul video lo mette in pausa; un **doppio clic** attiva la **modalità cinema**: la finestra passa a schermo intero e resta visibile solo il **video** (niente colonne né barra degli strumenti; il pulsante verde della finestra e **⌃⌘F** fanno lo stesso durante la riproduzione). **Esc** o **⌘↩** per uscirne.
- **Riprendi la riproduzione**: per film ed episodi, Kastideo ricorda la tua posizione. Quando ne riapri uno, la riproduzione riprende da dove ti eri fermato, con un messaggio che propone di **ricominciare**. Compaiono barre di avanzamento negli elenchi, sulle locandine e negli episodi. Si può disattivare, e le posizioni si possono cancellare, nelle impostazioni.
- Per le sorgenti Xtream, la diretta viene riprodotta in formato MPEG-TS (.ts), come il player di riferimento di Xtream; se il flusso fallisce, Kastideo prova automaticamente la variante .m3u8 (e viceversa).
<!--/mac-->

<!--pc-->
Il player (motore mpv) ha una barra di controllo che si nasconde da sola, un punto di stato del flusso, volume, modalità cinema (doppio clic o Ctrl+Invio) e schermo intero (F11). Per film ed episodi: mini linea temporale, −10 s / +30 s, **ripresa** da dove ti eri fermato, **Torna ai dettagli**.
<!--/pc-->

## Barra di controllo, linea temporale e pannello informativo {#barre-controle}

<!--mac-->
- **Barra che si nasconde da sola**: compare al minimo movimento del mouse e si nasconde, insieme al puntatore, dopo 3 secondi di inattività (resta finché il mouse è sopra, in pausa o quando il pannello è aperto).
- **Stop** (pulsante ■ accanto a riproduci / pausa, oppure **⌘.**): ferma il flusso. L'area video mostra «Nessuna riproduzione» con un pulsante **Riavvia**; la posizione di un film o di un episodio viene ricordata per riprendere. Durante il casting, lo stop termina anche il cast e il televisore torna al suo programma. Se il canale è in registrazione, Kastideo chiede conferma (la registrazione si ferma con la riproduzione).
- **Mini linea temporale** (film ed episodi): una linea sottile sopra i pulsanti che si ispessisce al passaggio del mouse e mostra il tempo di destinazione; fai clic o trascina per spostarti.
- **Stato del flusso**: un punto **verde** (Eccellente), **arancione** (Discreto) o **rosso** (Instabile) indica la qualità della ricezione, con la definizione (SD, HD, 4K). Al passaggio del mouse: risoluzione esatta, bitrate, fotogrammi al secondo, immagini perse e interruzioni nell'ultimo minuto.
- **Pannello informativo** (pulsante ⓘ oppure **⌘I**, Esc per chiuderlo): scorre da destra sopra il video e mostra il canale con i programmi in corso e successivi, oppure la trama e il cast di un film; la scelta della **traccia audio** (lingua, audiodescrizione…) e dei **sottotitoli**; la qualità di ricezione dettagliata.
<!--/mac-->

## MultiVista (più canali contemporaneamente) {#multivue}

<!--mac-->
**MultiVista** mostra fino a **4 canali in diretta** in una finestra (1 a schermo intero, 2 affiancati, 3 o 4 in griglia). **L'audio segue il riquadro attivo** (bordo arancione): fai clic su un riquadro oppure usa i tasti **da 1 a 4**.

- Aprila: **Riproduzione > MultiVista…** (**⌥⌘M**), oppure clic destro su un canale > **Aggiungi a MultiVista**.
- Nella finestra: **+** aggiunge un canale (preferiti, recenti o ricerca); passando il mouse su un riquadro, ⟳ cambia il canale e ✕ lo rimuove; **Ferma tutto** ferma ogni flusso. Chiudere la finestra ferma MultiVista.
- Ogni flusso usa **una connessione** verso il tuo fornitore, quindi MultiVista è **disattivata per impostazione predefinita**: inserisci il numero di connessioni simultanee del tuo abbonamento in **Impostazioni > Generali > Riproduzione** (da 2 a 4) per attivarla. Il pulsante **Prova la connessione** di una sorgente Xtream mostra questo numero. All'apertura, la riproduzione principale si ferma per liberare la sua connessione (a meno che non stia registrando); anche una registrazione o un download usa una connessione.
<!--/mac-->

<!--pc-->
**MultiVista** mostra fino a **4 canali in diretta** su uno schermo. **L'audio segue il riquadro attivo** (bordo arancione).

- **Attivazione**: ogni canale usa una connessione verso il tuo fornitore, quindi MultiVista resta disattivata finché non imposti il numero di **connessioni simultanee** del tuo abbonamento: Impostazioni > Generali > Riproduzione (da 2 a 4). **Rileva** interroga le tue sorgenti Xtream.
- **Apertura**: home > **MultiVista**, barra laterale della diretta > **MultiVista**, **Ctrl+Alt+M**, oppure clic destro su un canale > **Aggiungi a MultiVista**. Il canale che stavi guardando diventa il primo riquadro; se è in registrazione, continua a registrare in background, senza audio.
- **Aggiunta**: pulsante **+** (o tasto **A**): preferiti, recenti, tutti i canali o ricerca. Anche una cella vuota della griglia propone «Aggiungi un canale».
- **Disposizioni** (in alto a destra): **Automatica** (1 a schermo intero, 2 affiancati, 3 o 4 in griglia), **Griglia 2 × 2**, **Uno grande** e gli altri piccoli, **Affiancati**. La disposizione viene ricordata.
- **Vista grande ↔ riquadro**: **doppio clic** su un riquadro (o premi **G**) per ingrandirlo con l'audio; fai di nuovo doppio clic sulla vista grande per tornare alla griglia.
- **Passando il mouse su un riquadro**: ingrandisci, cambia canale, rimuovi. Il nome del canale e il programma in corso sono mostrati in basso.
- **Gruppi salvati** (icona del segnalibro): **Salva questo gruppo…** memorizza i canali e la disposizione con un nome (ad es. «Multiplex calcio»); fai clic su un gruppo per riaprirlo, la croce lo elimina.
- **Tastiera**: **da 1 a 4** audio su quel riquadro, **G** ingrandisci, **A** aggiungi, **M** muto, **Canc** rimuovi il riquadro attivo, **F** o **F11** schermo intero, **Esc** esci dallo schermo intero poi da MultiVista.
- **Ferma tutto** (o Indietro) ferma ogni flusso e torna alla schermata precedente.

> Anche una registrazione o un download usa una connessione: un'icona ⓘ te lo ricorda nella barra di MultiVista. Se un riquadro indica «Il canale non risponde», il fornitore sta probabilmente rifiutando una connessione aggiuntiva: rimuovi un canale o riduci il numero di connessioni.
<!--/pc-->

## Più sorgenti live: MultiVista e picture in picture {#multivue-sources}

Se hai **più sorgenti live** (due abbonamenti IPTV, oppure un abbonamento e un elenco di canali pubblici), [MultiVista](help:multivue) le **mescola**. Ci sono tre passaggi.

**1. Connessioni di ciascun abbonamento.** In **Impostazioni > Generali > Riproduzione**, una riga per abbonamento (nome + identificativo dell'account, per distinguere due account dello stesso fornitore) imposta il numero di flussi simultanei consentiti: 1 per la maggior parte degli abbonamenti, 4 per un elenco pubblico. Su Windows, Linux e Android, **Rileva** interroga gli account Xtream.

**2. Numero di schermi.** Nella finestra di MultiVista, imposta il numero di **schermi** (da 1 a 4, al massimo la somma delle connessioni delle tue sorgenti).

**3. Sorgente di ciascuno schermo.** Ogni schermo è **riservato a una sorgente**: il badge in alto sullo schermo permette di cambiarla. Il selettore di canali di quello schermo propone solo canali della sua sorgente, e una sorgente non può riservare più schermi di quante connessioni abbia.

**Disposizione**: affiancati, impilati, griglia, oppure **uno grande + miniature (PIP)** (menu della disposizione di MultiVista). In quest'ultima, un canale riempie il fotogramma e gli altri fluttuano come **piccole miniature 16:9**: **trascina** una miniatura per spostarla (si aggancia all'angolo più vicino), fai **doppio clic** su di essa per scambiarla con quella grande (l'audio segue) e imposta la loro **dimensione** (piccola, media, grande) nella barra di MultiVista. Un singolo clic dà l'audio a una miniatura.

**Scegliere un canale.** Il selettore rispecchia l'interfaccia Classica: a sinistra **Preferiti**, **Recenti** e le **categorie della sorgente dello schermo** (nel tuo ordine, con le categorie nascoste o rinominate da «Gestisci le categorie»), a destra i canali con il programma in corso. Un **clic** riproduce il canale sullo schermo e lascia aperto il selettore per lo zapping; un **doppio clic** lo riproduce e lo chiude. Un canale già mostrato su un altro schermo è in grigio. La ricerca copre tutte le categorie della sorgente.

**Dove trovo MultiVista?** Su Mac: la voce **MultiVista** nella barra laterale, il pulsante nella barra degli strumenti, il pulsante **MultiVista** nella schermata Home (accanto a Preferiti e Registrazioni), il pulsante nella barra del player (apre MultiVista con il canale che stai guardando), il menu Riproduzione e ⌥⌘M. Su Windows, Linux e Android: Home, la barra laterale della Diretta, il pulsante nella barra del player e Ctrl+Alt+M.

**Picture in picture (PIP).** Mentre un canale in diretta è in riproduzione, il pulsante **picture in picture** (in alto a destra nel player) apre un **secondo canale in una piccola finestra** in un angolo, senza audio. **Fai clic sulla piccola finestra** per scambiarla con il canale principale, oppure sulla croce per chiuderla. Il secondo canale deve provenire da una sorgente con una connessione libera: con un solo abbonamento limitato a una connessione, scegli un canale dell'elenco pubblico (o di un secondo abbonamento). La piccola finestra si chiude quando esci dal player.

## Se un canale non parte {#chaine-ne-demarre-pas}

<!--mac-->
Se non arriva alcuna immagine dopo **20 secondi**, Kastideo prova automaticamente l'altro formato di flusso (.ts o .m3u8), poi mostra un messaggio di errore con i dettagli restituiti dal motore VLC.

Il **Registro** (menu **Riproduzione > Registro di riproduzione…**, **⌥⌘L**, oppure il pulsante nel messaggio di errore) è lo strumento di diagnostica di Kastideo. I nomi utente e le password vi sono **nascosti**: puoi copiarlo per condividerlo in caso di problema.

- **Argomenti**: i messaggi sono classificati in *Guida TV*, *Riproduzione e relay*, *Sorgenti e cataloghi*, *Registrazioni*, *Schede TMDB*, *Aggiornamenti* e *Schermo e altro*. Fai clic su uno o più argomenti per vedere solo quelli (viene indicato il numero di righe per ogni argomento).
- **Cerca** una parola nel registro, oppure mostra solo **errori e avvisi**.
- **Copia ciò che è mostrato** copia solo ciò che è visualizzato (argomenti, ricerca), con il filtro indicato in alto.
- **Livello di dettaglio** (per argomento): *Normale* (l'essenziale), *Dettagliato* (predefinito per la Guida TV) o *Debug* (tutto). L'impostazione si applica alle righe scritte da quel momento; errori e avvisi vengono sempre conservati.
- **Sessione corrente / Sessione precedente**: il registro è conservato su disco, quindi puoi leggere cosa è successo all'avvio nella sessione precedente. **Mostra la cartella del registro** rivela il file nel Finder.
<!--/mac-->

## Diretta in differita {#differe}

<!--mac-->
Metti in **pausa** un canale in diretta: il motore VLC continua a ricevere il flusso e lo memorizza. Quando riprendi, stai guardando in **differita** (indicatore giallo «DIFFERITA −2:34» nei controlli). Se un flusso non può essere messo in pausa, il pulsante è in grigio.

In differita, i controlli offrono:

- una **linea temporale**: il punto di pausa a sinistra, la **diretta** a destra. **Trascina il cursore verso destra** per avanzare: Kastideo accelera la riproduzione fino al punto scelto (marcatore giallo), poi torna alla velocità normale;
- **+30 s** (o ⌘]): avanza di 30 secondi allo stesso modo;
- la **velocità** (×1, ×1,25, ×1,5, ×2): accelera per ridurre il ritardo; la riproduzione torna a ×1 da sola quando raggiunge la diretta;
- **Raggiungi**: accelera fino alla diretta, senza saltare nulla;
- **Torna alla diretta**: torna subito alla diretta. Poiché il motore VLC di solito non può saltare all'interno del buffer della differita, il flusso viene riaperto e il buffer svuotato. Se il flusso consente lo spostamento, il buffer viene mantenuto e −10 s / +30 s saltano direttamente.

**Dove viene memorizzata la differita?** Nella cartella temporanea di Kastideo (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, file `vlc-timeshift-…`), svuotata quando cambi canale; calcola da 1 a 4 GB all'ora a seconda della qualità. Impostazioni > Generali > Riproduzione: **Durata massima della differita** (da 30 min a 3 h, oppure illimitata; una volta raggiunta, la riproduzione riprende da sola), **Velocità di recupero** e un pulsante **Mostra** per aprire la cartella.
<!--/mac-->

<!--pc-->
Metti in pausa un canale (oppure torna indietro con ← o con la barra): continua a essere memorizzato nel buffer (fino a 1 h per impostazione predefinita, regolabile). Senza alcuna azione da parte tua, il canale resta «IN DIRETTA». La barra della differita mostra il ritardo, un cursore per tornare indietro o recuperare più in fretta, la velocità, **Raggiungi** e **Torna alla diretta**. ← / →: −10 s / +30 s.
<!--/pc-->

## Replay: guardare un programma già trasmesso {#replay}

<!--mac-->
Alcuni abbonamenti IPTV conservano i canali fino a **14 giorni** (a seconda del fornitore e del canale). Kastideo lo rileva da solo: i canali con replay mostrano un'icona **↺** negli elenchi e nella Guida TV.

- **Nella Guida TV**: fai clic su un programma **passato** (contrassegnato con ↺), poi su **Rivedi**. Sul programma **in corso**, **Guarda dall'inizio** lo riproduce dall'inizio. **Salva questo replay** scarica il programma dall'archivio del fornitore (cartella delle registrazioni).
- **Giorni precedenti**: il menu della data della Guida TV propone **Rivedi (replay)** con i giorni passati.
- **Da un canale**: clic destro sul canale > **Rivedi (replay)** (programmi recenti di quel canale). L'interfaccia Cinema ha anche una riga **Da rivedere** (i tuoi canali preferiti con replay).
- **Durante un replay**, la barra del player permette di mettere in pausa e di spostarsi all'interno del programma. Alla fine, Kastideo **torna al flusso in diretta del canale** (disattivabile).
- **Impostazioni > Generali > Replay**: attiva o disattiva il replay, numero di **giorni di programmi passati conservati nella guida** (più giorni = più memoria), **sfasamento orario** (se il programma riprodotto è spostato di qualche minuto o di un'ora, correggilo qui; il fuso orario del server viene letto automaticamente), ritorno alla diretta.
- Un replay conta come **una connessione**: chiude il canale corrente, come quando si cambia canale.
- Se un replay non parte, apri il **Registro** (argomento «Riproduzione e relay»): vi sono elencati l'indirizzo dell'archivio costruito e lo sfasamento usato. La guida del fornitore deve contenere programmi passati: ricaricala dopo aver aumentato il numero di giorni conservati.
<!--/mac-->

<!--pc-->
Alcuni abbonamenti IPTV conservano i canali fino a **14 giorni** (a seconda del fornitore e del canale). Kastideo lo rileva da solo: i canali con replay mostrano un'icona **↺** negli elenchi e nella Guida TV.

- **Nella Guida TV**: fai clic su un programma **passato** (contrassegnato con ↺), poi su **Rivedi**. Sul programma **in corso**, **Guarda dall'inizio** lo riproduce dall'inizio. **Salva questo replay** scarica il programma dall'archivio del fornitore (cartella delle registrazioni).
- **Giorni precedenti**: il menu della data della Guida TV propone **Rivedi (replay)** con i giorni passati.
- **Da un canale**: clic destro sul canale > **Rivedi (replay)…** (programmi recenti di quel canale). L'interfaccia Cinema ha anche una riga **Da rivedere** (i tuoi canali preferiti con replay).
- **Durante un replay**, la barra del player permette di mettere in pausa e di spostarsi all'interno del programma. Alla fine, Kastideo **torna al flusso in diretta del canale** (disattivabile).
- **Impostazioni > Generali > Replay**: attiva o disattiva il replay, numero di **giorni di programmi passati conservati nella guida** (più giorni = più memoria), **sfasamento orario** (se il programma riprodotto è spostato di qualche minuto o di un'ora, correggilo qui; il fuso orario del server viene letto automaticamente), ritorno alla diretta.
- Un replay conta come **una connessione**: chiude il canale corrente, come quando si cambia canale.
- Se un replay non parte, apri il **Registro** (pulsante Registro, argomento «Riproduzione e relay»): vi sono elencati l'indirizzo dell'archivio costruito e lo sfasamento usato. La guida del fornitore deve contenere programmi passati: ricaricala dopo aver aumentato il numero di giorni conservati.
<!--/pc-->

## Una sola connessione alla volta {#connexion-unique}

<!--mac-->
La maggior parte degli abbonamenti IPTV consente solo **un flusso simultaneo**. Kastideo chiude sempre il flusso corrente prima di aprire il successivo: puoi fare zapping senza rischiare di superare il tuo limite. Se la riproduzione fallisce, verifica che nessun altro dispositivo (TV, telefono, Piboard…) stia guardando con lo stesso abbonamento.
<!--/mac-->

<!--pc-->
La maggior parte degli abbonamenti consente una sola connessione. Kastideo chiude il canale precedente prima di aprire il successivo (**relay del flusso**, Impostazioni > Generali > Riproduzione) e chiede conferma prima di interrompere una registrazione.
<!--/pc-->

## Trasmettere su un televisore (Cast) {#cast}

Invia ciò che stai guardando — **un canale in diretta, un film, una serie, un video locale o YouTube** — a un televisore sulla stessa rete, senza uscire da Kastideo. La barra di riproduzione resta il tuo telecomando.

### Cosa è possibile

- **Chromecast, Google TV, Android TV** (e molti televisori con Chromecast integrato): l'intera riproduzione passa al televisore.
- **Apple TV (AirPlay)**: Kastideo non può inviare direttamente il video. Usa la **duplicazione dello schermo** di macOS (vedi sotto).
- **YouTube**: il video si apre nell'app YouTube del televisore, oppure nel browser (a tua scelta nelle Impostazioni).

### Trasmettere qualcosa

1. Avvia un canale, un film, una serie o un video.
2. Nella barra di riproduzione, fai clic sul pulsante **TV**.
3. Scegli il dispositivo dall'elenco. Se non compare nulla, fai clic su **Cerca di nuovo**: il televisore deve essere acceso e sulla stessa rete.
4. L'immagine passa al televisore. Sul computer compare una schermata «Trasmissione su…».

La riproduzione **riprende da dove eri**. Pausa, riproduzione, salto di 10 / 30 s, posizione, volume e muto nella barra agiscono sul televisore. Se avvii un altro elemento durante la trasmissione, viene inviato anch'esso al televisore.

Per tornare indietro, scegli **Interrompi la trasmissione** (oppure **Riprendi sul computer**): la riproduzione riprende sul computer alla stessa posizione.

<!--pc-->
### ffmpeg: conversione del video

Su Windows e Linux, Kastideo prepara il video con **ffmpeg** prima di inviarlo al televisore. È incluso nella versione per Windows e nell'AppImage per Linux. Con il pacchetto .deb, installalo: `sudo apt install ffmpeg`. Se Kastideo non lo trova, indica il suo percorso in **Impostazioni > Generali > Cast**.

- **Preparazione del video**: *Automatica* copia il video quando è già H.264 (leggera per il computer) e lo converte in caso contrario; *Converti sempre* è la più compatibile.
- **Risoluzione massima**: 720p o 1080p.
- **Aggiungere un televisore tramite il suo indirizzo IP**: utile se la ricerca automatica non lo vede (Wi-Fi ospiti, VLAN…).

Il Firewall di Windows può chiedere di consentire Kastideo: accetta sulle reti **private**, altrimenti il televisore non può leggere il flusso.
<!--/pc-->
<!--mac-->
### Apple TV e AirPlay

VLC, il motore di riproduzione di Kastideo, non invia il video tramite AirPlay. Per un Apple TV: **Centro di Controllo > Duplicazione schermo** (oppure **Impostazioni di Sistema > Monitor**), scegli l'Apple TV, poi riproduci Kastideo a schermo intero. Il pulsante TV nella barra offre una scorciatoia alle impostazioni dei monitor.

### Permesso di rete

Al primo utilizzo, macOS chiede se Kastideo può **trovare dispositivi sulla rete locale**: accetta, altrimenti non comparirà alcun televisore (Impostazioni di Sistema > Privacy e sicurezza > Rete locale > Kastideo). Il menu del pulsante TV ha una scorciatoia a questa impostazione. Se è già consentito, scegli **Cerca di nuovo** e verifica che il Mac e il televisore siano sulla stessa rete (niente Wi-Fi ospiti, niente VPN).
<!--/mac-->

### YouTube sul televisore

In **Impostazioni > Generali > Cast**, scegli:

- **L'app YouTube del televisore**: Kastideo chiede al televisore di aprire YouTube sul video scelto (clic destro su un video > **Riproduci su un televisore**). L'app YouTube deve essere installata sul televisore.
- **Browser (pulsante Trasmetti di Chrome)**: il video si apre nel tuo browser; usa il pulsante **Trasmetti** di Chrome per inviarlo al televisore.

### Limiti da conoscere

- Una sola connessione verso il tuo fornitore: durante la trasmissione, il computer non riproduce più il canale (vedi [Una sola connessione alla volta](help:connexion-unique)).
- Durante la trasmissione non è possibile spostarsi nella **diretta**; la **differita** del computer viene interrotta.
- La **registrazione** dei canali e **MultiVista** non si combinano con la trasmissione.
- C'è qualche secondo di ritardo, più che con la riproduzione locale.
- Un televisore che non risponde alla ricerca: verifica che sia acceso e sulla stessa rete Wi-Fi o Ethernet del computer.

## Immagine bloccata: decodifica software {#image-figee}

Alcuni canali mostrano un'immagine e poi restano **bloccati** mentre il flusso continua ad arrivare. La causa abituale è il **decoder hardware** del computer (scheda grafica o chip video) che non funziona con quel flusso. La **decodifica software** usa invece il processore: più pesante, ma più tollerante.

### Ripiego automatico

Per impostazione predefinita, quando l'immagine resta bloccata per più di 6 secondi (o il decoder hardware segnala errori ripetuti), Kastideo **riapre il canale con la decodifica software** e lo ricorda: le riproduzioni successive di quel canale usano subito il software. Una riga esplicativa viene aggiunta al **Registro di riproduzione** («Décodage : … réouverture en décodage logiciel»).

<!--pc-->
Su Windows e Linux, il rilevamento si basa sul numero di immagini mostrate dal motore e sui suoi messaggi di errore del decoder hardware. Se un canale si blocca senza essere rilevato, attiva la decodifica software a mano (sotto) e faccelo sapere.
<!--/pc-->

### A mano

- **Per un canale**: clic destro sul canale > **Decodifica software (immagine bloccata)**. Il canale si riapre subito; ripeti per tornare al decoder hardware.
- **Per tutto**: <!--mac-->**Impostazioni (⌘,) > Generali > Riproduzione**<!--/mac--><!--pc-->**Impostazioni (Ctrl+,) > Generali > Riproduzione**<!--/pc--> > **Decodifica sempre via software**. Consuma più energia e processore, soprattutto in 4K.
- **Disattivare il ripiego automatico**: nello stesso punto, **Decodifica software automatica quando l'immagine si blocca**.
- **Dimenticare tutto**: il pulsante «Reimposta» (Mac) o «Dimentica i canali impostati sulla decodifica software» (Windows/Linux) cancella l'elenco memorizzato.

### Se non basta

Un canale che resta bloccato anche in software ha di solito un flusso difettoso presso il fornitore: controlla il **Registro di riproduzione** e prova un'altra versione del canale (HD, SD…).

## Buffer {#tampon}

<!--mac-->
In **Impostazioni > Generali > Riproduzione**, scegli il compromesso tra velocità e stabilità:

- **Veloce** (predefinito): 0,4 s di riserva, lo zapping più breve.
- **Bilanciato**: 1 s.
- **Stabile**: 3 s, per connessioni o server poco affidabili (meno interruzioni, avvio più lento).
<!--/mac-->

## Il Registro (diagnostica) {#journal}

<!--pc-->
Il **Registro** (**Ctrl+Alt+L**, oppure il pulsante nella schermata Home e nei messaggi di errore) è lo strumento di diagnostica di Kastideo. I nomi utente e le password vi sono **nascosti**: puoi copiarlo per condividerlo.

- **Argomenti**: *Guida TV*, *Riproduzione e relay*, *Sorgenti e cataloghi*, *Registrazioni*, *Schede TMDB*, *Aggiornamenti*, *Schermo e altro*. Fai clic su uno o più argomenti per vedere solo quelli (viene indicato il numero di righe per argomento).
- **Cerca** una parola, oppure mostra solo **errori e avvisi**.
- **Copia ciò che è mostrato** copia solo ciò che è visualizzato, con il filtro in alto.
- **Livello di dettaglio** (per argomento): *Normale*, *Dettagliato* (predefinito per la Guida TV) o *Debug* (tutto). L'impostazione si applica alle righe scritte in seguito; errori e avvisi vengono sempre conservati.
- **Sessione corrente / Sessione precedente**: il registro è conservato su disco (il percorso della cartella è mostrato in fondo alla finestra), quindi puoi leggere cosa è successo all'avvio nella sessione precedente.
<!--/pc-->

# Registrazioni e download

## Panoramica {#enregistrements}

<!--mac-->
Tutto si trova nella sezione **Registrazioni** della barra laterale (**⌘6**): registrazione in corso, conversioni, download, programmazioni e file registrati (fai clic per guardarli, clic destro per mostrarli nel Finder o eliminarli).

I file vengono salvati in **~/Movies/Kastideo** (modificabile in **Impostazioni > Registrazioni**) e denominati automaticamente, per esempio «TF1 – Le goût du détail – 2026-10-18 20h50».

**Durata della registrazione.** La registrazione **parte subito**, senza fare domande. Un banner «Registrazione avviata» permette poi di scegliere quando fermarla: tra 15 min, 30 min, 1 h, 2 h…, **a un'ora precisa**, oppure **senza limite**. Se non scegli nulla, la registrazione si ferma alla **fine del programma** (guida TV, margine incluso) oppure, quando la guida non lo conosce, dopo la **durata predefinita** impostata in **Impostazioni > Registrazioni** (inizialmente 2 h; «Nessun limite» è possibile). Puoi cambiare la fine in qualsiasi momento con il pulsante **Durata** nella riga «Registrazione in corso», che mostra anche il tempo rimanente.
<!--/mac-->

## Registrare in diretta {#enregistrer}

<!--mac-->
- Mentre un canale è in riproduzione, fai clic su **●** nei controlli, su **Registra** sotto il video, oppure usa **⇧⌘R**. Il badge **REC** mostra la durata.
- La registrazione si ferma automaticamente alla fine del programma in corso (secondo la guida TV, più il margine finale), oppure quando fai clic su **■**.
- Usa **la stessa connessione** della riproduzione: non viene consumato nulla di più del tuo abbonamento.
- Clic destro su un canale > **Registra ora**: se stai guardando un altro canale, Kastideo chiede se interrompere la riproduzione, poi registra in background.
- Un **banner** in fondo alla finestra conferma quando una registrazione inizia e finisce e mostra **la cartella** in cui si trova il file (pulsante **Mostra**). Se la cartella scelta nelle impostazioni non è più accessibile, il file viene collocato in ~/Movies/Kastideo e il banner lo segnala. I passaggi dettagliati sono nel **Registro di riproduzione**.
- **Durante la registrazione**, il file è visibile e cresce nella sottocartella **In corso** della cartella delle registrazioni (una cartella con il nome del programma). Quando si ferma, viene spostato nella cartella delle registrazioni e la sottocartella viene rimossa. Se il motore VLC non crea il file entro 10 secondi, Kastideo riprova automaticamente in una cartella temporanea (il file compare allora solo alla fine); «Registrazione impossibile» viene mostrato solo dopo entrambi i tentativi, con i dettagli nel Registro di riproduzione (⌥⌘L). La durata è limitata solo dallo spazio su disco: calcola circa da 1 a 3 GB all'ora a seconda del canale (sotto i 3 GB liberi compare un avviso).
- Alla fine, la registrazione viene **convertita in MP4** senza perdita di qualità (riproducibile in QuickTime, su iPhone e iPad). Compare prima il file .ts, poi viene sostituito dal .mp4 quando la conversione è terminata (qualche minuto per 2 ore; mostrato nella sezione Registrazioni). L'immagine viene copiata senza perdita; l'**audio viene convertito in AAC** (alcuni canali trasmettono audio MP2 o AC-3 che QuickTime riproduce muto). I sottotitoli DVB e il teletext, che l'MP4 non può contenere, vengono scartati; se la conversione fallisce, un secondo tentativo conserva solo l'immagine e l'audio principale e, come ultima risorsa, si conserva il .ts. Si può disattivare nelle impostazioni.
<!--/mac-->

<!--pc-->
Pulsante rosso rotondo nella barra del player, tasto **R**, oppure clic destro su un canale > **Registra ora**: il canale viene registrato fino alla fine del programma in corso (più il margine) o finché non lo fermi, in **Video/Kastideo/Enregistrements**.

- I byte del flusso vengono copiati così come sono in un file **.ts**, senza perdita: il canale che stai guardando viene copiato dal relay (nessuna seconda connessione al fornitore); un altro canale viene scaricato direttamente, riconnettendosi se il flusso cade.
- Alla fine, il .ts viene convertito senza perdita in **MKV** (formato predefinito, Impostazioni > Registrazioni); se la conversione fallisce, il .ts viene conservato: si riproduce ovunque.
- I flussi HLS (.m3u8) e la riproduzione senza relay passano comunque dal motore video.
<!--/pc-->

## Programmare una registrazione {#programmer}

<!--mac-->
- Nella guida TV sotto il video, **fai doppio clic** su un programma futuro, oppure clic destro > **Programma registrazione**. Un punto rosso contrassegna i programmi programmati.
- Clic destro su un canale > **Programma una registrazione…** (o l'icona del calendario sotto il video): scegli un programma dalla guida o orari personalizzati.
- I **margini** prima e dopo (2 e 5 minuti per impostazione predefinita, regolabili) evitano di perdere l'inizio o la fine.
- All'ora programmata, la registrazione parte in background. Se stai guardando un altro canale, Kastideo chiede se interrompere la riproduzione; senza risposta, la registrazione parte dopo 60 secondi.
<!--/mac-->

<!--pc-->
- **Clic destro su un canale in diretta > Programma una registrazione…**, oppure il pulsante **Programma…** della schermata Registrazioni (poi scegli il canale: preferiti, recenti o ricerca).
  - **Programmi della guida**: i prossimi programmi del canale, con **Programma** (o **Registra** per quello in corso). Un segno di spunta indica quelli già programmati.
  - **Fascia oraria**: giorno, ora di inizio e di fine, titolo facoltativo — per un canale senza guida TV o per uno spettacolo specifico. Una fine precedente all'inizio termina il giorno dopo.
  - **Ripetizione** (elenco in alto a destra): **una volta**, **ogni giorno**, **dal lunedì al venerdì** o **ogni settimana**. L'occorrenza successiva viene aggiunta automaticamente; il pulsante ⟲ di una registrazione ripetuta nell'elenco interrompe la ripetizione.
- Dai dettagli di un programma futuro (guida TV, temi): **Programma registrazione**.
- Vengono aggiunti i margini prima e dopo (Impostazioni > Registrazioni). Kastideo deve essere aperto all'ora programmata: attiva **Avvia Kastideo all'accesso** se necessario (Impostazioni > Generali).
<!--/pc-->

## Scaricare un film o degli episodi senza guardarli {#telecharger}

<!--mac-->
- Clic destro su un film o un episodio > **Scarica** o **Scarica stanotte**, oppure il pulsante **Scarica** sotto il video.
- Per una serie: il pulsante **Scarica** nella sua pagina > la stagione mostrata o l'intera serie.
- I download vengono eseguiti **uno dopo l'altro** (coda). «Stanotte» inizia alle 2:00 per impostazione predefinita (regolabile).
- Puoi mettere in pausa, riprendere o annullare ogni download nella sezione Registrazioni.
- **Indicatore permanente**: finché un download è attivo, nella barra degli strumenti resta visibile un anello di avanzamento. Un clic apre i dettagli: avanzamento del film o episodio corrente, «episodio X di N», avanzamento della serie o del gruppo, velocità e **tempo rimanente stimato** (che si affina man mano che il download procede).
<!--/mac-->

<!--pc-->
Pulsante **Scarica** nei dettagli di un film (ora o **stanotte**), **Scarica la stagione** o l'icona di ogni episodio per una serie, clic destro > Scarica. Un download alla volta, ripreso dopo un'interruzione, messo in pausa durante la riproduzione (regolabile). I file vanno in **Video/Kastideo/Films** e **Séries/<serie>**.
<!--/pc-->

## Connessione unica: chi ha la priorità? {#priorite}

<!--mac-->
Il tuo abbonamento consente una sola connessione. Kastideo quindi fa una sola cosa alla volta e **ti chiede sempre** prima di interrompere qualcosa:

- Cambi canale durante una registrazione: Kastideo chiede se **interrompere la registrazione**.
- Avvii la riproduzione durante un download: il download viene **messo in pausa** e riprende da solo quando la riproduzione si ferma.
- I file già registrati possono essere guardati in qualsiasi momento, anche durante una registrazione in background.
<!--/mac-->

## Schermata delle registrazioni {#ecran-enregistrements}

<!--pc-->
Registrazione in corso (ferma), download (pausa, riprendi, annulla), registrazioni programmate e cronologia, file della cartella: un clic li riproduce, clic destro per mostrarli nella cartella o eliminarli.
<!--/pc-->

## Schede nella tua lingua {#fiches-langue}

<!--pc-->
Con una **chiave TMDB** (Impostazioni > Generali), titoli, trame, generi ed episodi provengono da TMDB, nella lingua dell'interfaccia. Quando l'unica trama disponibile è quella del fornitore in un'altra lingua (portoghese, spagnolo…), viene ripiegata: **Mostra la trama (portoghese)** la mostra comunque. Non compare nel banner né nell'elenco degli episodi.
<!--/pc-->

## Da sapere {#bon-a-savoir}

<!--mac-->
- Kastideo deve **restare aperto** e il Mac **acceso** per le registrazioni programmate e i download notturni. Kastideo impedisce la sospensione automatica durante l'attività e nell'ora precedente, ma non lo spegnimento o la sospensione manuali.
- Una **notifica di macOS** segnala l'inizio e la fine di registrazioni e download (si può disattivare).
- **Pulizia automatica** (facoltativa): le registrazioni più vecchie del numero di giorni scelto vengono spostate nel Cestino.
- Un avviso ti segnala quando lo spazio su disco sta per finire.
- I diritti di copia dipendono dalle condizioni del tuo fornitore: Kastideo registra per il tuo uso privato ciò che il tuo abbonamento ti offre già.
<!--/mac-->

## Pulire l'elenco delle registrazioni {#nettoyer-liste}

<!--mac-->
Nella sezione **Registrazioni** puoi **rimuovere dall'elenco le registrazioni terminate** (programmazioni, download e registrazione in corso non vengono mai toccati).

- **Una registrazione**: il pulsante cestino della riga, oppure clic destro > **Rimuovi dall'elenco…**.
- **Più registrazioni**: il pulsante **Seleziona**, spunta le righe (o **Seleziona tutto**), poi **Rimuovi la selezione**.
- **Tutto**: il pulsante **Svuota l'elenco…**.

Si apre quindi una finestra di dialogo. Per impostazione predefinita **viene pulito solo l'elenco**: il file resta nella cartella delle registrazioni e non ricomparirà nell'elenco. Spunta **Elimina anche il file o i file dall'archiviazione** per cancellarlo anch'esso (Cestino su Mac); viene poi mostrato lo spazio liberato. **Ricorda questa scelta** conserva la tua risposta per la volta successiva.

Dopo una semplice rimozione dall'elenco, un banner **Annulla** resta visibile per circa dieci secondi.

Se un file non esiste più nell'archiviazione, o non può essere eliminato, la rimozione prosegue comunque: una notifica ti avvisa e, con più avvisi, una finestra li elenca.
<!--/mac-->

# Organizzare e personalizzare

## Correggere un canale {#corriger}

<!--mac-->
Alcuni canali sono referenziati male dal fornitore (nome sbagliato, programmi sbagliati, logo mancante). Clic destro sul canale > **Modifica il canale…**:

- **Nome** e **numero** (usato per lo zapping per numero nell'interfaccia TV);
- **Logo**: un indirizzo di immagine, oppure **Scegli un file…** (l'immagine viene copiata in Kastideo);
- **Programmi della guida TV**: se i programmi mostrati sono sbagliati o mancano, cerca il canale giusto nell'elenco (guida del fornitore e guida di riserva); il programma in onda ora aiuta a riconoscerlo.

La correzione si applica solo a **questa versione** del canale (FHD, HD, SD… si correggono separatamente) e sopravvive agli aggiornamenti delle sorgenti. **Ripristina l'originale** la annulla.
<!--/mac-->

<!--pc-->
Clic destro su un canale > **Modifica il canale…**: nome, numero, logo (indirizzo di immagine o un file copiato in Kastideo) e canale della **guida TV** (ricerca tra le guide del fornitore e di riserva). La correzione si applica a questa versione del canale (HD, FHD…) e sopravvive a ogni aggiornamento. **Ripristina** torna all'originale.
<!--/pc-->

## Organizzare le categorie {#categories}

<!--mac-->
Non devi accontentarti dell'elenco e dell'ordine delle categorie del tuo fornitore. Apri **Vista > Gestisci le categorie…** (**⌥⌘C**), il pulsante accanto al titolo «Categorie» nella barra laterale, oppure fai clic destro su una categoria. Scegli la sezione (**Diretta**, **Film** o **Serie**), poi:

- **Riordinare**: trascina le categorie nell'elenco, oppure usa il menu **…** > **Sposta in cima / in fondo**. **Ordina A → Z** ordina tutto alfabeticamente.
- **Seleziona / deseleziona tutto**: la casella sopra l'elenco spunta o deseleziona in un colpo tutte le categorie elencate. Con una ricerca (per esempio «PT»), riguarda solo le categorie trovate: comodo per nascondere un intero paese in un colpo solo, poi mostrare solo quelle che vuoi.
- **Nascondere**: deseleziona una categoria (o clic destro > **Nascondi questa categoria** nella barra laterale). Una categoria nascosta scompare **ovunque**: barra laterale, elenchi di Diretta / Film / Serie, ricerca, Guida TV, interfacce Cinema e TV, banner in evidenza. I tuoi preferiti e recenti restano disponibili.
- **Nascondere per parola chiave**: digita per esempio «PAKISTAN» o «ARABIC»: ogni categoria il cui nome la contiene viene nascosta, comprese quelle che il fornitore aggiunge in seguito. Fai clic sulla croce di una parola chiave per annullare.
- **Rinominare**: la matita dà un nome più leggibile («FRANCE FHD | OTT» → «Francia HD»); **Nome originale** lo annulla.
- **Mostra tutto** mostra di nuovo le categorie nascoste; **Reimposta…** torna interamente all'organizzazione del fornitore.

Le nuove categorie aggiunte dal fornitore compaiono accanto alla loro vicina originale.
<!--/mac-->

<!--pc-->
- **Clic destro su una categoria** nella barra laterale: **Rinomina…**, **Sposta in cima**, **Sposta su**, **Sposta giù**, **Sposta in fondo**, **Nascondi questa categoria**, **Gestisci le categorie…**.
- **Impostazioni > Categorie** (o l'icona accanto a «Categorie»): per TV in diretta, film o serie — trascina per riordinare, deseleziona per nascondere ovunque, doppio clic per rinominare, **parole chiave** per nascondere in un colpo tutte le categorie che le contengono (es. «PAKISTAN»), **Ordina dalla A alla Z**, **Ripristina**.
- **Seleziona / deseleziona tutto**: la casella sopra l'elenco spunta o deseleziona in un colpo tutte le categorie elencate. Con la **ricerca** (es. «PT»), riguarda solo le categorie trovate: nascondi un intero paese in due clic, poi spunta solo quelle che vuoi.

Una categoria nascosta lo è ovunque: elenchi, ricerca, home, righe.
<!--/pc-->

## Correggere la scheda di un film o di una serie {#corriger-fiche}

Quando il poster, il titolo o la trama di un film o di una serie sono sbagliati (per esempio due film condividono lo stesso titolo), puoi **collegarlo alla scheda TMDB giusta** oppure **inserire tu stesso i dati**. Funziona per **I miei video** (cartelle, Jellyfin, Emby, Plex) così come per i film e le serie dell'**abbonamento IPTV**, su Mac, Windows, Linux e Android.

### Aprire la finestra

Clic destro (o pressione prolungata) sul film o sulla serie, poi **Correggi la scheda…**; il collegamento si trova anche in fondo alla pagina dei dettagli.

### Collegare a un codice TMDB

1. Su **themoviedb.org**, trova il film giusto. Il **numero** si trova nell'indirizzo della pagina: `themoviedb.org/movie/12345-hero` → **12345** (per una serie: `…/tv/1399-…`).
2. In Kastideo, inserisci quel numero, oppure **incolla l'indirizzo completo**, poi **Verifica**.
3. Compare un'anteprima (poster, titolo, anno, trama): se è quella giusta, **Usa questa scheda**.

È necessaria una [chiave TMDB](help:tmdb). Se l'indirizzo è quello di una serie mentre stai correggendo un film (o viceversa), Kastideo te lo segnala.

### Cercare per titolo

Sotto il codice, la ricerca per titolo e anno propone un elenco di schede: tocca quella giusta. Il numero TMDB è mostrato accanto a ogni risultato.

### Personalizzare a mano

**Personalizza la scheda a mano** permette di inserire un **titolo**, un **anno**, un **indirizzo del poster** (https://…) e una **trama**. Questi campi sostituiscono quelli del fornitore e di TMDB; i campi lasciati vuoti non cambiano nulla. Si combinano con un codice TMDB.

### Rimuovere una correzione

Nella finestra, **Rimuovi la correzione** torna alla ricerca automatica. **Impostazioni > Generali > Schede di film e serie** elenca inoltre ogni scheda corretta (**Schede corrette a mano**) con un pulsante **Rimuovi** per ciascuna.

### Backup

Le correzioni fanno parte del **backup della configurazione** (Impostazioni > Backup): seguono le tue esportazioni e importazioni da un dispositivo all'altro.

### Da sapere

- Per i film dell'abbonamento IPTV, la correzione si applica alla **pagina dei dettagli**; la miniatura nell'elenco mantiene l'immagine del fornitore.
- Per I miei video, viene aggiornato anche il poster nell'elenco.

## Ordinare i canali e le categorie {#arranger}

La modalità **Ordina** permette di mettere **i canali, i film o le serie di una categoria** nell'ordine che preferisci, e anche di riordinare **le categorie** stesse. È disponibile su **Windows, Linux e Android** (non ancora su Mac). Funziona sia con il dito sia con il mouse: l'elenco scorre normalmente e solo la **maniglia ⋮⋮** a sinistra sposta una riga.

### Riordinare gli elementi di una categoria

1. Apri una categoria nella barra laterale (per esempio «SPORT»).
2. Tocca il pulsante **Ordina** (frecce ↑↓) a destra del titolo dell'elenco.
3. **Tieni premuta la maniglia ⋮⋮** di una riga, poi **trascinala** nella nuova posizione. Per scorrere l'elenco, tocca un punto qualsiasi diverso dalla maniglia.
4. Tocca **Fine** quando l'ordine ti soddisfa. Viene salvato automaticamente.

I tre puntini a destra di una riga offrono:

- **Sposta in cima** e **Sposta in fondo** (comodo in un elenco lungo);
- **Sposta in un'altra categoria…**: scegli una categoria o digita il nome di una **nuova lista personale** (per esempio «Le mie scelte») per riunire canali di più categorie;
- **Rimetti nella categoria originale**.

In cima alla modalità Ordina:

- **A → Z** ordina per nome; **Per numero** ordina i canali per numero;
- **Ordine del fornitore** annulla il tuo ordine per questa categoria.

Ordinare non è disponibile durante una ricerca, né in Preferiti e Recenti (hanno un proprio ordine).

### Riordinare le categorie

Apri **Impostazioni > Categorie** (o il pulsante a destra del titolo «Categorie» nella barra laterale). Tieni premuta la grande maniglia ⋮⋮ a sinistra di una categoria e trascinala. **Reimposta** cancella anche gli ordini e gli spostamenti dei canali.

### Backup

Il tuo ordine, le liste personali e gli spostamenti fanno parte del **backup della configurazione** (Impostazioni > Backup): seguono le tue esportazioni e importazioni.

## Pagina iniziale per Diretta, Film e Serie {#page-depart}

Per impostazione predefinita, aprire **Diretta**, **Film** o **Serie** mostra tutti i canali o tutti i contenuti, a partire dalla prima categoria del fornitore. Puoi scegliere invece cosa mostrare per primo.

### Scegliere la pagina iniziale

<!--mac-->
1. Apri **Impostazioni (⌘,) > Generali > Pagina iniziale**.
<!--/mac-->
<!--pc-->
1. Apri **Impostazioni (Ctrl+,) > Generali > Pagina iniziale**.
<!--/pc-->
2. Per **Diretta**, **Film** e **Serie**, scegli separatamente:
   - **Tutti**: l'elenco completo (predefinito);
   - **Preferiti** o **Recenti**;
   - **Ultima visualizzata**: la categoria in cui eri l'ultima volta;
   - oppure **una categoria specifica** del fornitore.

### Dalla barra laterale

Fai **clic destro** su una categoria, poi **Imposta come categoria iniziale**. Lo stesso menu permette di **smettere di usarla** come categoria iniziale.

### Quando si applica?

Ogni volta che apri Diretta, Film o Serie da un'altra sezione (home, guida TV…), anche all'avvio. Una volta nella sezione, navighi liberamente: facendo clic su **Diretta**, **Film** o **Serie** nella barra laterale quando sei già lì, viene mostrato l'elenco completo.

Se la categoria scelta è nascosta, rinominata o non esiste più presso il fornitore, Kastideo mostra l'elenco completo. Sceglila di nuovo nelle Impostazioni.

## Più account: sorgente attiva, duplicati e diagnostica {#sources-multiples}

Quando hai **due o più account IPTV**, Kastideo ti permette di scegliere quello visualizzato, **senza disattivare** gli altri nelle impostazioni.

### Scegliere la sorgente attiva

- Su **Mac**, nella barra laterale compare un menu **Sorgente**. Su **Windows, Linux e Android**, il menu **Sorgente** si trova nella barra laterale (su telefono: nel menu a scomparsa).
- Scegli **Tutte le sorgenti** o un account specifico. Accanto a ogni nome, tre numeri: **canali · film · serie** restituiti dal fornitore.
- La scelta filtra **Diretta, Film, Serie, la ricerca e la guida TV**, e viene **ricordata** tra un avvio e l'altro.
- Le cartelle e i server di [I miei video](help:mes-videos) restano sempre visibili.

### Unire i duplicati

Con **Tutte le sorgenti**, un film o una serie forniti da più account (stesso titolo, stesso anno) viene elencato **una sola volta**. Deseleziona **Unisci i duplicati** per vedere tutto. I preferiti e i recenti già salvati continuano a funzionare.

### Perché due account dello stesso livello hanno film diversi?

I **canali** sono spesso identici, ma i **cataloghi di film e serie** dipendono dall'account: molti fornitori danno a ogni account pacchetti di video on demand diversi. Se i numeri differiscono, nella maggior parte dei casi dipende **dal fornitore**.

### Il pulsante Diagnostica

In **Impostazioni > Sorgenti**, il pulsante **Diagnostica** (stetoscopio) di un account mostra:

- lo stato dell'account (stato, scadenza, connessioni);
- per canali, film e serie: il numero **restituito dal fornitore**, il numero di categorie e il numero **effettivamente mostrato**;
- ciò che Kastideo **nasconde**: categorie nascoste, contenuti per adulti, duplicati uniti.

Se il «restituito dal fornitore» differisce tra i tuoi due account, la differenza viene dal fornitore. Il pulsante **Copia** ti permette di allegare il risultato a un messaggio al tuo fornitore.

## Preferiti e recenti {#favoris}

<!--mac-->
- Aggiungi un preferito con la stella nel pannello informazioni, con il clic destro o con **⌘D**.
- La sezione **Recenti** conserva gli ultimi 60 elementi che hai guardato.
- **Rimuovere dai recenti**: clic destro su un elemento > **Rimuovi dai Recenti** (oppure il tasto **⌫** sull'elemento selezionato nell'interfaccia Classica). Per più elementi, fai clic su **Modifica**, spunta gli elementi, poi **Elimina**; **Seleziona tutto** spunta l'intero elenco e **Svuota tutto** azzera la cronologia.
- Dopo un'eliminazione, un banner **Annulla** resta visibile per qualche secondo per ripristinare tutto.
- I recenti si possono svuotare anche nelle impostazioni, scheda **Generali**.
<!--/mac-->

<!--pc-->
Stella nella barra del player, tasto **F** oppure clic destro > Aggiungi ai preferiti. I recenti conservano gli ultimi 60 elementi aperti.

- **Modifica** (accanto al titolo «Recenti»): spunta gli elementi poi **Rimuovi la selezione**, oppure la croce di una riga per rimuoverla da sola; **Seleziona tutto** e **Svuota tutto** (per la sezione mostrata). **Fine** torna all'elenco.
- Clic destro su un elemento > **Rimuovi dai recenti**.
- Impostazioni > **Cronologie** > **Recenti** > **Cancella** li cancella tutti, in ogni sezione.
<!--/pc-->

## Avvisi e notifiche {#alertes}

<!--pc-->
- **Avvisami quando inizia** nei dettagli di un programma futuro (campanella nella guida).
- **Parole chiave** (Impostazioni > Registrazioni): un programma il cui titolo contiene una parola chiave genera un avviso, sui tuoi canali preferiti o su tutti.
- L'avviso compare in alto a destra in Kastideo con **Guarda**, e la finestra torna in primo piano se era ridotta a icona.
- **Notifiche di sistema** (Impostazioni > Generali > Notifiche, attive per impostazione predefinita): avvisi, inizio e fine delle registrazioni, download terminati o falliti compaiono anche nel centro notifiche di Windows o Linux, anche quando Kastideo è dietro un'altra finestra. Facendo clic sulla notifica, Kastideo torna in primo piano.
<!--/pc-->

## Aspetto {#apparence}

<!--pc-->
Impostazioni > **Aspetto**:

- **Tema**: **Scuro** (predefinito), **Chiaro** o **Come il sistema** (segue Windows o Linux). Il player, l'interfaccia TV, MultiVista, la schermata Home, le pagine dei dettagli e il banner in evidenza restano scuri, come su Mac.
- **Colore d'accento**: predefinito (blu Kastideo), blu, viola, rosa, rosso, arancione, verde o turchese — usato per selezioni, pulsanti, interruttori.
- **Densità dell'elenco** (interfaccia Classica): compatta, standard o ariosa.
- **Dimensione delle miniature** (interfaccia Cinema): piccola, media o grande.
- **Interfaccia** per tipo di contenuto e **banner in evidenza** (vedi [Tre interfacce](help:interfaces)).

Le modifiche si applicano subito, senza riavviare.
<!--/pc-->

# YouTube

## YouTube: sfogliare e riprodurre {#youtube}

La sezione **YouTube** (barra laterale, pulsante Home,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc-->) funziona in due passaggi: prima un **browser**, poi il **player** non appena scegli un video.

![Dal browser al player](img:youtube)

### Il browser

- **I miei canali**: incolla un link di canale o il suo @nome nel campo in alto per seguirlo. I suoi ultimi video compaiono in una riga, senza chiave e senza account. Per portare tutte le tue iscrizioni in una volta: [Importa le mie iscrizioni](help:youtube-import).
- **Ricerca**: digita la tua ricerca nello stesso campo (risultati con miniature, ordinati per pertinenza, data o visualizzazioni, altre pagine). Serve una **chiave API Google gratuita**: [la guida passo passo](help:youtube-cle).
- **Link incollati**: un video viene riprodotto, una playlist diventa la coda di riproduzione, un canale viene seguito.
- **Preferiti e cronologia**: clic destro su una miniatura; la cronologia conserva gli ultimi 80 video (con un pulsante per svuotarla).
- **Guarda più tardi**: clic destro su una miniatura per mettere da parte un video. Un video iniziato **riprende da dove eri rimasto** (una barra rossa mostra l'avanzamento); esce dall'elenco quando è stato visto fino in fondo.

### Il player

<!--mac-->
Facendo clic su un video, il player sostituisce il browser; l'elenco da cui provieni diventa la coda. I pulsanti Precedente / Successivo, **Riproduzione automatica del successivo**, **Ripeti**, **Muto** e **Apri su YouTube** si trovano in una barra che si nasconde da sola; **Esc** o **Browser di YouTube** ti riporta all'elenco.
<!--/mac-->
<!--pc-->
Facendo clic su un video, il player si apre in **una finestra propria** (Edge o Chrome su Windows, Chrome o Chromium su Linux in modalità «app»; altrimenti il tuo browser predefinito); l'elenco da cui provieni diventa la coda. I pulsanti Precedente / Successivo, **Riproduzione automatica del successivo**, **Ripeti**, **Muto** e **Apri su YouTube** si trovano in una barra che si nasconde da sola. Un banner in Kastideo ti ricorda il video corrente, con **Riapri la finestra**.
<!--/pc-->

La riproduzione IPTV si ferma mentre YouTube è in riproduzione (a meno che non sia in corso una registrazione).

> A proposito di pubblicità e del tuo account Google: vedi [Pubblicità, account e privacy](help:youtube-confidentialite).

## Importare le mie iscrizioni YouTube {#youtube-import}

YouTube non permette a un'app come Kastideo di accedere al tuo account. Google però permette di **esportare i tuoi dati**: chiedi solo l'elenco delle tue iscrizioni, un piccolo file `subscriptions.csv` che Kastideo legge **sul tuo computer**.

![I passaggi dell'importazione](img:takeout)

### Passaggio 1: chiedere l'esportazione a Google

1. Apri [Google Takeout](https://takeout.google.com/) dopo aver effettuato l'accesso all'**account Google** di cui vuoi le iscrizioni.
2. Fai clic su **Deseleziona tutto** (in cima all'elenco).
3. Scorri fino a **YouTube e YouTube Music** e spunta la casella.
4. Fai clic su **Sono inclusi tutti i dati di YouTube**, fai clic su **Deseleziona tutto**, spunta solo **iscrizioni**, poi **OK**.
5. In fondo alla pagina, fai clic su **Passaggio successivo**. Mantieni **Invia link per il download via email**, **Esporta una volta** e il formato **.zip**, poi fai clic su **Crea esportazione**.
6. Google prepara l'archivio (qualche minuto, a volte di più) e ti invia un'email. Fai clic su **Scarica i tuoi file** nell'email e salva il `.zip`.

### Passaggio 2: trovare il file

1. Apri il `.zip`: <!--mac-->doppio clic nel Finder<!--/mac--><!--pc-->clic destro > **Estrai tutto** (Windows) o doppio clic (Linux)<!--/pc-->.
2. Apri **Takeout** > **YouTube e YouTube Music** > **iscrizioni**.
3. Il file si chiama **subscriptions.csv** (oppure ha un nome nella lingua del tuo account, per esempio **abonnements.csv** se il tuo account è in francese).

### Passaggio 3: importarlo in Kastideo

1. Apri **YouTube** > **I miei canali**.
2. Fai clic su **Importa le mie iscrizioni…** e scegli il file.
3. Kastideo aggiunge i canali e carica i loro ultimi video (con molte iscrizioni, il primo aggiornamento può richiedere un minuto).

> I canali che segui già non vengono aggiunti due volte. Il file viene letto solo da Kastideo, sul tuo computer: non viene inviato nulla a Google né altrove, e Kastideo non accede mai al tuo account.

### Se non funziona

- **«Nessun nuovo canale trovato in questo file»**: non è il file giusto (per esempio la cronologia di visualizzazione), oppure i canali sono già seguiti. Torna al passaggio 2.
- **Nessuna email da Google**: controlla la cartella dello spam, oppure torna su [Google Takeout](https://takeout.google.com/): la sezione «Gestisci esportazioni» permette di scaricare di nuovo l'archivio.
- **Nessuna cartella «iscrizioni»**: al passaggio 1.4, verifica di aver spuntato la casella **iscrizioni**.
- Senza file, puoi seguire un canale alla volta incollando il suo link o il suo @nome: vedi [YouTube](help:youtube).

## Ottenere una chiave API di Google (ricerca) {#youtube-cle}

La **ricerca** su YouTube usa l'interfaccia ufficiale di Google («YouTube Data API v3») con **la tua chiave personale**. È **gratuita** e sufficiente per circa **100 ricerche al giorno**. Senza chiave tutto il resto funziona: seguire canali, riprodurre link incollati, preferiti, cronologia.

### Creare la chiave (5 minuti, una volta sola)

1. Apri la [console Google Cloud](https://console.cloud.google.com/) e accedi con un account Google.
2. In alto, fai clic sul selettore dei progetti > **Nuovo progetto**. Dagli un nome (per esempio «Kastideo»), fai clic su **Crea**, poi selezionalo.
3. Apri [la pagina di YouTube Data API v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com) e fai clic su **Abilita**.
4. Menu **API e servizi > Credenziali** > **Crea credenziali** > **Chiave API**.
5. Copia la chiave mostrata (una quarantina di caratteri che iniziano con «AIza»).
6. Facoltativo ma consigliato: **Modifica chiave** > **Limitazioni delle API** > **Limita chiave** > spunta **YouTube Data API v3**.

### Darla a Kastideo

1. Apri **Impostazioni > Generali > YouTube**.
2. Incolla la chiave in **Chiave API di Google** e conferma.
3. Torna a **YouTube**: la ricerca ora funziona.

<!--mac-->
La chiave viene conservata nel **portachiavi di macOS**, mai in chiaro su disco, e non viene mai pubblicata.
<!--/mac-->
<!--pc-->
La chiave viene conservata nel **deposito sicuro del sistema** e non viene mai pubblicata.
<!--/pc-->

> Quota: ogni ricerca consuma 100 delle 10.000 unità gratuite giornaliere. Se raggiungi il limite, Kastideo mostra «Errore API YouTube»; la ricerca torna il giorno dopo. Seguire canali e riprodurre video non usa questa quota.

### Quando qualcosa va storto

- **«Chiave API mancante»**: non è salvato nulla nelle Impostazioni.
- **«Chiave API non valida» / «Errore API YouTube»**: la chiave è stata copiata in modo errato, oppure il passaggio 3 (abilitare l'API) non è stato eseguito per **questo** progetto.
- **Errore di limitazione**: se hai limitato la chiave, verifica che **YouTube Data API v3** sia spuntata.

## Pubblicità, account e privacy {#youtube-confidentialite}

### Pubblicità

Kastideo usa il **player ufficiale di YouTube in «modalità privacy avanzata»** (youtube-nocookie.com), quello che Google offre ai siti web per incorporare i video: non installa alcun cookie di tracciamento e quindi non mostra pubblicità personalizzata, di solito nessuna.

**Questo non è un blocco pubblicitario**: nulla viene intercettato o aggirato, e YouTube resta libero di mostrare pubblicità, che finanzia i creatori.
<!--pc-->
Se il tuo browser ha un proprio blocco pubblicitario, si applica nella finestra del player.
<!--/pc-->

### Perché non posso accedere al mio account?

Il player con privacy avanzata non riconosce il tuo account: niente consigli personalizzati, niente iscrizioni sincronizzate automaticamente, niente YouTube Premium (che elimina la pubblicità su youtube.com, non in un player incorporato). È il prezzo di una riproduzione senza tracciamento. Per recuperare le tue iscrizioni, usa l'[importazione passo passo](help:youtube-import).

### Cosa conserva Kastideo

I tuoi canali seguiti, preferiti, cronologia (80 video), elenco «guarda più tardi» e punti di ripresa sono conservati **solo sul tuo computer**. Qualsiasi chiave API resta nel deposito sicuro del sistema. Non viene inviato nulla a Kastideo né ad altri che non siano YouTube / Google quando cerchi o riproduci un video.

# Impostazioni e manutenzione

## Scorciatoie da tastiera {#raccourcis}

<!--mac-->
- **⌘0**: Home
- **⌘1 a ⌘7**: Diretta, Film, Serie, Preferiti, Recenti, Registrazioni, Guida TV
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3**: interfaccia Classica / Cinema / TV (per il tipo di contenuto mostrato)
- Interfaccia TV: **↑ ↓** zapping, **←** pannello dei canali, cifre = numero del canale, **I** banner, **B** canale precedente, **G** guida TV, **H** home, **F** preferito, **M** muto
- **⌘↑ / ⌘↓**: elemento precedente / successivo (zapping)
- **⌘K**: riproduci / pausa
- **⌘[ / ⌘]**: indietro di 10 s / avanti di 30 s (film ed episodi)
- **⌘↩** o doppio clic sul video: modalità cinema (Esc per uscire)
- **⌘.**: ferma la riproduzione
- **⇧⌘R**: registra il canale che stai guardando / ferma la registrazione
- **⌥⌘L**: registro
- **⌘D**: aggiungi o rimuovi dai preferiti
- **⌘R**: aggiorna tutte le sorgenti
- **⌘,**: impostazioni e sorgenti
- **⌘?**: questa guida (si apre sulla pagina della schermata corrente)
- **⌘8**: I miei video, **⌘9**: YouTube
<!--/mac-->

<!--pc-->
- **Ctrl+0**: home — **Ctrl+1**: diretta — **Ctrl+2**: film — **Ctrl+3**: serie — **Ctrl+7**: guida TV — **Ctrl+Alt+M**: MultiVista — **Ctrl+,**: impostazioni
- **Spazio**: riproduci / pausa — **M**: audio — **F**: preferito — **R**: registra / ferma — **← / →**: −10 s / +30 s — **Ctrl+.**: ferma la riproduzione
- **Ctrl+Invio** o doppio clic sull'immagine: modalità cinema — **F11**: schermo intero — **Esc**: esci dalla modalità cinema, torna ai dettagli o alle righe
- Interfaccia TV: **↑ / ↓** zapping, **cifre** numero del canale, **←** pannello, **→ / I** banner, **B** canale precedente, **G** guida, **H** home
- MultiVista: **1 a 4** audio, **G** ingrandisci, **A** aggiungi, **Canc** rimuovi, **F** schermo intero, **Esc** esci
- **Ctrl+Alt+L**: registro
- **Ctrl+8**: I miei video, **Ctrl+9**: YouTube
- **F1**: questa guida (si apre sulla pagina della schermata corrente)
<!--/pc-->

## Impostazioni generali {#reglages}

<!--mac-->
- **Lingua** (scheda **Generali**): Kastideo è disponibile in **francese, inglese, spagnolo, tedesco, italiano e portoghese**. La lingua si sceglie al primo avvio, poi si può cambiare in **Impostazioni > Generali > Lingua** (oppure «Sistema» per seguire la lingua del Mac). La modifica si applica dopo il riavvio dell'app, che Kastideo si offre di fare al posto tuo. La guida e i menu seguono la lingua scelta; le note di rilascio restano in francese.
- **Aspetto** (scheda **Aspetto**): tema scuro (predefinito), chiaro o come il sistema; **colore d'accento** (Sistema, blu, viola, rosa, rosso, arancione, verde, turchese); **interfaccia** Classica o Cinema per ogni tipo di contenuto; **densità dell'elenco** (compatta, standard, ariosa) per l'interfaccia Classica; **dimensione delle miniature** (piccola, media, grande) per l'interfaccia Cinema.
- **Schede di film e serie** (scheda **Generali**): chiave API **TMDB** facoltativa (gratuita su themoviedb.org > Impostazioni > API; chiave v3 o token di lettura v4), conservata nel portachiavi. **Salva e verifica** la controlla. Senza chiave, i dettagli provengono dal tuo fornitore IPTV.
- **Aggiorna all'avvio**: ricarica le sorgenti il cui ultimo aggiornamento risale a più di 6 ore fa.
- **Cache**: Kastideo conserva una copia locale degli elenchi e della guida TV per avviarsi subito. **Svuota e ricarica** cancella questa copia e riavvia il caricamento.
<!--/mac-->

<!--pc-->
- **Generali**: lingua (al prossimo avvio), ripresa della riproduzione, relay del flusso, aggiornamento all'avvio, svuota i recenti, **connessioni simultanee** (MultiVista), **notifiche di sistema**, guida TV e guida di riserva, contenuti per adulti (nascosti per impostazione predefinita), chiave TMDB, **avvio e file .m3u**, **aggiornamenti**.
- **Aspetto**: tema, colore d'accento, densità dell'elenco, dimensione delle miniature, interfacce, banner in evidenza.
- **Sorgenti**: aggiungi, aggiorna, elimina, stato della guida.
- **Categorie**: ordine, nascondere, nomi, parole chiave.
- **Registrazioni**: cartella, formato, margini, download, differita, avvisi.
- **Backup**: esporta o importa la configurazione.
<!--/pc-->

## Ottenere una chiave TMDB (gratuita) {#tmdb}

<!--mac-->
TMDB (The Movie Database) è un database collaborativo di cinema e televisione. La sua chiave è **gratuita** per uso personale; permette a Kastideo di mostrare foto del cast, poster e sfondi in HD, il trailer e una trama tradotta.

1. Crea un account su **themoviedb.org** («Join TMDB»), poi confermalo con il link inviato per email.
2. Una volta effettuato l'accesso, apri **themoviedb.org/settings/api** (avatar > Impostazioni > API), oppure fai clic su **Ottieni una chiave gratuita** nelle impostazioni di Kastideo.
3. Fai clic su **Create**, scegli **Developer** e accetta le condizioni d'uso.
4. Compila il modulo: tipo di utilizzo **Personal**, nome dell'applicazione **Kastideo**, URL **https://github.com/jihemezes/kastideo**, una breve descrizione («Player IPTV personale, mostra i dettagli dei film»), poi i tuoi dati di contatto.
5. Invia: la pagina mostra una **API Key** (32 caratteri) e un **API Read Access Token** (lungo, inizia con «eyJ»). Kastideo accetta entrambi; la chiave API è più facile da copiare.
6. In Kastideo: **Impostazioni (⌘,) > Generali > Schede di film e serie**, incolla la chiave e fai clic su **Salva e verifica**. «Chiave valida ✓» lo conferma.
7. Riapri una pagina dei dettagli (oppure fai clic su **Aggiorna** in fondo): ora viene completata da TMDB.

La chiave è conservata nel portachiavi del Mac. **Rimuovi la chiave** torna alle sole informazioni del fornitore IPTV.
<!--/mac-->

<!--pc-->
Crea un account su themoviedb.org, poi **Impostazioni > API** e richiedi una chiave (uso personale). Incolla la «chiave API» (v3) o il «token di accesso in lettura» (v4) in Impostazioni > Generali, poi **Salva**. I dettagli diventano più ricchi (poster, cast, trailer, trame ed episodi nella tua lingua).
<!--/pc-->

## Poster e trame per i tuoi video personali {#tmdb-perso}

Per i film e le serie nelle tue **cartelle**, Kastideo può cercare il poster e la trama su **TMDB** (è necessaria una [chiave TMDB](help:tmdb)).

Poiché un nome di file non ha anno né etichetta, la ricerca è **prudente**: una corrispondenza viene accettata solo se il suo **titolo (o titolo originale) è esattamente il nome del file**. I nomi attaccati con maiuscole interne (**TearsOfSteel**) vengono separati (Tears Of Steel). I nomi interamente in minuscolo attaccato («bigbuckbunny») non vengono riconosciuti.

- Impostazione: in **Impostazioni**, sezione **Schede di film e serie**: **Cerca anche i video personali**. Attiva per impostazione predefinita; disattivala per evitare qualsiasi ricerca.
- Se una corrispondenza manca o è sbagliata (per esempio due film condividono lo stesso titolo), usa [Correggi la scheda](help:corriger-fiche): puoi collegare il film al **codice TMDB** giusto.

## Avvio e file .m3u {#demarrage}

<!--pc-->
Impostazioni > Generali > **Avvio e file**:

- **Avvia Kastideo all'accesso** (Windows e Linux) e **Avvia ridotto a icona** nella barra delle applicazioni: le registrazioni programmate e gli avvisi avvengono solo finché Kastideo è aperto.
- **Apri i file .m3u e .m3u8 con Kastideo** (facoltativo): facendo doppio clic su una playlist viene proposto di aggiungerla come sorgente (Impostazioni > Sorgenti); se Kastideo è già aperto, la finestra esistente la riceve. Se Windows continua ad aprire un altro programma, clic destro sul file > Apri con > Scegli un'altra app > Kastideo. Su Linux, l'associazione viene salvata nel tuo profilo (file `~/.config/mimeapps.list`); se sotto l'interruttore compare un messaggio di errore, ne indica la causa.

Entrambe le opzioni sono offerte anche dal programma di installazione di Windows (non spuntate per impostazione predefinita).
<!--/pc-->

## Backup e trasferimento {#sauvegarde}

<!--mac-->
Impostazioni > Generali > **Backup e trasferimento**:

- **Esporta la configurazione…** salva un file `Kastideo-configuration.json`: sorgenti (Xtream e playlist M3U per indirizzo), preferiti, recenti, categorie personalizzate (ordine, nascoste, nomi, parole chiave), interfacce scelte e chiave TMDB. Spunta **Includi le password** perché non occorra digitare di nuovo nulla; conserva il file in un luogo sicuro.
- **Importa la configurazione…** aggiunge il contenuto di un file: su un nuovo Mac, oppure da Kastideo per Windows e Linux (stesso formato). Le sorgenti già presenti vengono riconosciute e non viene eliminato nulla.

I server Jellyfin, Emby e Plex vengono esportati (con la loro password o il token se spunti **Includi le password**). Le playlist M3U aggiunte come file locali e le cartelle non vengono importate su un altro Mac (i file lì non esistono o vanno scelti di nuovo).
<!--/mac-->

<!--pc-->
Impostazioni > **Backup**: **Esporta la configurazione…** (sorgenti e relativa guida, password se vuoi, preferiti, recenti, categorie, interfacce, aspetto, numero di connessioni, contenuti per adulti, banner, chiave TMDB) e **Importa la configurazione…**. Il file è lo stesso di Kastideo per Mac: puoi passare da un computer all'altro in entrambe le direzioni. All'importazione non viene eliminato nulla. I server Jellyfin, Emby e Plex sono inclusi (anche password o token, se richiesti); anche le cartelle, con i loro percorsi (da correggere se differiscono su questo computer).
<!--/pc-->

## Aggiornamenti {#mises-a-jour}

<!--mac-->
Kastideo si aggiorna da solo grazie a **Sparkle**, lo strumento di riferimento per le app Mac distribuite fuori dall'App Store.

- **All'avvio** (qualche secondo dopo l'apertura), poi una volta al giorno se Kastideo resta aperto, Kastideo verifica discretamente se su GitHub è disponibile una nuova versione.
- In tal caso, un **banner** in cima alla finestra la annuncia — **mai mentre guardi o registri** (attende la fine della riproduzione). L'aggiornamento è **facoltativo**: **Aggiorna…** apre la finestra delle note di rilascio, poi **Installa l'aggiornamento** (Kastideo si chiude, installa e si riapre); **Più tardi** nasconde il banner fino al prossimo avvio; **Salta questa versione** smette di proporla (verrà proposta la successiva).
- Puoi verificare in qualsiasi momento con **Kastideo > Verifica aggiornamenti…**.
- Ogni aggiornamento è firmato: Kastideo rifiuta di installare un file che non proviene dal suo editore.

In **Impostazioni > Aggiornamenti**:

- **Verifica gli aggiornamenti all'avvio**: attiva o disattiva la verifica all'avvio e quella giornaliera.
- **Ricevi versioni di prova (beta)**: propone anche le versioni beta, che portano le novità prima ma possono essere meno stabili. Disattiva l'opzione per tornare alle versioni stabili al prossimo aggiornamento.

> Le versioni 0.1.0 e precedenti non possono aggiornarsi da sole: installa la 0.2.0 a mano una volta, e le successive arriveranno da sole.
<!--/mac-->

<!--pc-->
Kastideo cerca nuove versioni su GitHub all'avvio e poi ogni 12 ore (versioni preliminari per Windows / Linux, finché queste versioni sono in anteprima).

- Una nuova versione viene annunciata da un **banner in basso a destra**, solo quando non stai guardando nulla. **Visualizza** apre la finestra di aggiornamento con le note di rilascio; la croce la rinvia.
- **Installa e riavvia** scarica il file corrispondente alla tua installazione, poi:
  - **Windows, installato**: esegue il nuovo programma di installazione in modo silenzioso, poi riavvia Kastideo;
  - **Windows, portatile**: sostituisce i file della cartella dopo la chiusura, poi riavvia Kastideo;
  - **AppImage**: salva il nuovo AppImage accanto al vecchio, elimina il vecchio e lo avvia;
  - **Pacchetto .deb**: lo installa con apt (viene chiesta la tua password), poi riavvia Kastideo.
- Una registrazione in corso viene terminata correttamente prima della chiusura.
- **Salta questa versione**: non verrà più proposta (una verifica manuale la propone di nuovo).
- Impostazioni > Generali > **Aggiornamenti**: versione installata e tipo di installazione, **Verifica ora**, verifiche automatiche, **Novità delle versioni recenti**, pagina delle release su GitHub.
- Al primo avvio dopo un aggiornamento, la finestra **Novità** riassume le modifiche.
<!--/pc-->

## Installazione {#installation}

<!--pc-->
- **Windows (consigliato)**: esegui **Kastideo-…-windows-x64-setup.exe**. Per impostazione predefinita Kastideo si installa solo per te, senza diritti di amministratore (nella tua cartella AppData); il programma di installazione propone anche di installare per tutti gli utenti, un'icona sul desktop, l'apertura dei file .m3u e l'avvio all'accesso. Disinstallazione: Impostazioni di Windows > App > Kastideo.
- **Windows, portatile**: decomprimi l'archivio «windows-x64.zip» dove vuoi ed esegui **kastideo.exe** (non viene installato nulla; gli aggiornamenti sostituiscono i file della cartella).
- L'app non è firmata: se SmartScreen dice «Windows ha protetto il PC», fai clic su **Ulteriori informazioni** poi su **Esegui comunque**.
- **Zorin OS 17 / Ubuntu 22.04**: pacchetto «ubuntu22.04_amd64.deb» (doppio clic o `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: pacchetto «ubuntu24.04_amd64.deb».
- **Qualsiasi distribuzione e Raspberry Pi (64 bit)**: file AppImage; rendilo eseguibile (clic destro > Proprietà > Consenti l'esecuzione, oppure `chmod +x`) ed eseguilo.
<!--/pc-->

## Kastideo su Android e Android TV {#android}

Kastideo è disponibile anche per **telefoni e tablet Android** e per **Android TV** (Google TV, Chromecast con Google TV, Nvidia Shield, televisori Philips, Sony, TCL…). È la stessa app, con le stesse sorgenti, categorie, preferiti, guida, replay, registrazioni, MultiVista e YouTube, adattata al touch e al telecomando. Un unico file **APK** funziona su telefoni e televisori.

### Scegliere il file giusto

Nella pagina delle release di GitHub, cerca i file `Kastideo-…-android-….apk`:

- **arm64-v8a**: quasi tutti i telefoni, i tablet e i box TV recenti (la scelta giusta in caso di dubbio);
- **armeabi-v7a**: dispositivi più vecchi e alcuni box TV a 32 bit;
- **x86_64**: emulatori e alcuni tablet Intel;
- **universal**: tutti i processori, ma più grande.

### Installare senza disattivare la sicurezza

Android **non** richiede di disattivare le sue protezioni: chiede un'autorizzazione per **una sola app** (quella che apre l'APK: browser, gestore file o Downloader).

1. Scarica l'APK, poi aprilo.
2. Se Android dice «Per la tua sicurezza, l'installazione di app sconosciute è bloccata», tocca **Impostazioni** e attiva **Consenti da questa fonte** per l'app che stai usando (Chrome, per esempio). Le altre restano bloccate.
3. Torna indietro e tocca **Installa**.
4. Se **Play Protect** segnala un'app di uno sviluppatore sconosciuto, tocca **Ulteriori dettagli** poi **Installa comunque**: Kastideo non è pubblicato su Google Play ed è firmato dal suo sviluppatore, non da un editore registrato presso Google.

Tutti gli APK di Kastideo sono firmati con la stessa chiave: Android accetta quindi gli aggiornamenti sull'installazione esistente, senza perdere le tue impostazioni.

### Installare su Android TV

Un televisore spesso non ha né browser né gestore file. Tre metodi:

- **Downloader** (app gratuita dal Play Store del televisore): digita l'indirizzo di download dell'APK di GitHub, poi consenti a Downloader di installare app;
- **Chiavetta USB**: copia l'APK sulla chiavetta, collegala al televisore e aprilo con un gestore file (Solid Explorer, File Commander…);
- **Dal telefono**: invia l'APK con «Send Files to TV», oppure installalo con `adb install` se il debug di rete è attivo.

Kastideo compare poi nell'elenco delle app del televisore con il suo banner.

### Uso touch (telefono, tablet)

- **Menu ☰** in alto a sinistra: le sezioni (Diretta, Film, Serie, Preferiti, categorie…) si aprono in un pannello laterale.
- **Pressione prolungata** su un canale, un film o un episodio: il menu (preferito, registra, replay, decodifica software…), come un clic destro su un computer.
- **Nel player**: un tocco mostra o nasconde la barra; **doppio tocco** a sinistra = −10 s, a destra = +30 s, al centro = pausa; **scorrimento verticale** a destra = volume, a sinistra = luminosità; **scorrimento orizzontale** = avanzare o tornare indietro in un film.
- **Indietro** (gesto o pulsante di Android): chiude il player, poi torna alla schermata Home.
- Ruota il dispositivo in **orizzontale**: il canale corrente passa a schermo intero.

### Uso del telecomando (Android TV)

Su Android TV, Kastideo mostra schermate pensate per il telecomando: l'elemento selezionato è **evidenziato in arancione, ingrandito e luminoso**, come su Apple TV.

Su Android TV le **Impostazioni** si aprono in pannelli: il menu occupa i 2/5 di sinistra e il suo contenuto si sviluppa nei 3/5 di destra; un livello in più scorre a sinistra coprendo in parte il menu genitore (◀ per tornare). L'impostazione **Pagina iniziale** sceglie la categoria mostrata entrando in Diretta, Film o Serie. La Home mostra il logo accanto al nome e come filigrana.
- **Frecce**: spostano la selezione; **OK** conferma; **Indietro** torna indietro (lettore → episodi → scheda → elenco → home).
- **Home**: riquadri Diretta, Film, Serie (e I miei video), poi **Continua a guardare** (locandine di film ed episodi iniziati, **OK** apre la scheda), poi i pulsanti Cerca, Preferiti, Recenti, Guida TV, Registrazioni, MultiVista (se le sorgenti consentono due connessioni), Aiuto e Impostazioni.
- **Cerca, Preferiti, Recenti, Aiuto**: in Cerca, **OK** sul campo apre la tastiera della TV; conferma, poi **▼** per scorrere i risultati (canali, film, serie, i miei video). Preferiti e Recenti: griglia di locandine, **OK** apre l'elemento. Aiuto: questa guida, leggibile col telecomando (**▲ ▼** scorrono).
- **Film e serie**: categorie in alto (**←/→**), locandine sotto. **OK** apre la scheda; per una serie, **Episodi** mostra le stagioni (**←/→**) e gli episodi (**↑/↓**).
- **Diretta**: **↑ / ↓** o **Canale +/−** cambiano canale, i **numeri** inseriscono un canale, **←** apre l'elenco dei canali, **→** mostra il banner informativo. Nell'elenco, **↑ / ↓** scorrono i canali **senza cambiare canale** e **OK** avvia quello evidenziato; **←** passa alla colonna delle **categorie** (**↑ / ↓** cambiano categoria), **→** o **OK** tornano ai canali; **Menu** aggiunge ai preferiti.
- **Durante la riproduzione**: **OK** = pausa, **←/→** = −10 s / +30 s, **↑ / ↓** = volume; i tasti Play/Pausa e Avanti/Indietro veloce sono supportati.
- **Aggiungere una sorgente senza tastiera**: Impostazioni > **Aggiungi una sorgente con il telefono**. La TV mostra un **codice QR** e un codice di 4 cifre; dal telefono (stessa rete Wi-Fi) apri l'indirizzo, inserisci il codice e i dati della sorgente (Xtream o lista M3U). **Rimuovi una sorgente** è nello stesso posto.
- **Configurazione da telefono** (stessa pagina dell'aggiunta di una sorgente): oltre agli abbonamenti **Xtream** e **M3U**, il telefono invia un server **Jellyfin**, **Emby** o **Plex**, **cartelle** leggibili dalla TV (disco USB, condivisione di rete già montata) e la **chiave TMDB**. Si ritrovano in **I miei video**.
- **Registro**: pulsante Registro della home, o tasto **Menu**, **Info** o **rosso** del telecomando da qualsiasi schermata. **↑ / ↓** scorrono, **OK** mostra solo gli errori.
- **Guida TV** (pulsante della home): griglia canali × ore. **◀ ▶** passano da programma a programma, **▲ ▼** da canale a canale; **OK** guarda il programma in corso (o apre le opzioni se è passato o futuro); **Menu** apre le opzioni: **Guarda**, **Rivedi** (replay), **Registra**, **Avvisami**, **Programma registrazione**. **▲** dal primo canale raggiunge **Ora**, il **giorno** (compresi i giorni di replay) e il **filtro** (preferiti, recenti, temi, categorie). **Replay**: il pulsante **Replay** nell'intestazione (▲ dal primo canale) salta a ieri; i programmi passati dei canali con archivio hanno l'icona ↺ (**OK** per rivederli).
- **Opzioni del lettore**: durante la riproduzione, il tasto **Menu** apre le opzioni: **audio**, **sottotitoli**, **velocità** (film ed episodi), **formato dell'immagine**, **episodio successivo**, **elenco episodi**, **concatenamento automatico** e, in Diretta, **preferito** e **canale precedente**. **OK** applica la scelta.
- **Rendering video diretto**: sulla TV il video è decodificato direttamente sullo schermo (fluido anche in 4K su un televisore datato). Impostazioni > **Rendering video diretto** lo disattiva (al prossimo avvio); in questa modalità i sottotitoli non vengono mostrati.
- **Impostazioni** (pulsante della Home): **Sorgenti** (attiva, disattiva, aggiorna, sposta su, sposta giù, rimuovi), **Categorie** di Diretta, Film e Serie (mostra, nascondi, sposta, ordina dalla A alla Z), **Lingua**, **Riproduzione** (episodio successivo automatico, rendering diretto, replay, decodifica software, relay), **Guida TV** (apertura, guida di riserva, ricarica), **Chiave TMDB** (con la tastiera della TV), **Aiuto** e **Registro**.
- **Stile di visualizzazione** (Impostazioni > **Stile di visualizzazione**): per tipo di contenuto. **Diretta**: *TV* (canale a schermo intero), *Classico* (griglia dei canali per categoria, predefinito) o *Cinema* (banner e righe di canali); **Film** e **Serie**: *Classico* (griglia) o *Cinema* (predefinito; banner dell'elemento selezionato, poi righe Continua a guardare, Preferiti, Recenti e categorie; **◀ ▶** in una riga, **▲ ▼** tra le righe, **OK** apre la scheda o avvia il canale).


**Scheda film / serie su Android TV**: la riga dei pulsanti scorre con la selezione (▶ raggiunge tutti i pulsanti) e la scheda mostra sfondo, slogan, durata, voto, paese, regista e cast. Questi dati arrivano da TMDB: senza chiave (Impostazioni > Chiave TMDB) la scheda resta limitata e viene segnalato.

**«App non installata» installando un APK a mano**: Android rifiuta un APK con numero di versione inferiore a quello installato. Fino ad android28, gli APK a 64 bit (arm64-v8a) avevano un numero più alto di quelli a 32 bit (armeabi-v7a): installare un v7a sopra un arm64 falliva. Da android29 tutti gli APK hanno lo stesso numero e si installano l'uno sopra l'altro. Se il messaggio compare ancora, disinstalli Kastideo (Impostazioni Android > App) poi installi l'APK; l'app installata si aggiorna con il file giusto per la sua architettura (32 o 64 bit).

**Aggiornamento, sottotitoli e download su Android TV**: una nuova versione si apre in una pagina a parte (Installa e riavvia, Più tardi, Ignora questa versione) raggiungibile direttamente con il telecomando. Durante un film o un episodio, **OK** apre la barra delle opzioni: sottotitoli (scelta della lingua o **Nessuno**), audio, velocità, formato e **Scarica** (il file va nella cartella Film / Serie e si segue in **Registrazioni**). I sottotitoli sono **disattivati all'avvio** per impostazione predefinita; Impostazioni > Riproduzione > Sottotitoli > **All'avvio** permette di scegliere Nessuno, la lingua dell'interfaccia o Automatico. L'alone attorno all'elemento selezionato è stato rimosso e la modalità Cinema non ha più il banner: il logo Kastideo arrotondato appare come filigrana dietro le locandine. **Serie**: l'elenco degli episodi scorre con la selezione (mai fuori schermo); ▲ dal primo episodio raggiunge l'intestazione (◀ ▶ cambiano stagione, OK scarica l'intera stagione); ▶ su un episodio raggiunge la sua icona di download, OK lo aggiunge alla coda.

**Categorie su Android TV**: Impostazioni > Categorie permette di mostrare, nascondere, spostare su o giù le categorie senza attese: le scelte sono salvate subito, ma gli elenchi vengono ricalcolati solo **uscendo dal menu Categorie** (◀ o Indietro), evitando lunghe attese con un catalogo grande.

**Cronologie**: Impostazioni > **Cronologie** (Android TV: Impostazioni > Cronologie) cancella, dopo conferma, i **Recenti**, i **Visti e la ripresa** (segni «visto» e posizioni) e la **cronologia YouTube**, uno alla volta o con **Cancella tutto**. Preferiti, sorgenti e impostazioni non vengono toccati. Con la sincronizzazione iCloud della ripresa o un server Jellyfin / Emby / Plex, le posizioni possono tornare da un altro dispositivo: cancellale anche lì.

**Cinema su Android TV: «Mostra tutto»**: ogni fila della modalità Cinema (Riprendi, Preferiti, Recenti, categorie) inizia e finisce con una miniatura **Mostra tutto (N)**; **OK** apre tutti i titoli della fila in una griglia. In essa, ▲ dalla prima riga raggiunge l'**Ordinamento** (◀ ▶: ordine del fornitore, A–Z, aggiunti di recente, anno); **Indietro** torna alla fila. Oltre 25 categorie, l'ultima fila **Tutte le categorie** elenca le altre. Il menu Cronologie di Android TV non propone più la cronologia YouTube (nessun lettore YouTube su TV).

**Nessun audio su Android TV?** Apra Impostazioni > Riproduzione > **Diagnostica audio** (dopo aver avviato un canale): mostra volume, traccia audio, codec, formato del flusso e quello inviato al televisore. **Uscita audio** permette di scegliere Stereo (predefinito, il più sicuro via HDMI), Automatico (multicanale) o Passthrough Dolby / DTS (amplificatore o soundbar). Se i valori sono corretti ma non esce nulla, controlli il cavo HDMI, il volume del televisore (gli altoparlanti possono essere deboli) e l'uscita audio del box nelle impostazioni Android.

**Registrazione, sottotitoli, MultiVista e visto / non visto su Android TV**

- **OK durante la riproduzione** (film, episodio, registrazione, canale) apre la barra delle opzioni in basso: pausa, −10 s / +30 s, audio, sottotitoli, impostazioni dei sottotitoli (dimensione, colore, posizione, ritardo), velocità, formato dell'immagine, episodio successivo, registra, MultiVista. ▲ ▼ o Indietro la chiudono.
- **Sottotitoli**: il «Rendering video diretto» (fluido in 4K) non li mostra; scegliendo «Sottotitoli» si propone di passare al rendering classico (Kastideo si chiude: riaprilo).
- **Registrare**: Menu > Registra questo canale, o Guida TV > Programma la registrazione (Kastideo deve essere aperto e il televisore acceso). Impostazioni > Registrazioni: supporto di archiviazione (memoria interna, chiavetta USB o scheda SD rilevata: Kastideo vi crea la sua cartella), durata predefinita, formato, eliminazione automatica delle vecchie (per età o spazio massimo). Home > Registrazioni: riproduci, elimina, annulla una programmazione.
- **MultiVista**: Home > MultiVista, o Menu > MultiVista durante una diretta. Compare se le sorgenti consentono almeno due connessioni in totale (Impostazioni > Sorgenti > la sorgente > Connessioni simultanee). OK su un riquadro: ascolta, cambia canale, ingrandisci, schermo intero, rimuovi.
- **Visto / non visto**: tasto Menu su un episodio dell'elenco, o pulsante «Segna come visto» nella scheda di un film o di una serie.
- **Qualità massima** (Impostazioni > Riproduzione): per i canali offerti in più versioni (SD, HD, Full HD, 4K), sceglie la versione più alta che non supera il limite. «Nessun limite» mantiene il comportamento abituale (Full HD).

### Differenze rispetto al computer

- **Video locali (galleria)**: Impostazioni > Sorgenti > **Aggiungi i video della galleria** (oppure Aggiungi una sorgente > **Galleria** per **scegliere gli album**: Fotocamera, Screenshot…). I video del telefono compaiono in **I miei video** con la loro miniatura, ordinati per data; un film con il nome corretto (titolo esatto) ottiene il suo poster e la sua trama da TMDB. Android chiede l'accesso ai video: da Android 14 puoi consentire solo una **selezione** (pulsante «Scegli altri video…»). Nulla viene copiato o inviato altrove.
- **Cast**: su Android, la trasmissione verso un Chromecast o un televisore usa la **modalità diretta**: l'indirizzo del flusso viene inviato così com'è al televisore (i canali passano a HLS «.m3u8»). I file locali (I miei video) non possono essere trasmessi. La conversione con ffmpeg disponibile sui computer non è disponibile.
- **Registrazioni e download** sono conservati nella cartella dell'app (`Android/data/fr.jmezes.kastideo/files/Movies`, visibile dal gestore file). Android può arrestare un'app in esecuzione in background: mantieni Kastideo aperto e il dispositivo collegato all'alimentazione durante una registrazione. Una registrazione programmata parte solo se Kastideo è in esecuzione all'ora prevista.
- **Nessun avvio all'accesso** e nessuna associazione dei file .m3u: aggiungi le tue playlist in Impostazioni > Sorgenti.
- **YouTube** si apre nel browser del dispositivo.

### Aggiornamenti

Kastideo cerca nuove versioni Android su GitHub. Quando ne viene proposta una, **Installa** scarica l'APK e Android ti chiede di confermare. La prima volta, Android ti chiede anche di consentire a Kastideo di installare app (l'impostazione si apre da sola). Dopo l'installazione dell'aggiornamento, **riapri Kastideo**: Android chiude l'app durante l'installazione.

### Se qualcosa va storto

- **«App non installata»**: è già installata un'altra copia di Kastideo firmata con una chiave diversa; disinstallala prima.
- **«Errore di analisi» o «App non compatibile»**: file sbagliato per il tuo processore; prova l'APK **universal**.
- **Immagine bloccata**: vedi la pagina «Immagine bloccata: decodifica software».
- **Il Registro di riproduzione** (Impostazioni) conserva i dettagli degli errori di riproduzione.

## Kastideo Compat: Mac più vecchi (macOS 12 e 13) {#mac-compat}

La versione **Mac** di Kastideo richiede **macOS 14 Sonoma** o successivo. Per i Mac più vecchi, **Kastideo Compat** è la versione «Windows / Linux» ricostruita per Mac: **macOS 12 Monterey e successivi**, Intel o Apple Silicon.

**Installazione.** Scarica `Kastideo-Compat-…-macos.dmg` dalla pagina [Releases](https://github.com/jihemezes/kastideo/releases) (versioni preliminari il cui numero termina con `-desktopN`), aprilo e trascina **Kastideo Compat** in **Applicazioni**. L'app è firmata e autenticata (notarizzata) da Apple. Può essere installata **accanto** alla versione nativa.

**Cosa cambia rispetto alla versione Mac nativa.**

- L'interfaccia e le funzioni sono quelle della versione Windows e Linux (motore di riproduzione mpv): diretta, guida TV, temi, MultiVista, registrazione, film e serie, YouTube…
- Le scorciatoie usano il tasto **Comando** (⌘) al posto di Ctrl: ⌘1, ⌘2, ⌘3… per le sezioni, ⌘, per le impostazioni, ⌘K per la pausa.
- **Nessun aggiornamento automatico**: il banner di nuova versione apre la pagina di download.
- **Trasmettere su un televisore** richiede **ffmpeg** (per esempio `brew install ffmpeg` con Homebrew). Senza ffmpeg, tutto il resto funziona normalmente.
- Le registrazioni sono conservate in **Film > Kastideo**.
- L'avvio all'accesso e l'associazione dei file .m3u non sono offerti.

Impostazioni e sorgenti si possono spostare tra le versioni con **Backup e trasferimento**.

## Kastideo su iPhone e iPad {#ios}

**Kastideo per iPhone e iPad** (iOS 17 o successivo) è distribuito tramite **TestFlight**, il servizio di Apple per provare le app prima del rilascio. Non c'è alcun file da installare a mano: ricevi un invito, installi l'app **TestFlight** dall'App Store, poi **Kastideo** da TestFlight. Gli aggiornamenti arrivano tramite TestFlight.

**Primo avvio.** Leggi e accetta l'avviso legale. Nella schermata Home, tocca **Aggiungi una sorgente** (Xtream Codes o lista M3U), oppure vai su **Impostazioni > Importa la configurazione…** per portare le tue sorgenti, i preferiti e le categorie da Mac, Windows, Linux o Android (vedi «Backup e trasferimento»). Suggerimento: salva il file di configurazione in **iCloud Drive** per ritrovarlo su tutti i tuoi dispositivi. Per provare senza abbonamento, tocca **Prova la demo**: Kastideo aggiunge alcuni video liberi da diritti.

**Cosa offre l'app.**

- **Home**: su uno sfondo sfumato con il logo, i grandi riquadri **Diretta, Film, Serie, YouTube** e **I miei video** (se hai una galleria, una cartella o un server), con il numero di elementi; sotto, i pulsanti **Riprendi, Recenti, Preferiti, Guida TV** e **Registrazioni**, e un campo di ricerca in alto. **Riprendi / Recenti / Preferiti** aprono una pagina a griglia: tieni premuto un elemento o tocca **Seleziona** per rimuoverne diversi, **Svuota tutto** nel menu ⋯ e **Annulla** subito dopo una rimozione.
- **Barra inferiore**: **Home** (torna alla schermata Home da qualsiasi schermata), **Contenuti** (sorgenti, galleria, categorie, pagine dei dettagli TMDB, YouTube, iCloud, backup), **App** (riproduzione, MultiVista, registrazioni, replay, Cinema, aspetto, informazioni) e **Guida**. I riferimenti «Impostazioni > …» in questa pagina appartengono a una di queste due famiglie.
- **MultiVista in verticale**: quando lo schermo è tenuto in verticale, gli schermi della MultiVista vengono **impilati** (uno sopra l'altro, a tutta larghezza) invece che affiancati; in orizzontale viene mantenuta la disposizione scelta.
- **Apple TV** (beta): riceve la tua configurazione dall'iPhone (Impostazioni > Backup > Invia all'Apple TV), badge «visto»; guida che si riapre all'ultima posizione (impostazione); la stessa app esiste per Apple TV (tvOS 17) — viste Classica, Cinema e TV (Diretta), scelte per tipo di contenuto (pulsante «Vista» o Impostazioni > Vista); Home a riquadri (come su iPad), I miei video (Emby, Jellyfin, Plex), Diretta, Film, Serie, una Guida TV a griglia oraria (finestra di 3 h, replay dei programmi) e un player controllato dal telecomando (↑ / ↓ cambiano canale; clic = tracce audio, sottotitoli, velocità, ultimo canale, numero del canale; episodio successivo automatico). Scheda Ricerca, preferiti (pressione prolungata), timer di spegnimento. Impostazioni: sorgenti modificabili, pagina iniziale, categorie, zapping (con conferma o diretto). Aggiungi sorgenti da un telefono (codice QR + codice a 4 cifre, Impostazioni > Aggiungi da un telefono; il modulo si adatta al tipo di sorgente e accetta la chiave TMDB) oppure con la tastiera; la sincronizzazione con iCloud Drive non è disponibile su Apple TV.
- **Visti e guida**: badge sui poster visti, «Segna come visto» (dettaglio, pressione prolungata su un episodio, stagione); impostazione «All'apertura della guida» (Impostazioni > Replay).
- **Categorie (Diretta, Film, Serie)**: nella vista Elenco o Griglia, la **barra in alto** (Tutti, Preferiti, Recenti, poi ogni categoria) cambia categoria con un tocco; il pulsante ▦ a sinistra apre l'**elenco completo** con ricerca e numero di elementi.
- **Diretta**: il pulsante in alto a sinistra cambia la visualizzazione — **Elenco** (canali con programma in corso, ricerca, categorie, preferiti; scorri un canale verso sinistra), **Cinema** (un banner «in evidenza», righe «in onda ora» per tema, «Da rivedere», recenti, preferiti, una riga per categoria), **Temi** (Sport, Notizie, Film…: in onda ora, stasera, tutti i canali; pressione prolungata per cambiare il tema di un canale) e **Guida TV**.
- **Guida TV**: una **griglia** come su Mac — il giorno come linea temporale orizzontale, una riga per canale, **colonna dei canali** e **ore sempre visibili**, indicatore rosso «adesso», programma in corso in arancione. Trascina in entrambe le direzioni, **pizzica per ingrandire** la scala temporale (oppure Menu > Scala temporale). Scegli il giorno (fino a 14 giorni passati a seconda di Impostazioni > Replay, e 3 in avanti) e tocca un'ora per andarci. Tocca un programma per la sua pagina (**Guarda in diretta**, **Replay**, **Ricordamelo**, preferito); la pressione prolungata offre le stesse azioni. Il menu filtra per **preferiti, recenti, tema o categoria**, e torna alla vista **Fasce** (una riga per canale all'ora scelta).
- **Replay**: sui canali contrassegnati con ↺, **rivedi** un programma dall'archivio del fornitore (dettagli del programma, oppure pressione prolungata su un canale > Rivedi). Nel player, **Torna alla diretta**; quando un replay finisce, torni automaticamente alla diretta (regolabile). Impostazioni > Replay: giorni passati, correzione oraria se un replay parte all'ora sbagliata.
- **Film** e **Serie**: visualizzazione **Cinema** (banner «in evidenza» a scorrimento, riprendi, recenti, preferiti, una riga per categoria — prima la **categoria iniziale** (Impostazioni > Organizzazione) —, filtro per paese come su Mac) oppure **Griglia** (l'intero catalogo); ricerca, pagina dei dettagli con trama, riprendi da dove eri rimasto, stagioni ed episodi. Impostazioni > Visualizzazione Cinema: contenuto e velocità del banner.
- **Player**: tocca per mostrare i controlli. **Gesti**: doppio tocco a sinistra = −10 s, a destra = +30 s, al centro = pausa; **scorrimento verticale** a destra = volume, a sinistra = luminosità; **scorrimento orizzontale** = spostarsi in un film (anteprima del tempo), oppure **cambiare canale** in diretta. L'altoparlante in basso regola il **volume** e **silenzia / riattiva l'audio**; il badge in alto a destra (colore di ricezione, HD / 4K) apre le **informazioni sul flusso**: risoluzione, bitrate, fotogrammi al secondo, fotogrammi persi, interruzioni. Per un film o un episodio, la barra mostra il tempo trascorso, il **tempo rimanente** e l'**ora di fine**. In diretta, il **programma in corso** (barra di avanzamento) e il successivo vengono mostrati sotto il nome del canale, e i pulsanti |◀ ▶| passano al canale precedente / successivo della categoria. Il pulsante ⋯ offre la **velocità di riproduzione** (da 0,5× a 2×), il **formato dell'immagine** (adatta, riempi lo schermo, 16:9, 4:3), l'**ultimo canale** guardato e, per una serie, l'**elenco degli episodi**; il pulsante **Successivo** avvia l'episodio successivo, e gli episodi **si susseguono** (Impostazioni > App > Riproduzione).
- **I miei video**: il pulsante in alto a destra **ordina** (nome A→Z / Z→A, data, dimensione, durata), **raggruppa** (menu Raggruppa per: sorgente, categoria / cartella / album, tipo, anno o mese di aggiunta — **più criteri insieme**, per es. Sorgente poi Categoria, con sezioni comprimibili; l'ordinamento si applica all'interno di ogni sezione) e **filtra** (tipo, visione: da guardare / in corso / visto / preferiti, sorgente). L'ordinamento per dimensione misura i file la prima volta; i video di dimensione sconosciuta (server) vanno in fondo. Le tue scelte vengono ricordate.
- **Categorie**: Impostazioni > Gestisci le categorie — **Deseleziona tutto / Seleziona tutto** in cima all'elenco (comodo per tenere solo poche categorie), ordine (trascina), nascondi, rinomina, nascondi per parola chiave (per es. PAKISTAN), ordina A→Z, reimposta; Paesi e lingue per la visualizzazione Cinema. Per riordinare i **canali** di una categoria: Diretta in vista elenco, scegli la categoria, menu in alto a destra > «Riordina i canali…».
- **Modificare un canale** (pressione prolungata): nome, numero, logo (indirizzo web o foto), tema, canale della guida TV associato quando la guida è sbagliata.
- **Aspetto**: tema, colore d'accento, dimensione dei poster, densità dell'elenco, visualizzazione predefinita per Diretta, Film e Serie.
- **Avvio**: scheda mostrata all'avvio, e pagina iniziale di Diretta, Film e Serie (tutti, preferiti, recenti, ultima visualizzata o una categoria).
- **Modificare una sorgente**: Impostazioni > Sorgenti, tocca una sorgente (oppure scorrila > Modifica) per cambiarne il nome, l'indirizzo, le credenziali (password o token vuoti = mantenuti), la guida TV o le cartelle, e provare la connessione di un account Xtream.
- **Sincronizzazione iCloud**: Impostazioni > **iCloud**. Ritrova sorgenti, preferiti, ripresa della riproduzione… su iPhone, iPad e Mac tramite una cartella di iCloud Drive. Vedi la pagina [Sincronizzare con iCloud](#icloud).
- **Video locali (galleria)**: Impostazioni > **Aggiungi i video della galleria** (oppure Aggiungi una sorgente > Galleria dell'iPhone per **scegliere gli album**: Fotocamera, Screenshot…). I video compaiono in Film, sotto **I miei video**, con la loro miniatura, ordinati per data di ripresa; un film con il nome corretto (titolo esatto) ottiene il suo poster e la sua trama da TMDB. iOS chiede l'accesso alle tue foto: se consenti solo una **selezione**, compaiono solo quei video (Impostazioni > Video locali > Scegli altri video…). Un video conservato solo su iCloud viene scaricato prima della riproduzione. Nulla viene copiato o inviato altrove. Impostazione: aggiorna all'apertura dell'app.
- **Pagine TMDB**: con una chiave TMDB gratuita (Impostazioni > Schede di film e serie), la pagina di un film o di una serie mostra il poster in HD, la trama tradotta, i generi, la valutazione, il cast con le foto e il trailer, e il banner in evidenza propone **le tendenze della settimana** presenti nel tuo catalogo. Una pagina è sbagliata? Sulla pagina, **Correggi la scheda…**: incolla il numero o l'indirizzo della pagina di themoviedb.org, cerca per titolo, oppure digita a mano titolo, anno, poster e trama. **Rimuovi la correzione** torna alla pagina automatica; l'elenco delle correzioni è nelle Impostazioni.
- **Più abbonamenti**: Impostazioni > Abbonamenti per mostrare una sola sorgente senza disattivare l'altra, unire i duplicati tra account e **Diagnostica** di una sorgente (scorrila verso sinistra).
- **Registrare la TV in diretta**: durante un canale in diretta, il pulsante rosso rotondo nel player lo registra (arresto automatico regolabile). I file .ts si trovano nell'**app File > Su questo iPhone > Kastideo > Enregistrements**; riproducili in Kastideo o VLC, condividili o eliminali (scorrendo). La registrazione programmata non è possibile su iPhone (l'app non può risvegliarsi da sola): usa gli avvisi o il Mac.
- **Scaricare** un film o un episodio: il pulsante ↓ nella sua pagina (oppure «Scarica la stagione»). I download proseguono con l'app chiusa; metti in pausa, riprendi ed elimina in **Registrazioni** (icona del vassoio in alto a destra, o Impostazioni). I file vanno in File > Kastideo > Téléchargements. I download vengono eseguiti **uno alla volta** (una stagione procede episodio dopo episodio, gli altri mostrano «In attesa»). Molti fornitori consentono una sola connessione: un download può interrompere la riproduzione in corso.
- **Diretta in differita**: metti in pausa il canale in diretta, continua a essere memorizzato. Torna indietro di 10 s, avanti di 30 s, trascina la linea temporale, accelera (da ×1,25 a ×2) e tocca **Torna alla diretta**. Durata massima e velocità: Impostazioni > Diretta in differita.
- **Avvisi sui programmi** (Impostazioni): per parola chiave, per tema sui tuoi canali preferiti, oppure «Avvisami all'inizio» nella pagina di un programma. Sono notifiche dell'iPhone, ricevute anche con l'app chiusa; tocca una notifica per aprire il canale. Consenti le notifiche quando iOS lo chiede.
- **I miei video**: Impostazioni > Aggiungi una sorgente > **Jellyfin, Emby, Plex** o **Cartelle di video** (iPhone, iCloud Drive, unità USB, NAS aggiunto in File). In Film e Serie, il pulsante in alto a destra sceglie **Tutti / IPTV / I miei video**.
- **YouTube** (scheda YouTube, o il riquadro della Home): segui i canali (incolla il loro link o @nome nel campo di ricerca, senza chiave né account), incolla il link di un video o di una playlist per riprodurlo, **cerca** con la tua chiave API Google gratuita (Impostazioni > YouTube, passaggi inclusi), metti da parte i video **per dopo** (pressione prolungata), aggiungi preferiti, ritrova la tua **cronologia** e la posizione di ripresa (barra rossa sulla miniatura). Importa le tue iscrizioni da un'esportazione di **Google Takeout** (subscriptions.csv). La riproduzione usa il player ufficiale di YouTube in «modalità privacy avanzata»; non è un blocco pubblicitario. Avviare un video interrompe la riproduzione IPTV.
- **MultiVista**: più canali contemporaneamente (da 2 a 4 schermi), come su Mac. Viene offerta solo se le tue sorgenti consentono almeno due flussi simultanei: imposta il numero di connessioni di ogni abbonamento in **Impostazioni > MultiVista** (1 per la maggior parte; una lista pubblica ne consente 4). Aprila con il pulsante ▦ in **Diretta** o nel player (il canale corrente viene aggiunto). Ogni schermo è riservato a una sorgente; scegli i canali, la disposizione (affiancati, impilati, griglia, **uno grande + miniature trascinabili**) e il numero di schermi dal menu in alto. Tocca uno schermo per dargli l'audio, doppio tocco su una miniatura per ingrandirla, pressione prolungata per cambiare canale, sorgente o rimuovere lo schermo. Aprire la MultiVista interrompe la riproduzione principale (a meno che non sia in corso una registrazione).
- **Player a schermo intero**: tocca l'immagine per mostrare i controlli, trascina la barra per spostarti, scegli la traccia audio e i sottotitoli. Chiudilo con la freccia: la riproduzione continua, con un **mini player** sopra la barra delle schede. L'audio continua con lo schermo bloccato. Tornare alla **Home** (pulsante Home della barra delle schede) **ferma la riproduzione**: niente più audio in sottofondo. Anche un canale **in pausa** viene chiuso quando esci dall'app, per liberare la connessione presso il fornitore.
- **AirPlay**: il pulsante del player invia l'audio a un Apple TV o a un HomePod; per il video, usa la duplicazione dello schermo di iOS.
- Stesso motore di riproduzione (VLC) e stesse impostazioni di buffer del Mac; relay del flusso per i fornitori che rifiutano le connessioni dirette.

**Non ancora su iPhone / iPad**: picture in picture (non disponibile con l'attuale motore di riproduzione). Una versione per **Apple TV** è prevista più avanti.

Se la riproduzione fallisce: **Impostazioni > Informazioni > Condividi il registro di riproduzione**.
## Sincronizzare con iCloud (iPhone, iPad, Mac) {#icloud}

Kastideo può mantenere **i tuoi dispositivi Apple identici**: iPhone, iPad e Mac condividono le tue sorgenti, i preferiti, la cronologia, le categorie, le impostazioni di visualizzazione, la **ripresa della riproduzione**, le schede dei dettagli corrette e — facoltativamente — le **password**. La sincronizzazione passa da **una cartella del tuo iCloud Drive**: Kastideo vi deposita piccoli file.

**Configurazione (su ogni dispositivo).**

1. In iCloud Drive, crea una cartella, per esempio **Kastideo** (una volta sola). Verifica che iCloud Drive sia attivo su ogni dispositivo.
2. Apri Kastideo > Impostazioni > **iCloud** e attiva **Sincronizza con iCloud Drive**.
3. Tocca **Cartella di sincronizzazione** e scegli **la stessa cartella**.
4. Scegli cosa sincronizzare.
5. Se sincronizzi le password o la chiave TMDB, inserisci la **frase segreta** — la stessa su tutti i dispositivi — poi **Salva la frase segreta**.

**Da sapere.**

- Prevale la modifica più recente. Alla prima sincronizzazione, gli elenchi (sorgenti, preferiti, cronologia) vengono uniti.
- Le password vengono **cifrate** con la tua frase segreta prima di essere memorizzate: senza di essa, nessuno può leggerle. Annotala: non può essere recuperata.
- Le cartelle di video, i file M3U e la galleria restano specifici di ciascun dispositivo. Le impostazioni di visualizzazione specifiche di Mac e iPhone vengono conservate separatamente.
- La sincronizzazione avviene ogni 30 secondi, al ritorno nell'app e quando passa in secondo piano; **Sincronizza ora** la forza. Su Mac, una piccola icona a forma di nuvola in fondo alla barra laterale mostra lo stato.
- «Cancella i file di sincronizzazione» elimina i file nella cartella per tutti i tuoi dispositivi (i tuoi dati locali vengono conservati).
- Windows, Linux e Android non sono coperti: usa l'esportazione / importazione della configurazione.

## Novità {#nouveautes}

Dopo ogni aggiornamento, la finestra **Novità** riassume le modifiche della versione installata.

<!--mac-->
Puoi riaprirla con **Aiuto > Novità di questa versione** oppure facendo clic sul numero di versione in basso a destra nella Home, e consultare lì le versioni precedenti.
<!--/mac-->
<!--pc-->
Puoi riaprirla facendo clic sul numero di versione in basso a destra nella Home, e consultare lì le versioni precedenti.
<!--/pc-->

La cronologia completa è pubblicata anche nella pagina [GitHub Releases](https://github.com/jihemezes/kastideo/releases).

# Risoluzione dei problemi

## Risoluzione dei problemi {#depannage}

<!--mac-->
- **Un canale non ha audio**: Kastideo lo rileva in pochi secondi e lo ripara da solo: se l'orologio del flusso è sfasato (l'audio viene scartato, «buffer too late» nel registro), il canale viene riaperto sincronizzato su audio e video, e Kastideo se ne ricorda; altrimenti riavvia la traccia audio o prova la successiva. Se un'icona arancione 🔇 resta accanto all'indicatore di stato, il fornitore invia un flusso senza audio o una traccia illeggibile: prova un'altra versione del canale (HD, SD…) oppure scegli un'altra traccia audio nel pannello informazioni (⌘I). Il registro di riproduzione (righe «Son :») mostra il formato ricevuto.

- **«Il fornitore rifiuta questo canale (HTTP 403)»**: è il fornitore stesso a bloccare questo canale (fuori servizio o non incluso nel tuo abbonamento). Kastideo non insiste; prova un'altra versione (HD, SD…) o più tardi.
- **Immagine bloccata, «Flusso difettoso presso il fornitore»**: l'orologio del flusso è incoerente. Kastideo riapre il canale una volta, sincronizzato su audio e video; se non basta, passa a **solo video** (senza audio) in modo che l'immagine non si blocchi più, e se ne ricorda. Clic destro sul canale > **Solo video (senza audio)** per attivarlo o disattivarlo a mano. Impostazioni > Generali > Riproduzione > **Ripristina** annulla queste riparazioni memorizzate. **Il passaggio automatico a solo video vale solo per la sessione in corso**: al prossimo avvio il canale viene riaperto con l'audio. Sotto la barra di riproduzione compare un avviso **Riattiva l'audio** finché un canale è senza audio. Le riparazioni memorizzate (orologio, decodifica software, solo video scelto a mano) **scadono dopo 7 giorni**.
- **Relay del flusso** (Impostazioni > Generali > Riproduzione, attivo per impostazione predefinita): Kastideo apre da sé la connessione al fornitore e la passa al motore VLC, come Piboard, così non ce ne sono mai due contemporaneamente. Il registro di riproduzione mostra allora righe «Relais :» con la risposta esatta del fornitore (per es. «HTTP 200 en 0,35 s»).
- **Cambio di canale lento o rifiutato («HTTP 404», «403», «401» o «520» nel registro di riproduzione)**: con un abbonamento a una sola connessione, il fornitore impiega un attimo a liberare il canale precedente. Kastideo attende 1,5 s prima di aprire il nuovo canale e riprova una volta se viene rifiutato («Attente…» e «nouvel essai» nel registro). Se i rifiuti persistono, attendi un minuto e riprova.

Kastideo si presenta ai server come il player **VLC**: molti fornitori IPTV rispondono solo ai player che riconoscono.

- **«Il server non ha risposto in tempo»**: il server è sovraccarico o non disponibile. Riprova più tardi; se il tuo indirizzo ha la forma `get.php?username=…`, verifica che sia stato convertito in Xtream Codes (tipo mostrato nelle impostazioni delle sorgenti).

- **«Nome utente o password rifiutati»**: verifica le tue credenziali con **Prova la connessione**.
- **«Account non attivo»**: l'abbonamento è scaduto o sospeso presso il tuo fornitore.
- **Nessun programma nella guida**: il canale non ha un identificatore della guida TV, oppure la guida della tua sorgente non ne contiene per esso.
- **«App Transport Security»**: questo messaggio compariva nelle versioni 0.1.0 e 0.2.0 con sorgenti http://. È stato corretto dalla versione 0.2.1.
- **Impossibile riprodurre**: il server non ha fornito il flusso. Verifica che nessun altro dispositivo stia usando il tuo abbonamento (è consentita una sola connessione), poi fai clic su **Riprova**. Prova anche il buffer **Stabile**.
<!--/mac-->

<!--pc-->
- **Un canale non parte**: apri il **Registro** (Ctrl+Alt+L, argomento *Riproduzione e relay*). Le righe «Relais :» danno la risposta esatta del fornitore (per es. «HTTP 200 en 0,35 s» o «HTTP 403»).
- **L'aggiornamento non si installa**: il registro di riproduzione (Ctrl+Alt+L) ne indica il motivo. Pacchetto .deb: se la finestra della password non compare, il comando da digitare in un terminale viene mostrato nella finestra di aggiornamento. Puoi sempre scaricare la nuova versione dalla pagina delle release di GitHub.
- **MultiVista: un riquadro resta nero**: il fornitore rifiuta una connessione aggiuntiva. Verifica il numero di connessioni del tuo abbonamento (Impostazioni > Generali > Riproduzione > Rileva).
- **Nessuna notifica**: controlla Impostazioni > Generali > Notifiche, poi le impostazioni di notifica di Windows (Impostazioni > Sistema > Notifiche) o del tuo desktop Linux. Su Linux è necessario il pacchetto libnotify (installato dal .deb, incluso nell'AppImage).
- **Registrazione vuota**: il fornitore non ha inviato nulla (canale rifiutato, connessione già usata da un altro dispositivo). Le righe «Enregistrement» nel registro danno la risposta del fornitore (per es. «HTTP 403») e indicano se non sono arrivati dati dopo 30 s.
- **La differita non torna più indietro**: la sua profondità dipende dallo spazio temporaneo su disco; senza cache su disco (alcune versioni di libmpv su Linux), è limitata a 512 MB in memoria.
- **Dettagli in un'altra lingua**: alcuni fornitori hanno una sola lingua. Con una **chiave TMDB**, trame, generi ed episodi provengono da TMDB nella tua lingua.
- **Finestra singola**: avviato mentre è già in esecuzione, Kastideo porta semplicemente in primo piano la finestra esistente.
- **Nessuna immagine su Linux**: verifica che il pacchetto **libmpv** sia installato (il .deb lo installa; l'AppImage lo include).
- **VPN**: una VPN attiva può impedire al fornitore di servire i flussi.
- **Nessun programma nella guida**: Impostazioni > Sorgenti mostra lo stato della guida di ciascuna sorgente; la guida di riserva integra i canali francesi più comuni.
- **Password su Linux**: senza un portachiavi (GNOME Keyring o KWallet), Kastideo conserva le password nelle sue preferenze e lo segnala nel registro.
<!--/pc-->

## La finestra è fuori dallo schermo (Windows e Linux) {#fenetre-hors-ecran}

Con più schermi, una finestra poteva aprirsi a metà fuori dallo schermo senza una barra del titolo raggiungibile. Dalla versione 1.12.1, Kastideo **ricorda la posizione della sua finestra** e, all'avvio, verifica che la sua barra del titolo sia visibile su uno schermo. In caso contrario (schermo scollegato, risoluzione o scala modificate), la finestra viene **ricentrata sullo schermo principale**.

Se una finestra è ancora irraggiungibile: su Windows, premi **Alt + Spazio** poi **S** (Sposta), poi i tasti freccia; oppure chiudi Kastideo e riavvialo.

# Informazioni

## Avviso legale {#avertissement}

Grazie per usare Kastideo. Kastideo è un lettore multimediale: riproduce playlist (M3U), account IPTV (Xtream Codes), i tuoi server (Jellyfin, Emby, Plex), i video sulle tue unità e YouTube.

- **Nessun contenuto fornito.** Kastideo non fornisce, non ospita né vende alcun canale, film, playlist o abbonamento.
- **Nessuna affiliazione.** Kastideo non è affiliato ad alcun fornitore di contenuti o di abbonamenti IPTV, né a YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple o Microsoft. I marchi citati appartengono ai rispettivi proprietari. Questo prodotto utilizza l'API di TMDB ma non è sostenuto né certificato da TMDB.
- **I tuoi contenuti.** Devi fornire le tue sorgenti e i tuoi contenuti. Sei l'unico responsabile della verifica che siano legali e che tu abbia tutti i diritti necessari per guardarli, registrarli, scaricarli e trasmetterli.
- **Diritto d'autore.** Kastideo non incoraggia la trasmissione di materiale protetto da diritto d'autore senza il permesso del titolare dei diritti. Registrazioni, download e trasmissioni su un televisore sono destinati solo all'uso privato, entro i limiti della legge del tuo paese.
- **Responsabilità.** L'autore di Kastideo non è responsabile dell'uso che fai del software, né del contenuto, della disponibilità o della legalità dei servizi di terze parti a cui lo colleghi. Kastideo è fornito gratuitamente, «così com'è», senza garanzia.
- **I tuoi dati.** Le tue credenziali restano sul tuo dispositivo e vengono inviate solo ai servizi che configuri.

Facendo clic su «Ho capito e accetto», confermi di aver letto e di accettare queste condizioni. In caso contrario, esci dall'applicazione.

Questo avviso compare al primo avvio e dopo ogni aggiornamento. Puoi rileggerlo in qualsiasi momento in <!--mac-->**Impostazioni (⌘,) > Informazioni**<!--/mac--><!--pc-->**Impostazioni (Ctrl+,) > Informazioni**<!--/pc-->.

## Sostieni Kastideo {#soutenir}

<!--mac-->
Kastideo è **gratuito**. Se l'app ti piace, puoi incoraggiarne lo sviluppo offrendomi un caffè su [Ko-fi](https://ko-fi.com/jihemezes): è del tutto facoltativo.

Il pulsante **Offrimi un caffè** compare in modo discreto nella schermata Home e nella finestra Novità, oltre che in **Impostazioni > Informazioni** e in **Aiuto > Sostieni Kastideo (Ko-fi)**. Per nascondere i pulsanti nella schermata Home e nelle Novità, spunta **Nascondi i pulsanti «Offrimi un caffè»** in **Impostazioni > Informazioni**.
<!--/mac-->

<!--pc-->
Kastideo è **gratuito**. Se l'app ti piace, puoi incoraggiarne lo sviluppo offrendomi un caffè su [Ko-fi](https://ko-fi.com/jihemezes): è del tutto facoltativo.

Il pulsante **Offrimi un caffè** compare in modo discreto nella schermata Home e nella finestra Novità, oltre che in **Impostazioni > Informazioni**. Per nascondere i pulsanti nella schermata Home e nelle Novità, spunta **Nascondi i pulsanti «Offrimi un caffè»** in **Impostazioni > Informazioni**.
<!--/pc-->

## Privacy {#confidentialite}

<!--mac-->
Kastideo gira nella sandbox di macOS. Accede solo alla rete e ai file che scegli tu. Le tue password restano nel portachiavi. Nessun dato viene inviato altrove se non alle tue sorgenti.
<!--/mac-->

<!--pc-->
Kastideo non raccoglie alcun dato. Contatta solo i tuoi fornitori IPTV, le guide TV che hai scelto, GitHub per gli aggiornamenti e, se hai inserito una chiave, TMDB. Le tue impostazioni, i preferiti e le password restano sul tuo computer.
<!--/pc-->

## Licenze {#licences}

<!--mac-->
Kastideo utilizza **VLCKit** (il motore di VLC, © VideoLAN, licenza LGPL 2.1 o successiva, https://www.videolan.org/vlc/libvlc.html) e **Sparkle** (licenza MIT, https://sparkle-project.org). VLCKit è incorporato come libreria dinamica non modificata.
<!--/mac-->
