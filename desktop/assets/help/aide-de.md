# Erste Schritte

## Willkommen {#bienvenue}

Kastideo vereint Ihre **Live-Sender, IPTV-Filme und -Serien**, Ihre **persönlichen Videos** (Festplatte, USB-Stick, NAS, Jellyfin, Emby, Plex) und **YouTube** in einer einzigen Oberfläche. Kastideo stellt **keine eigenen Inhalte** bereit: Sie fügen Ihre eigenen Quellen hinzu.

<!--mac-->
![Der Startbildschirm](img:home)

1. Von überall zurück zum Start.
2. Eine gemeinsame Suche für Sender, Filme und Serien.
3. Die Schaltfläche **?**: die Hilfe, geöffnet auf der Seite, die zum aktuellen Bildschirm passt.
<!--/mac-->
<!--pc-->
![Der Startbildschirm](img:homepc)

1. Die Schaltfläche **?**: die Hilfe, geöffnet auf der Seite, die zum aktuellen Bildschirm passt.
2. **Wiedergabeprotokoll**: das Diagnosewerkzeug.
3. **Einstellungen**: Quellen, Darstellung, Aufnahmen …
4. Eine gemeinsame Suche für Sender, Filme und Serien, dann die Kacheln und Kurzbefehle ([Details zum Startbildschirm](help:accueil)).
<!--/pc-->

### Schnellstart

<!--mac-->
1. Klicken Sie beim ersten Start auf **Quelle hinzufügen** (oder **Einstellungen ⌘,** > **Quellen** > **Hinzufügen**).
<!--/mac-->
<!--pc-->
1. Öffnen Sie die **Einstellungen** (das Zahnrad auf dem Start oder **Strg+,**) > **Quellen** > **Quelle hinzufügen**.
<!--/pc-->
2. Wählen Sie den Quellentyp: [Xtream Codes](help:xtream), [M3U-Wiedergabeliste](help:m3u), [Ordner](help:dossiers) oder einen [Jellyfin-, Emby- oder Plex](help:serveurs)-Server.
3. Füllen Sie die verlangten Angaben aus und klicken Sie auf **Hinzufügen**: Kastideo lädt die Sender, Filme, Serien und den [TV-Programm](help:guide).
4. Gehen Sie zurück zum **Start** und öffnen Sie **Live**, **Filme** oder **Serien**.

### Hilfe erhalten

<!--mac-->
- Die Schaltfläche **?** in der Symbolleiste öffnet die Hilfe auf der Seite, die zum aktuellen Bildschirm passt.
- Menü **Hilfe > Kastideo-Hilfe** oder **⌘?**.
<!--/mac-->
<!--pc-->
- Die Schaltfläche **?** auf dem Start und auf den Hauptbildschirmen öffnet die Hilfe.
<!--/pc-->
- Das Feld **Suchen** oben in der Hilfe durchsucht alle Seiten.
- Etwas funktioniert nicht? Lesen Sie die [FAQ](help:faq) und danach die [Fehlerbehebung](help:depannage).

> Sie möchten YouTube ansehen? Siehe [YouTube](help:youtube). Ihre Abonnements importieren: [Schritt für Schritt](help:youtube-import).

## FAQ {#faq}

### Wo finde ich Sender zum Hinzufügen?
Kastideo stellt weder Sender noch ein Abonnement bereit. Ihr IPTV-Anbieter gibt Ihnen entweder einen Server, einen Benutzernamen und ein Passwort ([Xtream Codes](help:xtream)) oder die Adresse einer Wiedergabeliste ([M3U](help:m3u)). Sie können auch Ihre eigenen Dateien abspielen ([Ordner](help:dossiers)).

### Wie ändere ich die Sprache von Kastideo?
Kastideo ist verfügbar auf **Französisch, Englisch, Spanisch, Deutsch, Italienisch und Portugiesisch** (Portugal und Brasilien). Standardmäßig folgt es der Sprache Ihres Geräts; wird diese Sprache nicht unterstützt, erscheint die Oberfläche auf Englisch. So ändern Sie sie: **Einstellungen > Allgemein > Sprache** (auf iPhone, iPad und Apple TV folgt Kastideo der Systemsprache: stellen Sie sie in den Geräteeinstellungen ein). Die Änderung wird beim nächsten Start von Kastideo übernommen.

### Ein Sender startet nicht oder ruckelt
<!--mac-->Siehe [Wenn ein Sender nicht startet](help:chaine-ne-demarre-pas) und [Fehlerbehebung](help:depannage).<!--/mac--><!--pc-->Siehe [Fehlerbehebung](help:depannage).<!--/pc--> Sehr oft ist eine **zweite gleichzeitige Verbindung** mit demselben Abonnement die Ursache: siehe [Eine Verbindung zur selben Zeit](help:connexion-unique).

### Der TV-Programm ist leer oder unvollständig
Einstellungen > Quellen > **TV-Programm neu laden**, lesen Sie dann [TV-Programm](help:guide) und den [Ersatz-Guide](help:guide-secours).

### Wie kann ich YouTube ohne Werbung ansehen?
Kastideo spielt Videos mit dem offiziellen Player im **erweiterten Datenschutzmodus** ab: keine Tracking-Cookies, daher in der Regel keine personalisierte Werbung. Es ist **kein** Werbeblocker: siehe [Werbung, Konto und Datenschutz](help:youtube-confidentialite).

### Wie importiere ich meine YouTube-Abonnements?
YouTube erlaubt es nicht, ein Konto mit einer Drittanbieter-App zu verbinden: Sie verwenden eine Datei, die Google für Sie erstellt. Folgen Sie der [Schritt-für-Schritt-Anleitung](help:youtube-import).

### Die YouTube-Suche verlangt einen Schlüssel
Die Suche verwendet **Ihren eigenen** kostenlosen Google-API-Schlüssel. Die [Schritt-für-Schritt-Anleitung](help:youtube-cle) erklärt es in wenigen Minuten. Ohne Schlüssel können Sie weiterhin Kanälen folgen und eingefügte Links abspielen.

### Wie nehme ich eine Sendung auf?
Siehe [Live-Fernsehen aufnehmen](help:enregistrer) und [Eine Aufnahme planen](help:programmer).

### Wie sehe ich eine Sendung, die schon gelaufen ist?
Wenn Ihr Anbieter ein Archiv bereitstellt: siehe [Replay](help:replay).

### Wie bekomme ich meine Einstellungen auf einen anderen Computer?
Siehe [Sicherung und Übertragung](help:sauvegarde).

# Quellen

## Xtream Codes {#xtream}

<!--mac-->
Das ist das gebräuchlichste Format bei IPTV-Anbietern. Sie benötigen drei Angaben: die Adresse des **Servers** (zum Beispiel `http://example.com:8080`), Ihren **Benutzernamen** und Ihr **Passwort**.

- Die Schaltfläche **Verbindung testen** prüft Ihre Zugangsdaten und zeigt den Status des Kontos, das Ablaufdatum und die Anzahl der erlaubten gleichzeitigen Verbindungen an.
- Das Passwort wird im **macOS-Schlüsselbund** gespeichert, niemals im Klartext auf der Festplatte.
- Der TV-Programm des Servers wird automatisch verwendet.
- Serien öffnen sich auf einer Seite mit ihren Staffeln und Folgen.
<!--/mac-->

<!--pc-->
Serveradresse (z. B. http://example.com:8080), Benutzername und Passwort. Das Passwort wird im Systemtresor gespeichert: Anmeldeinformationsverwaltung unter Windows, GNOME-Schlüsselbund oder KWallet unter Linux.
<!--/pc-->

## M3U-/M3U8-Wiedergabeliste {#m3u}

<!--mac-->
- **Per URL**: Fügen Sie die Adresse der Wiedergabeliste ein, die Ihr Anbieter Ihnen mitgeteilt hat.
- Sieht die Adresse wie `get.php?username=…&password=…` aus (der häufigste Fall bei Abonnement-Anbietern), erkennt Kastideo sie und speichert sie als **Xtream Codes**: Das Laden ist deutlich schneller, der TV-Programm ist enthalten und das Passwort bleibt im Schlüsselbund. Bereits gespeicherte Quellen dieser Art werden automatisch umgewandelt.
- **Per Datei**: Wählen Sie eine `.m3u`- oder `.m3u8`-Datei auf Ihrem Mac. Kastideo behält die Zugriffsberechtigung, um sie aktualisieren zu können.
- Die Kategorien stammen aus dem Attribut `group-title`, die Logos aus `tvg-logo` und die Verknüpfung mit dem TV-Programm aus `tvg-id`.
- Kastideo ordnet die Einträge anhand ihrer Adresse automatisch in Live, Filme oder Serien ein.
<!--/mac-->

<!--pc-->
Adresse der Wiedergabeliste oder Datei auf der Festplatte (**Datei auswählen …**). Eine Adresse „get.php?username=…&password=…“ wird erkannt und in eine Xtream-Quelle umgewandelt, deutlich schneller und vollständiger (Details, Folgen, neueste Neuzugänge).
<!--/pc-->

## Ordner (Festplatte, USB-Stick, NAS) {#dossiers}

<!--mac-->
So sehen Sie Videos, die auf dem Mac, einer externen Festplatte, einem USB-Stick oder einem NAS gespeichert sind:

1. Einstellungen > Quellen > **Hinzufügen** > Typ **Ordner (Festplatte, USB, NAS)**.
2. **Ordner hinzufügen …**: Wählen Sie einen oder mehrere Ordner (zum Beispiel „Filme“ und „Serien“). Bei einem **NAS** binden Sie die Freigabe zuerst im Finder ein (**Gehe zu > Mit Server verbinden …**, zum Beispiel `smb://nas.local/Videos`) und wählen sie dann unter den Volumes aus.
3. **Hinzufügen**: Kastideo durchsucht die Ordner und ihre Unterordner.

Videos werden an ihren Namen erkannt:

- **Filme**: „Inception (2010).mkv“, „The.Matrix.1999.1080p.BluRay.mkv“ oder ein Ordner „Amélie (2001)“, der den Film enthält. Sie erscheinen unter **Filme**, Kategorie „Filme · Ordnername“.
- **Serien**: „Breaking.Bad.S01E02.mkv“, „Friends 1x05.mp4“ oder ein Ordner „Kaamelott/Season 3/12 - Le Tourment.avi“. Die Folgen werden unter **Serien** zu einer Serie mit ihren Staffeln zusammengefasst.
- **Andere Videos** (Urlaub, Kamera …): Kategorie **Videos · Ordnername**, unter Filme.

Die Ordner werden bei jedem Start und danach alle 20 Minuten durchsucht: Ein neues Video erscheint von selbst. Ist die Festplatte abgezogen oder die Freigabe getrennt, weist eine Meldung unter der Quelle darauf hin und die bisherige Liste bleibt erhalten. **Untertitel** neben einem Video („Inception (2010).srt“, „Inception (2010).en.srt“) werden bei der Wiedergabe geladen.

Mit einem **TMDB-Schlüssel** (Einstellungen > Allgemein) erhalten Filme und Serien automatisch **Poster und Inhaltsangabe**. Führt der Dateiname die Suche in die Irre, klicken Sie mit der rechten Maustaste auf das Poster (oder auf den Link am Ende der Detailseite) > **Details korrigieren …**: Suchen Sie den richtigen Titel und wählen Sie ihn aus; die Auswahl wird gespeichert.
<!--/mac-->

<!--pc-->
Einstellungen > Quellen > **Quelle hinzufügen** > **Ordner**, dann **Ordner hinzufügen …** (interne Festplatte, USB-Festplatte oder -Stick) oder geben Sie einen **Netzwerkpfad** ein und klicken Sie auf **+**: `\\NAS\Videos` oder ein Netzlaufwerk (`Z:\`) unter Windows, eine eingehängte Freigabe (`/mnt/nas/videos`, `/media/…`) unter Linux. Mehrere Ordner können eine Quelle bilden.

- **Filme**, erkannt an ihren Namen: „Inception (2010).mkv“, „The.Matrix.1999.1080p.BluRay.mkv“, Ordner „Amélie (2001)“. Kategorie „Filme · Ordnername“.
- **Serien**: „Breaking.Bad.S01E02.mkv“, „Friends 1x05.mp4“, Ordner „Serie/Season 1/…“. Die Folgen werden unter **Serien** nach Serie und Staffel gruppiert.
- **Andere Videos**: Kategorie **Videos · Ordnername** unter Filme.
- Durchsucht bei jedem Start und danach alle 20 Minuten. Festplatte abgezogen: Eine Meldung weist darauf hin und die bisherige Liste bleibt erhalten. Unlesbare Unterordner („System Volume Information“ …) werden übersprungen.
- **Untertitel** neben einem Video („Film.srt“, „Film.en.srt“) werden bei der Wiedergabe geladen.
- Mit einem **TMDB-Schlüssel** werden **Poster und Inhaltsangaben** automatisch hinzugefügt; Rechtsklick > **Details korrigieren …**, um den richtigen Titel auszuwählen, wenn der Dateiname die Suche in die Irre führt.
<!--/pc-->

## Jellyfin, Emby und Plex {#serveurs}

<!--mac-->
### Jellyfin und Emby

1. Einstellungen > Quellen > **Hinzufügen** > **Jellyfin** oder **Emby**.
2. **Im Netzwerk suchen** findet die Server bei Ihnen zu Hause; klicken Sie auf Ihren, um die Adresse auszufüllen. Andernfalls geben Sie sie ein (zum Beispiel `192.168.1.10`: Der Port 8096 wird ergänzt).
3. Ihr Jellyfin-/Emby-**Benutzername** und **Passwort** — **optional**: Lassen Sie sie leer, wenn das Konto keine hat (ein **API-Schlüssel** aus dem Dashboard kann sie ebenfalls ersetzen). **Verbindung testen** prüft die Adresse. Eine aus dem Browser kopierte Adresse („…:8096/web/index.html#!/home“) wird auf die des Servers gekürzt.
4. **Hinzufügen**: Der Benutzername wird geprüft, dann erscheinen die Film-, Serien- und Videobibliotheken des Servers unter **Filme** und **Serien** (Kategorien „Bibliotheksname · Servername“), mit den Postern und Details des Servers.

Die Wiedergabe erfolgt **direkt**, ohne Transkodierung durch den Server. Das Passwort und die Sitzung werden im Schlüsselbund gespeichert.

### Plex

1. Einstellungen > Quellen > **Hinzufügen** > **Plex**.
2. **Mit Plex anmelden** öffnet plex.tv im Browser: Melden Sie sich an und autorisieren Sie Kastideo. Zurück in Kastideo wählen Sie den Server Ihres Kontos aus.
3. Sie können auch die Serveradresse (Port 32400) und den **Token** (X-Plex-Token) eingeben. Der Token ist **optional**, wenn der Server das lokale Netzwerk ohne Authentifizierung zulässt (Plex > Einstellungen > Netzwerk > „Liste der IP-Adressen und Netzwerke, die ohne Authentifizierung zugelassen sind“).
4. **Hinzufügen**: Die Film- und Serienbibliotheken erscheinen unter **Filme** und **Serien**.
<!--/mac-->

<!--pc-->
Einstellungen > Quellen > **Quelle hinzufügen** > **Jellyfin**, **Emby** oder **Plex**. **Im Netzwerk suchen** findet die Server bei Ihnen zu Hause: Klicken Sie auf Ihren, um das Formular auszufüllen (andernfalls geben Sie die Adresse ein; ohne Port wird 8096 oder 32400 ergänzt).

- **Jellyfin / Emby**: Benutzername und Passwort — **optional**, wenn das Konto keine hat (oder ein **API-Schlüssel** aus dem Dashboard). **Testen** prüft die Adresse; bei einem Fehler wird die genaue Antwort des Servers angezeigt.
- **Plex**: **Mit Plex anmelden** öffnet plex.tv im Browser; autorisieren Sie Kastideo und wählen Sie dann den Server Ihres Kontos aus. Oder geben Sie die Adresse und den **Token** (X-Plex-Token) ein, optional, wenn der Server das lokale Netzwerk ohne Authentifizierung zulässt.
- Die Bibliotheken erscheinen unter **Filme** und **Serien** („Bibliotheksname · Servername“), mit den Postern, Details, Staffeln und Folgen des Servers. Direkte Wiedergabe, keine Transkodierung.
- **Fortsetzen und „gesehen“ in beide Richtungen geteilt**: Die Position wird während der Wiedergabe an den Server gesendet, und die von Ihren anderen Geräten wird übernommen. Rechtsklick > **Als gesehen / ungesehen markieren**; Abzeichen **Gesehen** auf den Postern.

> Windows-Firewall: Erlauben Sie Kastideo bei der ersten Suche in privaten Netzwerken, damit die Server antworten können.
<!--/pc-->

## Fortsetzen und „gesehen“ mit den Servern geteilt {#reprise-serveurs}

<!--mac-->
Bei Jellyfin, Emby und Plex wird die Wiedergabeposition während der Wiedergabe an den Server gesendet: Ein in Kastideo begonnener Film kann auf dem Fernseher fortgesetzt werden und umgekehrt. Ein bis zum Ende angesehener Film wird auf dem Server als **gesehen** markiert. Rechtsklick auf einen Film oder eine Folge > **Als gesehen / ungesehen markieren** (auch für Dateien aus Ordnern). Auf den Postern erscheint ein Abzeichen **Gesehen** und in der Folgenliste ein Häkchen.

> Netzwerksuche: Beim ersten Mal fragt macOS nach der Erlaubnis für den Zugriff auf das **lokale Netzwerk**; akzeptieren Sie sie (andernfalls Systemeinstellungen > Datenschutz & Sicherheit > Lokales Netzwerk).
<!--/mac-->

## TV-Programm (XMLTV) {#guide}

<!--mac-->
Jede Quelle kann eine TV-Programm-Adresse im XMLTV-Format haben (`.xml` oder `.xml.gz`). Lassen Sie sie leer, verwendet Kastideo die des Xtream-Servers oder die in der Wiedergabeliste angegebene (`url-tvg`). Der Guide wird ab 6 Stunden in der Vergangenheit bis 48 Stunden in der Zukunft vorgehalten.
<!--/mac-->

<!--pc-->
Der von Ihrem Anbieter bereitgestellte Guide wird im Hintergrund geladen und auf der Festplatte gespeichert. Mit dem optionalen Feld **TV-Programm (XMLTV)** einer Quelle können Sie einen anderen Guide verwenden (.xml oder .xml.gz).
<!--/pc-->

## Ersatz-TV-Programm (xmltvfr.fr) {#guide-secours}

<!--mac-->
Der Guide Ihres Anbieters kann unvollständig oder vorübergehend leer sein. Kastideo ergänzt ihn mit einem kostenlosen **Ersatz-Guide** von **xmltvfr.fr** (standardmäßig der Guide „Komplett“: etwa 785 französische und ausländische Sender, 5 Tage, täglich aktualisiert):

- Es werden nur Sender **ohne Sendungen** bei Ihrem Anbieter ergänzt; der Guide des Anbieters hat weiterhin Vorrang;
- Die Sender werden **über den Namen** zugeordnet: „|FR| TF1 FHD“ → TF1, „|FR| FRANCE 2 UHD“ → France 2, „|FR| TF1 4K“ → TF1 4K;
- Der Ersatz-Guide wird alle 12 Stunden neu geladen. Sendet der Anbieter einen leeren oder unlesbaren Guide, bleiben die bereits bekannten Sendungen erhalten und unter der Quelle erscheint eine Meldung.

**Herausfinden, woher der Guide stammt.** Unter jeder Quelle zeigt Einstellungen > Quellen, wie viele Sendungen der Anbieter gesendet hat. Die Schaltfläche **TV-Programm neu laden** (Kalendersymbol) startet den Download des Anbieter-Guides und des Ersatz-Guides neu. Zeilen des Anbieters, die nur **Kategorietrenner** sind („♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣“), werden ignoriert; eine 4K- oder FHD-Version ohne eigenes Programm übernimmt das der HD-Version; Sender ohne Programm zeigen „Programm nicht verfügbar“. Das **Protokoll**, Thema **TV-Programm**, protokolliert jeden Versuch: angeforderte Adresse, Antwort des Servers (Code, Größe, Zeit), Anzahl der empfangenen Sender und Sendungen, abgedeckter Zeitraum, wie viele Ihrer Sender mit dem Guide des Anbieters, dem Ersatz-Guide oder keinem von beiden verknüpft sind und — falls der Guide nichts Brauchbares enthält — den Anfang der Serverantwort.

Einstellungen > Allgemein > **Ersatz-TV-Programm**: ein- oder ausschalten, einen anderen xmltvfr.fr-Guide wählen (Frankreich ~400 Sender, DVB-T) oder eine beliebige XMLTV-Adresse eingeben, **Jetzt aktualisieren**, und sehen, wie viele Sender mit Ihren verknüpft wurden.
<!--/mac-->

<!--pc-->
Einstellungen > Allgemein > **TV-Programm**: Ein Ersatz-Guide füllt Sender ohne Sendungen im Guide Ihres Anbieters auf und ordnet sie über den Namen zu. Wählen Sie einen xmltvfr.fr-Guide oder geben Sie eine Adresse ein; **Guide neu laden** lädt alles erneut herunter. Die Schaltfläche **TV-Programm-Protokoll** öffnet das Protokoll zum Thema *TV-Programm*: angeforderte Adresse, Antwort des Anbieters (Code, Größe, Zeit), empfangene Sender und Sendungen, abgedeckter Zeitraum, wie viele Ihrer Sender mit dem Anbieter, dem Ersatz-Guide oder keinem Guide verknüpft sind und — falls der Guide unbrauchbar ist — den Anfang der Serverantwort. Die Sendungen des Anbieters werden nach den Kennungen Ihrer Sender gefiltert: Enthält der Guide Sendungen, aber keine für Ihre Sender, zeigt das Protokoll die Kennungen auf beiden Seiten.
<!--/pc-->

## Quellen verwalten {#gerer-sources}

<!--mac-->
Öffnen Sie **Kastideo > Einstellungen … (⌘,)**, Tab **Quellen**, oder klicken Sie in der Symbolleiste auf die Schaltfläche **Quellen**.

- Mit dem Schalter aktivieren oder deaktivieren Sie eine Quelle, ohne sie zu löschen.
- Mit den Schaltflächen aktualisieren, bearbeiten oder löschen Sie eine Quelle.
- Bei einem Fehler erscheint die Meldung rot unter der Quelle und in der Seitenleiste ein oranges Dreieck.
<!--/mac-->

<!--pc-->
Einstellungen > **Quellen**: eine Quelle **bearbeiten** (Stiftsymbol: Name, Server, Benutzername, Passwort, Adresse der Wiedergabeliste, TV-Programm — Favoriten, Zuletzt-Liste und Sender-Korrekturen bleiben erhalten), aktualisieren, löschen und den Zustand ihres TV-Programms sehen. Die Schaltfläche mit dem **Auge** zeigt das Passwort (oder den TMDB-Schlüssel) zur Kontrolle an. Quellen werden beim Start aktualisiert, wenn ihre letzte Aktualisierung mehr als 6 Stunden zurückliegt (einstellbar). Liefert eine Aktualisierung einen leeren Abschnitt, bleibt der vorherige erhalten.
<!--/pc-->

Während die Sender, Filme und Serien eines Abos geprüft oder geladen werden (und wenn die Listen nach einer Kategorieänderung neu berechnet werden), erscheint oben im Fenster ein Banner **Katalog wird aktualisiert**. Die App wirkt dann einige Sekunden lang, bei großen Katalogen bis zu einer Minute, möglicherweise eingefroren: Das ist normal, das Banner verschwindet von selbst.

# Navigieren

## Der Startbildschirm {#accueil}

<!--mac-->
![Der Startbildschirm](img:home)

Kastideo öffnet sich auf dem **Startbildschirm**, von oben nach unten:

- das **Suchfeld**, das Sender, Filme und Serien gleichzeitig durchsucht; ein Klick auf ein Ergebnis öffnet es;
- die großen Kacheln **Live**, **Filme** und **Serien** sowie **Meine Videos**, sobald eine Quelle vom Typ [Ordner, Jellyfin, Emby oder Plex](help:mes-videos) existiert; jede Kachel zeigt die Anzahl der Sender, Filme, Serien oder Videos;
- die Schaltflächen **Favoriten**, **Zuletzt**, **TV-Programm**, **YouTube** und **Aufnahmen** (ein Abzeichen zeigt die Anzahl der Einträge oder der ausstehenden Aufnahmen und Downloads);
- die Zeile **Jetzt im TV**: Chips nach Thema (Sport, Nachrichten, Filme …) und **Heute Abend**, die [Live nach Themen](help:direct-theme) öffnen;
- die Zeile **Weiterschauen**: Filme und Folgen, die Sie begonnen haben; ein Klick setzt dort fort, wo Sie aufgehört haben;
- Wenn etwas läuft, können Sie über ein Banner **Aktuelle Wiedergabe** dorthin **zurückkehren** oder es **beenden**.

So kehren Sie jederzeit zum Start zurück: die Schaltfläche **Start** (Haus) oben links in der Symbolleiste, **⌘0**, die Zeile **Start** der Seitenleiste oder die Taste **H** in der TV-Oberfläche.

Die **Versionsnummer** wird dezent unten rechts neben den Schaltflächen **?** und **Spendier mir einen Kaffee** angezeigt; ein Klick auf die Version öffnet die Neuigkeiten.
<!--/mac-->
<!--pc-->
![Der Startbildschirm](img:homepc)

Kastideo öffnet sich auf dem **Startbildschirm**, von oben nach unten:

- die **Kopfzeile**: Logo, Name und rechts drei Schaltflächen: **Hilfe** (**F1**), **Wiedergabeprotokoll** und **Einstellungen** (**Strg+,**); ein kleiner Kreisel dreht sich, während Quellen aktualisiert werden;
- das **Suchfeld**, das Sender, Filme und Serien gleichzeitig durchsucht; ein Klick auf ein Ergebnis öffnet es;
- die großen Kacheln **Live**, **Filme** und **Serien** sowie **Meine Videos**, sobald eine Quelle vom Typ [Ordner, Jellyfin, Emby oder Plex](help:mes-videos) existiert; jede Kachel zeigt die Anzahl der Sender, Filme, Serien oder Videos;
- die Schaltflächen **Favoriten**, **Zuletzt**, **TV-Programm**, **MultiView**, **YouTube** und **Aufnahmen** (ein Abzeichen zeigt die Anzahl der Einträge, der Sender in MultiView oder der ausstehenden Aufnahmen und Downloads);
- die Zeile **Weiterschauen**: Filme und Folgen, die Sie begonnen haben; ein Klick setzt dort fort, wo Sie aufgehört haben;
- Wenn etwas läuft, können Sie über ein Banner **Aktuelle Wiedergabe** dorthin **zurückkehren** oder es **beenden**;
- Wurde keine Quelle hinzugefügt, bietet eine Karte **Keine Quelle** die Option **Quelle hinzufügen** an.

Unten rechts: die Schaltfläche **Spendier mir einen Kaffee** (lässt sich unter Einstellungen > Info ausblenden) und die Versionsnummer.

So kehren Sie jederzeit zum Start zurück: die Zeile **Start** der Seitenleiste, **Strg+0** oder die Taste **H** in der TV-Oberfläche.

**Auf Android-Smartphones und -Tablets** passt sich der Start der Bildschirmbreite an: Unter etwa 720 px (Smartphone oder Tablet im Hochformat) rücken die vier Kacheln in **zwei Spalten** und die Kopfzeile schrumpft. **Auf Android TV** werden die Schaltflächen mit der Fernbedienung ausgewählt (sichtbarer Rahmen) und **OK** öffnet.
<!--/pc-->

## Meine Videos {#mes-videos}

<!--mac-->
Sobald eine Quelle vom Typ **Ordner**, **Jellyfin**, **Emby** oder **Plex** existiert, erscheint auf dem Startbildschirm eine Kachel **Meine Videos** (und eine Zeile in der Seitenleiste, **⌘8**). Sie vereint Ihre Videos außerhalb von IPTV:

- **Empfohlen**: **Wiedergabe fortsetzen** (begonnene Filme und Folgen), **Kürzlich hinzugefügt**, **Filme zum Ansehen**, danach eine Zeile mit Filmen, Serien und Videos;
- **Filme**, **Serien**, **Videos**: Raster mit Suche, Filtern (**Genre**, **Jahr**, **ungesehen**) und Sortierung (Titel, kürzlich hinzugefügt, Jahr);
- **Ordner**: Durchsuchen Sie Ihre Ordner und Unterordner wie im Finder (Pfadleiste zum Zurückgehen) sowie die Bibliotheken der Server;
- **Quellen**: alle oder nur eine (NAS, Emby, Plex …). Ein oranges Dreieck zeigt einen Fehler an: Rechtsklick > **Fehlerdetails …** zeigt die Anfrage und die **genaue Antwort des Servers** (Schaltfläche **Kopieren**), dann **Erneut versuchen**.

In **Filme** und **Serien** legt der Wähler **Alle / IPTV / Meine Videos** (Seitenleiste, oberhalb der Kategorien) fest, was angezeigt wird: nur IPTV (Standard), nur Ihre Videos oder beides gemischt. Die Kategorien Ihrer Videos werden von der Länder-Einstellung nie ausgeblendet.
<!--/mac-->

<!--pc-->
Sobald eine Quelle vom Typ **Ordner**, **Jellyfin**, **Emby** oder **Plex** existiert, erscheint auf dem Startbildschirm eine Kachel **Meine Videos** (Kurzbefehl **Strg+8**). Sie vereint Ihre Videos außerhalb von IPTV:

- **Empfohlen**: **Wiedergabe fortsetzen** (begonnene Filme und Folgen), **Kürzlich hinzugefügt**, **Filme zum Ansehen**, danach eine Zeile mit Filmen, Serien und Videos;
- **Filme**, **Serien**, **Videos**: Raster mit Suche, Filtern (**Genre**, **Jahr**, **ungesehen**) und Sortierung (Titel, kürzlich hinzugefügt, Jahr);
- **Ordner**: Durchsuchen Sie Ihre Ordner und Unterordner wie im Datei-Explorer (Pfadleiste zum Zurückgehen) sowie die Bibliotheken der Server;
- **Quellen**: alle oder nur eine (NAS, Emby, Plex …). Ein oranges Dreieck zeigt einen Fehler an: Rechtsklick > **Fehlerdetails …** zeigt die Anfrage und die **genaue Antwort des Servers**, dann **Erneut versuchen**.

In **Filme** und **Serien** legt der Wähler **Alle / IPTV / Meine Videos** (Seitenleiste, oberhalb der Kategorien) fest, was angezeigt wird: nur IPTV (Standard), nur Ihre Videos oder beides gemischt. Die Kategorien Ihrer Videos werden von der Länder-Einstellung nie ausgeblendet.
<!--/pc-->

## Einen Eintrag aus „Weiterschauen“ entfernen {#retirer-reprise}

<!--mac-->
Klicken Sie mit der rechten Maustaste auf eine Miniatur in **Weiterschauen** (Start, Kino-Oberfläche, Meine Videos; langer Druck unter Android), um Folgendes zu erhalten:

- **Aus „Weiterschauen“ entfernen**: Die Miniatur verschwindet aus der Zeile, aber die **Position bleibt erhalten**: Wenn Sie den Film später wieder abspielen, geht es dort weiter, wo Sie aufgehört haben.
- **„Weiterschauen“ leeren**: entfernt alle Miniaturen aus der Zeile.

Ein Banner **Rückgängig** bleibt einige Sekunden sichtbar. Ein entfernter Eintrag **kehrt in die Zeile zurück**, sobald Sie ihn erneut ansehen; bis dahin erscheint er unter „Zuletzt angesehen“.
<!--/mac-->

## Meine Videos sortieren und filtern {#filtres-videos}

<!--pc-->
Unter **Windows, Linux und Android** kehrt der **Pfeil** die Sortierung um, und **Gruppieren nach** ordnet die Poster in **Abschnitte** (Quelle, Kategorie / Ordner / Album, Typ, Jahr, Monat des Hinzufügens; mehrere Kriterien gleichzeitig). Alles wird gemerkt.
<!--/pc-->

In **Meine Videos** haben die Ansichten **Filme**, **Serien** und **Videos** eine Filterleiste. Ihre Auswahl wird **gespeichert** und beim nächsten Start wiederhergestellt. **Zurücksetzen** löscht alle Filter (die Sortierung bleibt erhalten).

- **Quelle**: Wenn mehrere Quellen hinzugefügt sind (lokaler Ordner, Emby, Jellyfin, Plex …), zeigen Sie nur eine davon an. In der Ansicht „alle Quellen“ zeigt ein **Abzeichen** auf jedem Poster, woher der Film stammt.
- **Genre**, **Jahr**.
- **Land** und **Sprache**: aus den TMDB-Details (oder vom Emby-, Jellyfin- oder Plex-Server).
- **Qualität**: **4K** (2160p, UHD), **HD** (1080p, 720p, Blu-ray, WEB-DL …) oder andere, anhand des Dateinamens.
- **Status**: **Ungesehen**, **Begonnen**, **Gesehen** oder **Favoriten**.
- **Sortierung**: Titel, kürzlich hinzugefügt, Jahr, **TMDB-Bewertung** oder **Dauer**.

Bewertungen, Laufzeiten, Länder und Sprachen der Dateien in Ihren Ordnern stammen von TMDB (ein [TMDB-Schlüssel](help:tmdb) ist erforderlich): Sie erscheinen im Lauf der Detailsuche, die beim ersten Mal einige Minuten dauert. Ein Film ohne Bewertung steht bei der Sortierung nach Bewertung am Ende.

## Fensteraufbau und Seitenleiste {#colonnes}

![Fensteraufbau und Seitenleiste](img:layout)

<!--mac-->
In der klassischen Oberfläche hat das Fenster drei Spalten:

- **Seitenleiste**: Start, Live, Filme, Serien, Favoriten, Zuletzt, TV-Programm, danach die Kategorien des gewählten Bereichs und der Status Ihrer Quellen.
- **Liste**: die Einträge des Bereichs oder der Kategorie, bei Sendern mit der aktuellen Sendung. Das Feld **Suchen** filtert die Liste unabhängig von Groß-/Kleinschreibung und Akzenten.
- **Player**: das Video, darunter die aktuelle Sendung, ihr Fortschritt und die kommenden Sendungen.

Mit einem Rechtsklick auf einen Eintrag können Sie ihn zu den Favoriten hinzufügen oder die Adresse des Streams kopieren.
<!--/mac-->

<!--pc-->
Auswahl Live / Filme / Serien, dann: alle Sender oder Filme, **Favoriten**, **Zuletzt** und für Live-TV **Themen**, **TV-Programm** und **MultiView**; **Aufnahmen**; die **Kategorien**. Unten: die aktuelle Aufnahme und der aktuelle Download (Fortschritt, Restzeit) und **Einstellungen**.
<!--/pc-->

## Drei Oberflächen zur Auswahl {#interfaces}

<!--mac-->
Kastideo bietet drei Darstellungen, die Sie **getrennt für Live, Filme, Serien und Favoriten / Zuletzt** wählen:

- **Klassisch**: die drei Spalten, beschrieben unter [Fensteraufbau und Seitenleiste](help:colonnes).
- **TV** (nur Live): siehe [Die TV-Oberfläche](help:interface-tv).
- **Kino**: ein großes, scrollendes **„Empfohlen“-Banner** (siehe [Das „Empfohlen“-Banner](help:bandeau)), danach **horizontale Zeilen**: Weiterschauen, Favoriten und eine Zeile pro Kategorie. Filme und Serien erscheinen als Poster, Sender als Miniaturen mit der aktuellen Sendung. Ein Klick auf einen Sender öffnet den Player im Vollbild. Ein Klick auf das Poster eines **Films** oder einer **Serie** öffnet zuerst die **Detailseite**: Hintergrundbild, Poster, Jahr, Laufzeit, Genres, Bewertung, Inhaltsangabe, Regie, Besetzung (mit Fotos), oben links eine Schaltfläche **Zurück zu Filme** (oder Serien), **Abspielen** / **Fortsetzen**, **Folgen ansehen**, **Trailer**, **Herunterladen** und die Favoriten-Schaltflächen. Die Informationen stammen von Ihrem IPTV-Anbieter; fügen Sie einen kostenlosen **TMDB**-Schlüssel hinzu (Einstellungen > Allgemein > Details zu Filmen und Serien), um umfangreichere Seiten zu erhalten. **Zurück** (oder Esc) führt zum Katalog zurück. Oben im Fenster ersetzen die Tabs **Live / Filme / Serien / Guide / Favoriten / Zuletzt / Aufnahmen** die Seitenleiste; die Suche funktioniert wie in der klassischen Oberfläche. „Alle anzeigen“ öffnet eine komplette Kategorie als Raster.

So wechseln Sie die Oberfläche:

- die Schaltfläche **Oberfläche** in der Symbolleiste (sie gilt für den angezeigten Inhaltstyp),
- das Menü **Darstellung**: **⌥⌘1** Klassisch, **⌥⌘2** Kino, **⌥⌘3** TV (Live),
- oder **Einstellungen > Darstellung**.

Zum Beispiel: TV für Live und Kino für Filme und Serien. Der Bereich **Aufnahmen** wird immer in der klassischen Oberfläche angezeigt. Standard ist überall Klassisch.
<!--/mac-->

<!--pc-->
Einstellungen > Darstellung > **Oberfläche pro Inhaltstyp**:

- **Klassisch**: drei Spalten (Seitenleiste, Liste mit der aktuellen Sendung, Player oder Details rechts).
- **Kino**: Empfohlen-Banner, Poster oder Miniaturen in horizontalen Zeilen, Details als ganze Seite. Für Live-TV: Zeilen „Sport gerade jetzt“, „Nachrichten live“, „Heute Abend“ pro Thema, Favoriten, Zuletzt, Kategorien; ein Klick öffnet den Sender im Vollbild, **Zurück** (oder Esc) beendet ihn.
- **TV** (nur Live): der Sender im Vollbild, wie im Fernsehen (siehe [Die TV-Oberfläche](help:interface-tv)).
<!--/pc-->

## Das „Empfohlen“-Banner (Kino) {#bandeau}

<!--mac-->
Oben in Filme und Serien blättert ein **Karussell in voller Breite** durch eine Auswahl: Hintergrundbild, Poster, Titel, Jahr, Laufzeit, Genres, Bewertung, Inhaltsangabe und die Schaltflächen **Abspielen** (oder **Fortsetzen** / **Folgen ansehen**), **Mehr Infos** (die Detailseite) und **Trailer**. Es mischt:

- die **TMDB-Trends** dieser Woche, die in Ihrem Katalog zu finden sind (TMDB-Schlüssel erforderlich);
- die **neuesten Neuzugänge** Ihres Anbieters;
- eine **Auswahl aus einer Kategorie** Ihrer Wahl (zum Beispiel „Neuerscheinungen“ oder „Netflix“) oder zufällig aus dem gesamten Katalog.

Das Scrollen pausiert, solange die Maus über dem Banner ist; Pfeile und Punkte ermöglichen die Navigation. Unter **Live** zeigt das Banner, **was gerade läuft**, auf Ihren Favoriten- und zuletzt gesehenen Sendern, mit Fortschritt, der nächsten Sendung und **Ansehen**.

Einstellungen > Darstellung > **„Empfohlen“-Banner**: ein- oder ausblenden, Höhe (kompakt, normal, groß), Scrollgeschwindigkeit, Quellen des Karussells sowie Film- und Serienkategorien.
<!--/mac-->

<!--pc-->
Es blättert durch Filme oder Serien (die TMDB-Trends dieser Woche, die Ihnen zur Verfügung stehen, neueste Neuzugänge, eine Kategorieauswahl) oder bei Live-TV durch die aktuelle Sendung Ihrer Sender. Pfeile beim Darüberfahren; pausiert, solange die Maus darüber ist. Einstellungen > Darstellung > **Empfohlen-Banner**: ein- oder ausblenden, Höhe, Geschwindigkeit, Quellen.
<!--/pc-->

## Länder und Sprachen (Kino) {#pays}

<!--mac-->
Anbieter mischen oft mehrere Länder (Kategorien „FR| …“, „|PT| …“, „ITALIA“ …). Einstellungen > Darstellung > **Länder und Sprachen (Kino-Oberfläche)** listet die in Ihren Kategorienamen gefundenen Länder mit der Anzahl der Einträge auf: Haken Sie die an, die Sie sehen möchten. **Neueste Neuzugänge**, **Trends**, das **Empfohlen-Banner** und die **Kategoriezeilen** der Kino-Oberfläche zeigen dann nur diese Länder. **Kategorien ohne Land beibehalten** behält Kategorien wie „Action“ oder „Neu“. **Alle Länder** kehrt zur vollständigen Anzeige zurück. Klassische Listen und die Suche bleiben vollständig.
<!--/mac-->

<!--pc-->
Anbieter mischen oft mehrere Länder (Kategorien „FR| …“, „|PT| …“, „ITALIA“ …). Einstellungen > Darstellung > **Länder und Sprachen (Kino-Oberfläche)** listet die in Ihren Kategorienamen gefundenen Länder mit der Anzahl der Einträge auf: Wählen Sie die aus, die angezeigt werden sollen. **Neueste Neuzugänge**, **Trends**, das **Empfohlen-Banner** und die **Kategoriezeilen** der Kino-Oberfläche zeigen dann nur diese Länder. **Kategorien ohne Land beibehalten** behält Kategorien wie „Action“ oder „Neu“. **Alle** kehrt zur vollständigen Anzeige zurück. Listen und die Suche bleiben vollständig.
<!--/pc-->

## Die TV-Oberfläche (Live) {#interface-tv}

<!--mac-->
Der Sender füllt das gesamte Bild, wie im Fernsehen. Beim ersten Erscheinen setzt Kastideo den zuletzt gesehenen Sender fort.

- **Senderliste**: Taste **←**, **Return** oder die Maus an den linken Rand bewegen. Sie listet die Sender mit Nummer, Logo, aktueller Sendung und Fortschritt auf. Das Menü oben filtert nach **Alle / Favoriten / Zuletzt / Kategorie**, und das Feld **Suchen** filtert nach Namen. Sie schließt sich nach einigen Sekunden von selbst (**→** oder **Esc**, um sie sofort zu schließen).
- **Zappen**: **↑ / ↓** vorheriger / nächster Sender in der angezeigten Liste, **B** zurück zum vorherigen Sender.
- **Sendernummer**: Geben Sie die Ziffern ein (zum Beispiel **1**, dann **2**); der Sender öffnet sich nach 1,6 s oder mit **Return**. Nummeriert Ihr Anbieter seine Sender nicht, bezieht sich die Nummer auf die Position in der angezeigten Liste.
- **Info-Banner**: wird bei jedem Senderwechsel fünf Sekunden lang angezeigt (Logo, Nummer, aktuelle Sendung, Zeiten, nächste Sendung, Uhrzeit). **I** oder **→** zeigt oder verbirgt es.
- Weitere Tasten: **F** Favorit, **M** Stumm, **Leertaste** Pause (zeitversetztes Live).
- Doppelklick auf das Bild oder **⌘↩**: Vollbild; die Symbolleiste wird ausgeblendet.
- Tastaturbefehle funktionieren nicht, während Sie im Suchfeld tippen. Mit den Tabs oben im Fenster wechseln Sie zu Filme, Serien usw.
<!--/mac-->

<!--pc-->
- **↑ / ↓**: vorheriger / nächster Sender; **Nummer eingeben** (bis zu 4 Ziffern).
- **←** oder linker Rand: **Senderliste** (Filter, Suche, aktuelle Sendung).
- **→** oder **I**: **Info-Banner** (aktuelle und nächste Sendung).
- **B**: vorheriger Sender — **F**: Favorit — **M**: Ton — **Leertaste**: Pause — **G**: TV-Programm — **H**: Start.
<!--/pc-->

## Das TV-Programm-Raster {#guide-grille}

<!--pc-->
Einstellungen > Allgemein > Startseite > **Beim Öffnen des Programms**: **Jetzt** (aktuelle Uhrzeit) oder **Letzte Position** (Uhrzeit und Kategorie des letzten Besuchs). Auf der Serienseite markiert **Gesehen / nicht gesehen** eine Staffel oder die ganze Serie.
<!--/pc-->

<!--mac-->
Der Bereich **TV-Programm** (Seitenleiste, Tab **TV-Programm** der Kino- und TV-Oberflächen, **⌘7** oder die Taste **G** in der TV-Oberfläche). Die Sender stehen in Zeilen, die Uhrzeiten in Spalten; die rote Linie markiert die aktuelle Zeit.

- **‹ ›** verschieben das Raster, **Jetzt** springt zurück zur aktuellen Zeit, das Datumsmenü springt zu einem anderen Tag (19 Uhr an den Folgetagen).
- Wählen Sie den angezeigten Zeitraum (**2 h / 3 h / 6 h**), filtern Sie nach **Favoriten**, **Zuletzt** oder **Kategorie** oder suchen Sie einen Sender.
- Klicken Sie auf eine Sendung: Beschreibung, Schaltfläche **Ansehen**, **Aufnehmen** (laufende Sendung) oder **Aufnahme planen** (kommende Sendung). Ein roter Punkt markiert eine geplante Aufnahme.
- Vergangene Tage (Datumsmenü, Abschnitt **Nochmal ansehen**) und mit ↺ markierte Sendungen ermöglichen **Replay** (siehe [Replay](help:replay)).
- Klicken Sie auf einen Sendernamen, um ihn anzusehen. Es werden nur Sender mit Sendungen aufgelistet: Ist das Raster leer, prüfen Sie die Guide-Adresse in den Einstellungen der Quelle.
<!--/mac-->

<!--pc-->
Start, Live-Seitenleiste, **Strg+7** oder die Taste G in der TV-Oberfläche. Sender in Zeilen, Uhrzeiten in Spalten, eine rote Linie bei der aktuellen Zeit; **‹ Jetzt ›**, Tageswähler, Zeitraum 2 h / 3 h / 6 h, Filter (alle, Favoriten, Zuletzt, Thema, Kategorie) und Suche. Ein Klick auf eine Sendung öffnet ihre Details: **Ansehen**, **Aufnehmen**, **Aufnahme planen** (roter Punkt im Raster) oder **Erinnern, wenn es beginnt** (Glocke). Bei einer vergangenen Sendung eines Senders mit Replay (↺): **Nochmal ansehen** oder **Dieses Replay speichern**; vergangene Tage finden Sie im Datumsmenü.
<!--/pc-->

## Live-TV nach Themen {#direct-theme}

<!--mac-->
Der Bereich **Themen** der Seitenleiste (unter Live) sortiert Live-TV nach **Thema** — Sport, Auto & Moto (Motorsport), Filme, Serien, Nachrichten, Dokumentationen, Natur / Jagd & Angeln, Kinder, Unterhaltung, Essen & Wohnen, Musik, Allgemein, Regional (Regionen von France 3, lokales Fernsehen), International (ausländische Sender), Religion, Radio — ohne die Kategorien, die Sie ausgeblendet haben. Drei Modi:

- **Jetzt**: was gerade läuft, sortiert nach dem **Genre der Sendung** im TV-Programm (ein Film auf einem Vollprogramm erscheint unter „Filme“), mit Fortschritt. Sender **ohne Guide-Daten** werden ebenfalls aufgelistet, wenn ihr **Name zur Einordnung genügt** (beIN Sports → Sport …): Sie zeigen ihren Namen, ohne Fortschritt.
- **Heute Abend**: Sendungen, die **zwischen 20 und 23 Uhr** beginnen. Rechtsklick auf eine kommende Sendung > **Erinnern, wenn sie beginnt**.
- **Sender**: nach Spezialgebiet sortierte Sender. Das Thema wird automatisch aus dem Sendernamen abgeleitet (beIN, Eurosport → Sport; BFM, LCI → Nachrichten …) und danach aus den üblichen Sendungen; Rechtsklick > **Thema des Senders**, um es zu korrigieren.

Jeder Sender erscheint **nur einmal**, auch wenn Ihr Anbieter ihn in mehreren Versionen anbietet (4K, FHD, HD, SD): Kastideo wählt die zu **Ihrer Verbindung** passende Version (Einstellung **Automatisch** unter Einstellungen > Allgemein > Wiedergabe > Senderversion) — es schaltet nach instabiler Wiedergabe herunter und nach drei flüssigen wieder hoch. Rechtsklick > **Version**, um eine andere zu wählen.

Themen werden auch an anderer Stelle angeboten: Zeilen „Sport jetzt“, „Filme jetzt“ … oben in Live in der **Kino**-Oberfläche, ein Filter **Themen** in der Senderliste der **TV**-Oberfläche und im **TV-Programm** sowie Chips „Jetzt im TV“ (und „Heute Abend“) auf dem **Startbildschirm**.

Unter **Sport** filtert eine zweite Zeile nach **Disziplin**: Fußball, Rugby, Tennis, Basketball, Kampfsport, Golf, Radsport, Handball, Motorsport, Wintersport, Pferdesport, Leichtathletik & Schwimmen (anhand von Sendungstiteln, Genres und Beschreibungen).

**Inhalte für Erwachsene**: Sender und Inhalte, deren Name „|XX|“ enthält (oder die in einer Erwachsenenkategorie liegen), sind standardmäßig **überall ausgeblendet**. Um sie und das Thema **Erwachsene** anzuzeigen: Einstellungen > Allgemein > Wiedergabe > **Inhalte für Erwachsene anzeigen**.

**Sendungserinnerungen** (Schaltfläche 🔔 der Themen-Ansicht): Kastideo erinnert Sie zwei Minuten vor Beginn einer Sendung, deren Titel ein gewähltes Wort enthält („PSG“, „Formel 1“ …), eines Themas auf Ihren Favoritensendern oder einer bestimmten Sendung. Es erscheinen eine Benachrichtigung und ein Banner **Ansehen**.
<!--/mac-->

<!--pc-->
Seitenleiste > **Themen**: **Gerade jetzt**, **Heute Abend** (20–23 Uhr) oder **Sender**, gefiltert nach Thema (Sport, Nachrichten, Filme, Kinder, Dokumentationen …) und beim Sport nach Disziplin. Eine Version pro Sender (FHD, HD oder SD je nach Verbindung). Rechtsklick: Senderversion, **Thema des Senders** (zum Korrigieren der Einordnung), Favoriten, Sender bearbeiten.
<!--/pc-->

# Wiedergabe

## Das Wichtigste {#lecture}

<!--pc-->
Unter **Windows, Linux und Android** bietet das Menü **⋯** der Player-Leiste **Geschwindigkeit** (Filme, Folgen), **Tonspuren**, **Untertitel** und **Bildformat** (anpassen, Bildschirm füllen, 16:9, 4:3). Live schalten **◀◀ / ▶▶** zum vorherigen oder nächsten Sender der Kategorie; die Leiste zeigt die **laufende Sendung** mit Fortschritt und die nächste. Bei einer Folge erscheinen **Weiter** und **Folgen…**, und die nächste Folge startet am Ende von selbst (abschaltbar unter Einstellungen > Allgemein > Wiedergabe).
<!--/pc-->

<!--mac-->
Kastideo spielt alle Inhalte mit der **VLC**-Engine ab: Live-MPEG-TS (.ts), HLS (.m3u8), MP4, MKV, AVI …

- Die Wiedergabe beginnt, sobald Sie einen Sender, einen Film oder eine Folge auswählen.
- Beim Öffnen werden das Logo und der Name des Senders angezeigt. Das Abzeichen **„Bereit in x s“** zeigt danach die Startzeit (in den Einstellungen abschaltbar).
- Die Steuerelemente erscheinen, wenn Sie mit der Maus über das Video fahren: Wiedergabe / Pause, 10 s zurück und 30 s vor bei Filmen und Folgen, Fortschrittsleiste, Lautstärke (bis 200 %) und Kinomodus.
- Ein Klick auf das Video pausiert es; ein **Doppelklick** schaltet den **Kinomodus** ein: Das Fenster geht in den Vollbildmodus und nur das **Video** bleibt sichtbar (keine Spalten und keine Symbolleiste; die grüne Fensterschaltfläche und **⌃⌘F** bewirken während der Wiedergabe dasselbe). **Esc** oder **⌘↩**, um ihn zu verlassen.
- **Wiedergabe fortsetzen**: Bei Filmen und Folgen merkt sich Kastideo Ihre Position. Öffnen Sie einen erneut, wird dort fortgesetzt, wo Sie aufgehört haben, mit einer Meldung, die anbietet, **von vorn zu beginnen**. In Listen, auf Postern und bei Folgen erscheinen Fortschrittsbalken. Das lässt sich in den Einstellungen abschalten, und Positionen lassen sich dort löschen.
- Bei Xtream-Quellen wird Live im MPEG-TS-Format (.ts) abgespielt, wie im Xtream-Referenzplayer; schlägt der Stream fehl, probiert Kastideo automatisch die .m3u8-Variante (und umgekehrt).
<!--/mac-->

<!--pc-->
Der Player (mpv-Engine) hat eine Steuerleiste, die sich von selbst ausblendet, einen Zustandspunkt für den Stream, Lautstärke, Kinomodus (Doppelklick oder Strg+Eingabe) und Vollbild (F11). Bei Filmen und Folgen: Mini-Zeitleiste, −10 s / +30 s, **Fortsetzen**, wo Sie aufgehört haben, **Zurück zu den Details**.
<!--/pc-->

## Steuerleiste, Zeitleiste und Informationsbereich {#barre-controle}

<!--mac-->
- **Sich selbst ausblendende Leiste**: Sie erscheint bei der kleinsten Mausbewegung und verschwindet samt Zeiger nach 3 Sekunden Inaktivität (sie bleibt, solange die Maus darüber ist, bei Pause oder bei geöffnetem Bereich).
- **Stopp** (Schaltfläche ■ neben Wiedergabe / Pause oder **⌘.**): beendet den Stream. Der Videobereich zeigt „Keine Wiedergabe“ mit einer Schaltfläche **Neu starten**; die Position eines Films oder einer Folge wird für die Fortsetzung gespeichert. Beim Casten beendet Stopp auch das Casting und der Fernseher kehrt zu seinem Programm zurück. Wird der Sender gerade aufgenommen, fragt Kastideo nach Bestätigung (die Aufnahme endet mit der Wiedergabe).
- **Mini-Zeitleiste** (Filme und Folgen): eine dünne Linie über den Schaltflächen, die beim Darüberfahren dicker wird und die Zielzeit anzeigt; klicken oder ziehen, um zu springen.
- **Stream-Zustand**: Ein **grüner** (Ausgezeichnet), **oranger** (Mittelmäßig) oder **roter** (Instabil) Punkt zeigt die Empfangsqualität an, zusammen mit der Auflösungsklasse (SD, HD, 4K). Beim Darüberfahren: genaue Auflösung, Bitrate, Bilder pro Sekunde, verworfene Bilder und Unterbrechungen in der letzten Minute.
- **Informationsbereich** (Schaltfläche ⓘ oder **⌘I**, Esc zum Schließen): Er gleitet von rechts über das Video und zeigt den Sender mit seiner aktuellen und den kommenden Sendungen oder die Inhaltsangabe und Besetzung eines Films; die Auswahl von **Tonspur** (Sprache, Audiodeskription …) und **Untertiteln**; die detaillierte Empfangsqualität.
<!--/mac-->

## MultiView (mehrere Sender gleichzeitig) {#multivue}

<!--mac-->
**MultiView** zeigt bis zu **4 Live-Sender** in einem Fenster (1 im Vollbild, 2 nebeneinander, 3 oder 4 im Raster). **Der Ton folgt der aktiven Kachel** (oranger Rand): Klicken Sie auf eine Kachel oder verwenden Sie die Tasten **1 bis 4**.

- Öffnen: **Wiedergabe > MultiView …** (**⌥⌘M**) oder Rechtsklick auf einen Sender > **Zu MultiView hinzufügen**.
- Im Fenster: **+** fügt einen Sender hinzu (Favoriten, Zuletzt oder Suche); beim Darüberfahren über eine Kachel wechselt ⟳ den Sender und ✕ entfernt ihn; **Alle beenden** stoppt jeden Stream. Das Schließen des Fensters beendet MultiView.
- Jeder Stream nutzt **eine Verbindung** zu Ihrem Anbieter, deshalb ist MultiView **standardmäßig aus**: Geben Sie die Anzahl der gleichzeitigen Verbindungen Ihres Abonnements unter **Einstellungen > Allgemein > Wiedergabe** (2 bis 4) ein, um es zu aktivieren. Die Schaltfläche **Verbindung testen** einer Xtream-Quelle zeigt diese Zahl an. Beim Öffnen wird die Hauptwiedergabe gestoppt, um ihre Verbindung freizugeben (außer bei einer Aufnahme); auch eine Aufnahme oder ein Download nutzt eine Verbindung.
<!--/mac-->

<!--pc-->
**MultiView** zeigt bis zu **4 Live-Sender** auf einem Bildschirm. **Der Ton folgt der aktiven Kachel** (oranger Rand).

- **Aktivieren**: Jeder Sender nutzt eine Verbindung zu Ihrem Anbieter, daher bleibt MultiView aus, bis Sie die Anzahl der **gleichzeitigen Verbindungen** Ihres Abonnements festgelegt haben: Einstellungen > Allgemein > Wiedergabe (2 bis 4). **Erkennen** fragt Ihre Xtream-Quellen ab.
- **Öffnen**: Start > **MultiView**, Live-Seitenleiste > **MultiView**, **Strg+Alt+M** oder Rechtsklick auf einen Sender > **Zu MultiView hinzufügen**. Der Sender, den Sie gerade ansahen, wird zur ersten Kachel; wird er aufgenommen, nimmt er im Hintergrund stumm weiter auf.
- **Hinzufügen**: Schaltfläche **+** (oder Taste **A**): Favoriten, Zuletzt, alle Sender oder Suche. Auch eine leere Zelle des Rasters bietet „Sender hinzufügen“ an.
- **Anordnungen** (oben rechts): **Automatisch** (1 im Vollbild, 2 nebeneinander, 3 oder 4 im Raster), **2 × 2-Raster**, **Einer groß** und die anderen klein, **Nebeneinander**. Die Anordnung wird gespeichert.
- **Große Ansicht ↔ Kachel**: **Doppelklick** auf eine Kachel (oder Taste **G**), um sie mit Ton groß darzustellen; erneuter Doppelklick auf die große Ansicht führt zum Raster zurück.
- **Beim Darüberfahren über eine Kachel**: vergrößern, Sender wechseln, entfernen. Der Sendername und die aktuelle Sendung werden unten angezeigt.
- **Gespeicherte Gruppen** (Lesezeichen-Symbol): **Diese Gruppe speichern …** speichert die Sender und die Anordnung unter einem Namen (z. B. „Fußball-Multiplex“); ein Klick auf eine Gruppe öffnet sie erneut, das Kreuz löscht sie.
- **Tastatur**: **1 bis 4** Ton auf dieser Kachel, **G** vergrößern, **A** hinzufügen, **M** stumm, **Entf** aktive Kachel entfernen, **F** oder **F11** Vollbild, **Esc** Vollbild verlassen, dann MultiView.
- **Alle beenden** (oder Zurück) stoppt jeden Stream und kehrt zum vorherigen Bildschirm zurück.

> Auch eine Aufnahme oder ein Download nutzt eine Verbindung: Ein Symbol ⓘ in der MultiView-Leiste erinnert Sie daran. Zeigt eine Kachel „Der Sender antwortet nicht“, lehnt der Anbieter wahrscheinlich eine zusätzliche Verbindung ab: Entfernen Sie einen Sender oder verringern Sie die Anzahl der Verbindungen.
<!--/pc-->

## Mehrere Live-Quellen: MultiView und Bild-in-Bild {#multivue-sources}

Wenn Sie **mehrere Live-Quellen** haben (zwei IPTV-Abonnements oder ein Abonnement und eine Liste öffentlicher Sender), **mischt** [MultiView](help:multivue) sie. Es gibt drei Schritte.

**1. Verbindungen jedes Abonnements.** Unter **Einstellungen > Allgemein > Wiedergabe** legt eine Zeile pro Abonnement (Name + Konto-ID, um zwei Konten desselben Anbieters zu unterscheiden) die Anzahl der gleichzeitig erlaubten Streams fest: 1 bei den meisten Abonnements, 4 bei einer öffentlichen Liste. Unter Windows, Linux und Android fragt **Erkennen** die Xtream-Konten ab.

**2. Anzahl der Bildschirme.** Legen Sie im MultiView-Fenster die Anzahl der **Bildschirme** fest (1 bis 4, höchstens die Summe der Verbindungen Ihrer Quellen).

**3. Quelle jedes Bildschirms.** Jeder Bildschirm ist **einer Quelle vorbehalten**: Über das Abzeichen oben auf dem Bildschirm können Sie sie ändern. Die Senderauswahl dieses Bildschirms bietet nur Sender seiner Quelle an, und eine Quelle kann nicht mehr Bildschirme reservieren, als sie Verbindungen hat.

**Anordnung**: nebeneinander, übereinander, Raster oder **einer groß + Miniaturen (PIP)** (Anordnungsmenü von MultiView). Bei Letzterem füllt ein Sender das Bild und die anderen schweben als **kleine 16:9-Miniaturen**: **Ziehen** Sie eine Miniatur, um sie zu verschieben (sie rastet an der nächsten Ecke ein), **doppelklicken** Sie darauf, um sie mit der großen zu tauschen (der Ton folgt), und legen Sie ihre **Größe** (klein, mittel, groß) in der MultiView-Leiste fest. Ein einzelner Klick gibt einer Miniatur den Ton.

**Einen Sender auswählen.** Die Auswahl entspricht der klassischen Oberfläche: links **Favoriten**, **Zuletzt** und die **Kategorien der Quelle des Bildschirms** (in Ihrer Reihenfolge, mit den ausgeblendeten oder umbenannten Kategorien aus „Kategorien verwalten“), rechts die Sender mit ihrer aktuellen Sendung. Ein **Klick** spielt den Sender auf dem Bildschirm ab und lässt die Auswahl zum Zappen geöffnet; ein **Doppelklick** spielt ihn ab und schließt sie. Ein Sender, der bereits auf einem anderen Bildschirm läuft, ist ausgegraut. Die Suche umfasst alle Kategorien der Quelle.

**Wo finde ich MultiView?** Auf dem Mac: der Eintrag **MultiView** in der Seitenleiste, die Schaltfläche in der Symbolleiste, die Schaltfläche **MultiView** auf dem Startbildschirm (neben Favoriten und Aufnahmen), die Schaltfläche in der Player-Leiste (öffnet MultiView mit dem Sender, den Sie gerade ansehen), das Menü Wiedergabe und ⌥⌘M. Unter Windows, Linux und Android: Start, die Live-Seitenleiste, die Schaltfläche in der Player-Leiste und Strg+Alt+M.

**Bild-in-Bild (PIP).** Während ein Live-Sender läuft, öffnet die Schaltfläche **Bild-in-Bild** (oben rechts im Player) einen **zweiten Sender in einem kleinen Fenster** in einer Ecke, stumm. **Klicken Sie auf das kleine Fenster**, um es mit dem Hauptsender zu tauschen, oder auf das Kreuz, um es zu schließen. Der zweite Sender muss aus einer Quelle mit einer freien Verbindung stammen: Wählen Sie bei einem einzigen, auf eine Verbindung begrenzten Abonnement einen Sender aus der öffentlichen Liste (oder von einem zweiten Abonnement). Das kleine Fenster schließt sich, wenn Sie den Player verlassen.

## Wenn ein Sender nicht startet {#chaine-ne-demarre-pas}

<!--mac-->
Kommt nach **20 Sekunden** kein Bild an, probiert Kastideo automatisch das andere Streamformat (.ts oder .m3u8) und zeigt dann eine Fehlermeldung mit den Details der VLC-Engine an.

Das **Protokoll** (Menü **Wiedergabe > Wiedergabeprotokoll …**, **⌥⌘L** oder die Schaltfläche in der Fehlermeldung) ist das Diagnosewerkzeug von Kastideo. Benutzernamen und Passwörter sind darin **verborgen**: Sie können es kopieren und bei einem Problem weitergeben.

- **Themen**: Die Meldungen werden in *TV-Programm*, *Wiedergabe und Relay*, *Quellen und Kataloge*, *Aufnahmen*, *TMDB-Details*, *Updates* und *Anzeige und Sonstiges* einsortiert. Klicken Sie auf ein oder mehrere Themen, um nur diese zu sehen (die Zeilenzahl jedes Themas wird angezeigt).
- **Suchen** Sie ein Wort im Protokoll oder zeigen Sie nur **Fehler und Warnungen**.
- **Angezeigtes kopieren** kopiert nur, was angezeigt wird (Themen, Suche), mit dem oben vermerkten Filter.
- **Detailgrad** (pro Thema): *Normal* (das Wesentliche), *Detailliert* (Standard für den TV-Programm) oder *Debug* (alles). Die Einstellung gilt für ab dann geschriebene Zeilen; Fehler und Warnungen werden immer behalten.
- **Aktuelle Sitzung / Vorherige Sitzung**: Das Protokoll wird auf der Festplatte aufbewahrt, sodass Sie nachlesen können, was beim Start der vorherigen Sitzung geschehen ist. **Protokollordner anzeigen** zeigt die Datei im Finder.
<!--/mac-->

## Zeitversetztes Live {#differe}

<!--mac-->
**Pausieren** Sie einen Live-Sender: Die VLC-Engine empfängt den Stream weiter und speichert ihn. Wenn Sie fortsetzen, sehen Sie **zeitversetzt** (gelbe Anzeige „ZEITVERSETZT −2:34“ in den Steuerelementen). Lässt sich ein Stream nicht pausieren, ist die Schaltfläche ausgegraut.

Beim zeitversetzten Sehen bieten die Steuerelemente:

- eine **Zeitleiste**: links der Pausenpunkt, rechts **Live**. **Ziehen Sie den Cursor nach rechts**, um vorzuspulen: Kastideo beschleunigt die Wiedergabe bis zum gewählten Punkt (gelbe Markierung) und kehrt dann zur normalen Geschwindigkeit zurück;
- **+30 s** (oder ⌘]): spult auf dieselbe Weise 30 Sekunden vor;
- die **Geschwindigkeit** (×1, ×1,25, ×1,5, ×2): beschleunigen, um die Verzögerung zu verringern; die Wiedergabe kehrt von selbst zu ×1 zurück, wenn sie Live eingeholt hat;
- **Aufholen**: beschleunigt bis Live, ohne etwas zu überspringen;
- **Zurück zu Live**: kehrt sofort zu Live zurück. Da die VLC-Engine im Zeitversatz-Puffer in der Regel nicht springen kann, wird der Stream neu geöffnet und der Puffer geleert. Erlaubt der Stream das Springen, bleibt der Puffer erhalten und −10 s / +30 s springen direkt.

**Wo wird der Zeitversatz gespeichert?** Im temporären Ordner von Kastideo (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, Dateien `vlc-timeshift-…`), der beim Senderwechsel geleert wird; rechnen Sie je nach Qualität mit 1 bis 4 GB pro Stunde. Einstellungen > Allgemein > Wiedergabe: **Maximale Zeitversatz-Dauer** (30 Min. bis 3 Std. oder unbegrenzt; ist sie erreicht, wird die Wiedergabe von selbst fortgesetzt), **Aufholgeschwindigkeit** und eine Schaltfläche **Anzeigen**, um den Ordner zu öffnen.
<!--/mac-->

<!--pc-->
Pausieren Sie einen Sender (oder gehen Sie mit ← oder der Leiste zurück): Er wird weiter gepuffert (standardmäßig bis zu 1 Std., einstellbar). Ohne Zutun bleibt der Sender „LIVE“. Die Zeitversatz-Leiste zeigt die Verzögerung, einen Schieberegler zum Zurückgehen oder schnelleren Aufholen, die Geschwindigkeit, **Aufholen** und **Zurück zu Live**. ← / →: −10 s / +30 s.
<!--/pc-->

## Replay: eine bereits gelaufene Sendung ansehen {#replay}

<!--mac-->
Manche IPTV-Abonnements halten Sender bis zu **14 Tage** lang vor (je nach Anbieter und Sender). Kastideo erkennt das von selbst: Sender mit Replay zeigen in Listen und im TV-Programm ein Symbol **↺**.

- **Im TV-Programm**: Klicken Sie auf eine **vergangene** Sendung (mit ↺ markiert), dann auf **Nochmal ansehen**. Bei der **aktuellen** Sendung spielt **Von Anfang an ansehen** sie von vorn ab. **Dieses Replay speichern** lädt die Sendung aus dem Archiv des Anbieters herunter (Aufnahmeordner).
- **Vorherige Tage**: Das Datumsmenü des TV-Programms bietet **Nochmal ansehen (Replay)** mit den vergangenen Tagen.
- **Von einem Sender aus**: Rechtsklick auf den Sender > **Nochmal ansehen (Replay)** (aktuelle Sendungen dieses Senders). Die Kino-Oberfläche hat außerdem eine Zeile **Zum Wiederansehen** (Ihre Lieblingssender mit Replay).
- **Während eines Replays** können Sie in der Player-Leiste pausieren und sich innerhalb der Sendung bewegen. Am Ende **kehrt Kastideo zum Live-Stream des Senders zurück** (abschaltbar).
- **Einstellungen > Allgemein > Replay**: Replay ein- oder ausschalten, Anzahl der **im Guide gehaltenen Tage vergangener Sendungen** (mehr Tage = mehr Speicher), **Zeitversatz** (wenn die abgespielte Sendung um einige Minuten oder eine Stunde verschoben ist, korrigieren Sie das hier; die Zeitzone des Servers wird automatisch gelesen), Rückkehr zu Live.
- Ein Replay zählt als **eine Verbindung**: Es schließt den aktuellen Sender, wie beim Senderwechsel.
- Startet ein Replay nicht, öffnen Sie das **Protokoll** (Thema „Wiedergabe und Relay“): Dort stehen die gebildete Archivadresse und der verwendete Versatz. Der Guide des Anbieters muss vergangene Sendungen enthalten: Laden Sie ihn neu, nachdem Sie die Anzahl der gehaltenen Tage erhöht haben.
<!--/mac-->

<!--pc-->
Manche IPTV-Abonnements halten Sender bis zu **14 Tage** lang vor (je nach Anbieter und Sender). Kastideo erkennt das von selbst: Sender mit Replay zeigen in Listen und im TV-Programm ein Symbol **↺**.

- **Im TV-Programm**: Klicken Sie auf eine **vergangene** Sendung (mit ↺ markiert), dann auf **Nochmal ansehen**. Bei der **aktuellen** Sendung spielt **Von Anfang an ansehen** sie von vorn ab. **Dieses Replay speichern** lädt die Sendung aus dem Archiv des Anbieters herunter (Aufnahmeordner).
- **Vorherige Tage**: Das Datumsmenü des TV-Programms bietet **Nochmal ansehen (Replay)** mit den vergangenen Tagen.
- **Von einem Sender aus**: Rechtsklick auf den Sender > **Nochmal ansehen (Replay) …** (aktuelle Sendungen dieses Senders). Die Kino-Oberfläche hat außerdem eine Zeile **Zum Wiederansehen** (Ihre Lieblingssender mit Replay).
- **Während eines Replays** können Sie in der Player-Leiste pausieren und sich innerhalb der Sendung bewegen. Am Ende **kehrt Kastideo zum Live-Stream des Senders zurück** (abschaltbar).
- **Einstellungen > Allgemein > Replay**: Replay ein- oder ausschalten, Anzahl der **im Guide gehaltenen Tage vergangener Sendungen** (mehr Tage = mehr Speicher), **Zeitversatz** (wenn die abgespielte Sendung um einige Minuten oder eine Stunde verschoben ist, korrigieren Sie das hier; die Zeitzone des Servers wird automatisch gelesen), Rückkehr zu Live.
- Ein Replay zählt als **eine Verbindung**: Es schließt den aktuellen Sender, wie beim Senderwechsel.
- Startet ein Replay nicht, öffnen Sie das **Protokoll** (Schaltfläche Protokoll, Thema „Wiedergabe und Relay“): Dort stehen die gebildete Archivadresse und der verwendete Versatz. Der Guide des Anbieters muss vergangene Sendungen enthalten: Laden Sie ihn neu, nachdem Sie die Anzahl der gehaltenen Tage erhöht haben.
<!--/pc-->

## Eine Verbindung zur selben Zeit {#connexion-unique}

<!--mac-->
Die meisten IPTV-Abonnements erlauben nur **einen gleichzeitigen Stream**. Kastideo schließt immer den aktuellen Stream, bevor es den nächsten öffnet: Sie können zappen, ohne Ihr Limit zu überschreiten. Schlägt die Wiedergabe fehl, prüfen Sie, dass kein anderes Gerät (Fernseher, Smartphone, Piboard …) mit demselben Abonnement schaut.
<!--/mac-->

<!--pc-->
Die meisten Abonnements erlauben nur eine Verbindung. Kastideo schließt den vorherigen Sender, bevor es den nächsten öffnet (**Stream-Relay**, Einstellungen > Allgemein > Wiedergabe) und fragt nach, bevor es eine Aufnahme unterbricht.
<!--/pc-->

## Auf einen Fernseher übertragen (Cast) {#cast}

Senden Sie, was Sie gerade ansehen — **einen Live-Sender, Film, eine Serie, ein lokales Video oder YouTube** —, an einen Fernseher im selben Netzwerk, ohne Kastideo zu verlassen. Die Wiedergabeleiste bleibt Ihre Fernbedienung.

### Was möglich ist

- **Chromecast, Google TV, Android TV** (und viele Fernseher mit eingebautem Chromecast): Die gesamte Wiedergabe geht auf den Fernseher.
- **Apple TV (AirPlay)**: Kastideo kann das Video nicht direkt senden. Verwenden Sie die **Bildschirmspiegelung** von macOS (siehe unten).
- **YouTube**: Das Video öffnet sich in der YouTube-App des Fernsehers oder im Browser (Ihre Wahl in den Einstellungen).

### Etwas übertragen

1. Starten Sie einen Sender, einen Film, eine Serie oder ein Video.
2. Klicken Sie in der Wiedergabeleiste auf die Schaltfläche **TV**.
3. Wählen Sie das Gerät aus der Liste. Wird nichts angezeigt, klicken Sie auf **Erneut suchen**: Der Fernseher muss eingeschaltet und im selben Netzwerk sein.
4. Das Bild geht auf den Fernseher. Auf dem Computer erscheint ein Bildschirm mit „Übertragung auf …“.

Die Wiedergabe **setzt dort fort, wo Sie waren**. Pause, Wiedergabe, 10-/30-s-Sprung, Position, Lautstärke und Stumm in der Leiste wirken auf den Fernseher. Starten Sie während der Übertragung ein weiteres Element, wird es ebenfalls an den Fernseher gesendet.

Um zurückzukehren, wählen Sie **Übertragung beenden** (oder **Auf dem Computer fortsetzen**): Die Wiedergabe wird auf dem Computer an derselben Position fortgesetzt.

<!--pc-->
### ffmpeg: Umwandlung des Videos

Unter Windows und Linux bereitet Kastideo das Video mit **ffmpeg** auf, bevor es an den Fernseher gesendet wird. Es wird mit der Windows-Version und dem Linux-AppImage mitgeliefert. Beim .deb-Paket installieren Sie es selbst: `sudo apt install ffmpeg`. Findet Kastideo es nicht, geben Sie den Pfad unter **Einstellungen > Allgemein > Cast** an.

- **Videoaufbereitung**: *Automatisch* kopiert das Video, wenn es bereits H.264 ist (schont den Computer), und wandelt es sonst um; *Immer umwandeln* ist am kompatibelsten.
- **Maximale Auflösung**: 720p oder 1080p.
- **Einen Fernseher über seine IP-Adresse hinzufügen**: nützlich, wenn die automatische Suche ihn nicht sieht (Gast-WLAN, VLAN …).

Die Windows-Firewall fragt möglicherweise nach einer Freigabe für Kastideo: Stimmen Sie in **privaten** Netzwerken zu, sonst kann der Fernseher den Stream nicht lesen.
<!--/pc-->
<!--mac-->
### Apple TV und AirPlay

VLC, die Wiedergabe-Engine von Kastideo, sendet kein Video über AirPlay. Für einen Apple TV: **Kontrollzentrum > Bildschirmspiegelung** (oder **Systemeinstellungen > Displays**), den Apple TV auswählen und dann Kastideo im Vollbild abspielen. Die Schaltfläche TV in der Leiste bietet eine Abkürzung zu den Displayeinstellungen.

### Netzwerkberechtigung

Bei der ersten Verwendung fragt macOS, ob Kastideo **Geräte im lokalen Netzwerk finden** darf: Stimmen Sie zu, sonst erscheint kein Fernseher (Systemeinstellungen > Datenschutz & Sicherheit > Lokales Netzwerk > Kastideo). Das Menü der Schaltfläche TV hat eine Abkürzung zu dieser Einstellung. Ist sie bereits erlaubt, wählen Sie **Erneut suchen** und prüfen Sie, dass sich Mac und Fernseher im selben Netzwerk befinden (kein Gast-WLAN, kein VPN).
<!--/mac-->

### YouTube auf dem Fernseher

Wählen Sie unter **Einstellungen > Allgemein > Cast**:

- **Die YouTube-App des Fernsehers**: Kastideo bittet den Fernseher, YouTube mit dem gewählten Video zu öffnen (Rechtsklick auf ein Video > **Auf einem Fernseher abspielen**). Die YouTube-App muss auf dem Fernseher installiert sein.
- **Browser (Cast-Schaltfläche von Chrome)**: Das Video öffnet sich in Ihrem Browser; verwenden Sie die Schaltfläche **Cast** von Chrome, um es an den Fernseher zu senden.

### Einschränkungen, die man kennen sollte

- Eine Verbindung zu Ihrem Anbieter: Beim Casten spielt der Computer den Sender nicht mehr ab (siehe [Eine Verbindung zur selben Zeit](help:connexion-unique)).
- Bei **Live** kann beim Casten nicht gespult werden; der **Zeitversatz** des Computers wird abgeschnitten.
- Die **Aufnahme** von Sendern und **MultiView** lassen sich nicht mit dem Casten kombinieren.
- Es gibt einige Sekunden Verzögerung, mehr als bei lokaler Wiedergabe.
- Ein Fernseher, der auf die Suche nicht antwortet: Prüfen Sie, dass er eingeschaltet und im selben WLAN- oder Ethernet-Netzwerk wie der Computer ist.

## Eingefrorenes Bild: Software-Dekodierung {#image-figee}

Manche Sender zeigen ein Bild und bleiben dann **eingefroren**, während der Stream weiter ankommt. Die übliche Ursache ist, dass der **Hardware-Decoder** des Computers (Grafikkarte oder Videochip) bei diesem Stream versagt. Die **Software-Dekodierung** nutzt stattdessen den Prozessor: aufwendiger, aber toleranter.

### Automatischer Ausweichmodus

Bleibt das Bild standardmäßig länger als 6 Sekunden eingefroren (oder meldet der Hardware-Decoder wiederholt Fehler), **öffnet Kastideo den Sender erneut mit Software-Dekodierung** und merkt sich das: Spätere Wiedergaben dieses Senders verwenden sofort Software. Dem **Wiedergabeprotokoll** wird eine erklärende Zeile hinzugefügt („Décodage : … réouverture en décodage logiciel“).

<!--pc-->
Unter Windows und Linux beruht die Erkennung auf der Anzahl der von der Engine angezeigten Bilder und auf ihren Fehlermeldungen des Hardware-Decoders. Friert ein Sender ein, ohne erkannt zu werden, schalten Sie die Software-Dekodierung von Hand ein (unten) und geben Sie uns Bescheid.
<!--/pc-->

### Von Hand

- **Für einen Sender**: Rechtsklick auf den Sender > **Software-Dekodierung (eingefrorenes Bild)**. Der Sender wird sofort neu geöffnet; wiederholen Sie den Vorgang, um zum Hardware-Decoder zurückzukehren.
- **Für alles**: <!--mac-->**Einstellungen (⌘,) > Allgemein > Wiedergabe**<!--/mac--><!--pc-->**Einstellungen (Strg+,) > Allgemein > Wiedergabe**<!--/pc--> > **Immer per Software dekodieren**. Verbraucht mehr Energie und Prozessorleistung, besonders bei 4K.
- **Den automatischen Ausweichmodus ausschalten**: an derselben Stelle **Automatische Software-Dekodierung, wenn das Bild einfriert**.
- **Alles vergessen**: Die Schaltfläche „Zurücksetzen“ (Mac) oder „Auf Software-Dekodierung gesetzte Sender vergessen“ (Windows/Linux) löscht die gemerkte Liste.

### Wenn das nicht reicht

Ein Sender, der selbst per Software eingefroren bleibt, hat meist einen fehlerhaften Stream beim Anbieter: Prüfen Sie das **Wiedergabeprotokoll** und probieren Sie eine andere Version des Senders (HD, SD …).

## Puffer {#tampon}

<!--mac-->
Wählen Sie unter **Einstellungen > Allgemein > Wiedergabe** den Kompromiss zwischen Geschwindigkeit und Stabilität:

- **Schnell** (Standard): 0,4 s Reserve, kürzestes Zappen.
- **Ausgewogen**: 1 s.
- **Stabil**: 3 s, für unzuverlässige Verbindungen oder Server (weniger Unterbrechungen, langsamerer Start).
<!--/mac-->

## Das Protokoll (Diagnose) {#journal}

<!--pc-->
Das **Protokoll** (**Strg+Alt+L** oder die Schaltfläche auf dem Startbildschirm und in Fehlermeldungen) ist das Diagnosewerkzeug von Kastideo. Benutzernamen und Passwörter sind darin **verborgen**: Sie können es kopieren und weitergeben.

- **Themen**: *TV-Programm*, *Wiedergabe und Relay*, *Quellen und Kataloge*, *Aufnahmen*, *TMDB-Details*, *Updates*, *Anzeige und Sonstiges*. Klicken Sie auf ein oder mehrere Themen, um nur diese zu sehen (die Zeilenzahl pro Thema wird angezeigt).
- **Suchen** Sie ein Wort oder zeigen Sie nur **Fehler und Warnungen**.
- **Angezeigtes kopieren** kopiert nur, was angezeigt wird, mit dem Filter oben.
- **Detailgrad** (pro Thema): *Normal*, *Detailliert* (Standard für den TV-Programm) oder *Debug* (alles). Die Einstellung gilt für danach geschriebene Zeilen; Fehler und Warnungen werden immer behalten.
- **Aktuelle Sitzung / Vorherige Sitzung**: Das Protokoll wird auf der Festplatte aufbewahrt (der Ordnerpfad steht unten im Fenster), sodass Sie nachlesen können, was beim Start der vorherigen Sitzung geschehen ist.
<!--/pc-->

# Aufnahmen und Downloads

## Überblick {#enregistrements}

<!--mac-->
Alles befindet sich im Bereich **Aufnahmen** der Seitenleiste (**⌘6**): laufende Aufnahme, Umwandlungen, Downloads, Zeitpläne und aufgenommene Dateien (zum Ansehen anklicken, per Rechtsklick im Finder anzeigen oder löschen).

Die Dateien werden in **~/Movies/Kastideo** gespeichert (änderbar unter **Einstellungen > Aufnahmen**) und automatisch benannt, zum Beispiel „TF1 – Le goût du détail – 2026-10-18 20h50“.

**Aufnahmedauer.** Die Aufnahme **startet sofort**, ohne Rückfrage. Ein Banner „Aufnahme gestartet“ lässt Sie dann wählen, wann sie enden soll: in 15 Min., 30 Min., 1 Std., 2 Std. …, **zu einer bestimmten Uhrzeit** oder **ohne Limit**. Wählen Sie nichts, endet die Aufnahme am **Ende der Sendung** (TV-Programm, Puffer inklusive) oder, wenn der Guide sie nicht kennt, nach der **Standarddauer** unter **Einstellungen > Aufnahmen** (anfangs 2 Std.; „Kein Limit“ ist möglich). Sie können das Ende jederzeit mit der Schaltfläche **Dauer** in der Zeile „Aufnahme läuft“ ändern, die auch die Restzeit anzeigt.
<!--/mac-->

## Live aufnehmen {#enregistrer}

<!--mac-->
- Während ein Sender läuft, klicken Sie in den Steuerelementen auf **●**, unter dem Video auf **Aufnehmen** oder verwenden **⇧⌘R**. Das Zeichen **REC** zeigt die Dauer.
- Die Aufnahme endet automatisch am Ende der aktuellen Sendung (laut TV-Programm, plus der Nachlauf) oder wenn Sie auf **■** klicken.
- Sie nutzt **dieselbe Verbindung** wie die Wiedergabe: Es wird nichts weiter von Ihrem Abonnement verbraucht.
- Rechtsklick auf einen Sender > **Jetzt aufnehmen**: Sehen Sie gerade einen anderen Sender, fragt Kastideo, ob die Wiedergabe gestoppt werden soll, und nimmt dann im Hintergrund auf.
- Ein **Banner** am unteren Fensterrand bestätigt Beginn und Ende einer Aufnahme und zeigt **den Ordner**, in dem die Datei liegt (Schaltfläche **Anzeigen**). Ist der in den Einstellungen gewählte Ordner nicht mehr erreichbar, wird die Datei in ~/Movies/Kastideo abgelegt, und das Banner weist darauf hin. Die detaillierten Schritte stehen im **Wiedergabeprotokoll**.
- **Während der Aufnahme** ist die Datei im Unterordner **Läuft** des Aufnahmeordners sichtbar und wächst (ein nach der Sendung benannter Ordner). Nach dem Stopp wird sie in den Aufnahmeordner verschoben und der Unterordner entfernt. Legt die VLC-Engine die Datei nicht innerhalb von 10 Sekunden an, versucht Kastideo es automatisch in einem temporären Ordner erneut (die Datei erscheint dann erst nach dem Stopp); „Aufnahme nicht möglich“ erscheint erst nach beiden Versuchen, mit Details im Wiedergabeprotokoll (⌥⌘L). Die Länge wird nur durch den Speicherplatz begrenzt: Rechnen Sie je nach Sender mit etwa 1 bis 3 GB pro Stunde (unter 3 GB frei erscheint eine Warnung).
- Am Ende wird die Aufnahme **ohne Qualitätsverlust in MP4 umgewandelt** (abspielbar in QuickTime, auf iPhone und iPad). Zuerst erscheint die .ts-Datei, die nach der Umwandlung durch die .mp4 ersetzt wird (einige Minuten für 2 Stunden; angezeigt im Bereich Aufnahmen). Das Bild wird verlustfrei kopiert; der **Ton wird in AAC umgewandelt** (manche Sender senden MP2- oder AC-3-Ton, den QuickTime stumm abspielt). DVB-Untertitel und Teletext, die MP4 nicht aufnehmen kann, entfallen; schlägt die Umwandlung fehl, behält ein zweiter Versuch nur das Bild und den Haupttonkanal, und als letzter Ausweg bleibt die .ts erhalten. Das lässt sich in den Einstellungen abschalten.
<!--/mac-->

<!--pc-->
Roter runder Knopf in der Player-Leiste, Taste **R** oder Rechtsklick auf einen Sender > **Jetzt aufnehmen**: Der Sender wird bis zum Ende der aktuellen Sendung (plus Nachlauf) oder bis zu Ihrem Stopp aufgenommen, in **Videos/Kastideo/Enregistrements**.

- Die Stream-Bytes werden unverändert und verlustfrei in eine **.ts**-Datei kopiert: Der gerade angesehene Sender wird vom Relay kopiert (keine zweite Verbindung zum Anbieter); ein anderer Sender wird direkt heruntergeladen, mit erneutem Verbinden, falls der Stream abbricht.
- Am Ende wird die .ts verlustfrei in **MKV** umgewandelt (Standardformat, Einstellungen > Aufnahmen); schlägt die Umwandlung fehl, bleibt die .ts erhalten — sie lässt sich überall abspielen.
- HLS-Streams (.m3u8) und die Wiedergabe ohne Relay laufen weiterhin über die Video-Engine.
<!--/pc-->

## Eine Aufnahme planen {#programmer}

<!--mac-->
- Im TV-Programm unter dem Video **doppelklicken** Sie auf eine kommende Sendung oder wählen per Rechtsklick > **Aufnahme planen**. Ein roter Punkt markiert geplante Sendungen.
- Rechtsklick auf einen Sender > **Eine Aufnahme planen …** (oder das Kalendersymbol unter dem Video): Wählen Sie eine Sendung aus dem Guide oder eigene Zeiten.
- **Vor- und Nachlauf** (standardmäßig 2 und 5 Minuten, einstellbar) verhindern, dass Anfang oder Ende fehlen.
- Zur geplanten Zeit beginnt die Aufnahme im Hintergrund. Sehen Sie gerade einen anderen Sender, fragt Kastideo, ob die Wiedergabe gestoppt werden soll; ohne Antwort beginnt die Aufnahme nach 60 Sekunden.
<!--/mac-->

<!--pc-->
- **Rechtsklick auf einen Live-Sender > Aufnahme planen …**, oder die Schaltfläche **Planen …** im Bildschirm Aufnahmen (dann den Sender wählen: Favoriten, Zuletzt gesehen oder Suche).
  - **Guide-Sendungen**: die nächsten Sendungen des Senders, mit **Planen** (oder **Aufnehmen** für die aktuelle). Ein Häkchen zeigt bereits geplante an.
  - **Zeitfenster**: Tag, Start- und Endzeit, optionaler Titel — für einen Sender ohne TV-Programm oder eine bestimmte Sendung. Ein Ende vor dem Start endet am nächsten Tag.
  - **Wiederholung** (Liste oben rechts): **einmal**, **jeden Tag**, **Montag bis Freitag** oder **jede Woche**. Das nächste Vorkommen wird automatisch hinzugefügt; die Schaltfläche ⟲ einer wiederholten Aufnahme in der Liste beendet die Wiederholung.
- In den Details einer kommenden Sendung (TV-Programm, Themen): **Aufnahme planen**.
- Vor- und Nachlauf (Einstellungen > Aufnahmen) werden hinzugefügt. Kastideo muss zur geplanten Zeit geöffnet sein: Aktivieren Sie bei Bedarf **Kastideo bei der Anmeldung starten** (Einstellungen > Allgemein).
<!--/pc-->

## Einen Film oder Folgen herunterladen, ohne sie anzusehen {#telecharger}

<!--mac-->
- Rechtsklick auf einen Film oder eine Folge > **Herunterladen** oder **Heute Nacht herunterladen**, oder die Schaltfläche **Herunterladen** unter dem Video.
- Für eine Serie: die Schaltfläche **Herunterladen** auf ihrer Seite > die angezeigte Staffel oder die ganze Serie.
- Downloads laufen **nacheinander** (Warteschlange). „Heute Nacht“ beginnt standardmäßig um 2 Uhr (einstellbar).
- Sie können jeden Download im Bereich Aufnahmen pausieren, fortsetzen oder abbrechen.
- **Dauerhafte Anzeige**: Solange ein Download aktiv ist, bleibt in der Symbolleiste ein Fortschrittsring sichtbar. Ein Klick öffnet die Details: Fortschritt des aktuellen Films oder der aktuellen Folge, „Folge X von N“, Fortschritt der Serie oder des Stapels, Geschwindigkeit und **geschätzte Restzeit** (wird im Verlauf des Downloads genauer).
<!--/mac-->

<!--pc-->
Schaltfläche **Herunterladen** in den Details eines Films (jetzt oder **heute Nacht**), **Staffel herunterladen** oder das Symbol jeder Folge bei einer Serie, Rechtsklick > Herunterladen. Ein Download zur selben Zeit, nach einer Unterbrechung fortgesetzt, während der Wiedergabe pausiert (einstellbar). Die Dateien gehen nach **Videos/Kastideo/Films** und **Séries/<Serie>**.
<!--/pc-->

## Eine Verbindung: Wer hat Vorrang? {#priorite}

<!--mac-->
Ihr Abonnement erlaubt nur eine Verbindung. Kastideo tut daher immer nur eine Sache zur selben Zeit und **fragt Sie immer**, bevor es etwas unterbricht:

- Sie wechseln während einer Aufnahme den Sender: Kastideo fragt, ob die **Aufnahme gestoppt** werden soll.
- Sie starten die Wiedergabe während eines Downloads: Der Download wird **pausiert** und setzt sich von selbst fort, wenn die Wiedergabe endet.
- Bereits aufgenommene Dateien können jederzeit angesehen werden, auch während einer Hintergrundaufnahme.
<!--/mac-->

## Bildschirm „Aufnahmen“ {#ecran-enregistrements}

<!--pc-->
Laufende Aufnahme (stoppen), Downloads (pausieren, fortsetzen, abbrechen), geplante Aufnahmen und Verlauf, Dateien im Ordner: Ein Klick spielt sie ab, per Rechtsklick zeigen Sie sie im Ordner an oder löschen sie.
<!--/pc-->

## Details in Ihrer Sprache {#fiches-langue}

<!--pc-->
Mit einem **TMDB-Schlüssel** (Einstellungen > Allgemein) stammen Titel, Zusammenfassungen, Genres und Folgen von TMDB, in der Sprache der Oberfläche. Ist die einzige verfügbare Zusammenfassung die des Anbieters in einer anderen Sprache (Portugiesisch, Spanisch …), wird sie eingeklappt: **Zusammenfassung anzeigen (Portugiesisch)** zeigt sie trotzdem an. Sie erscheint nicht im Banner und nicht in der Folgenliste.
<!--/pc-->

## Gut zu wissen {#bon-a-savoir}

<!--mac-->
- Kastideo muss für geplante Aufnahmen und nächtliche Downloads **geöffnet bleiben** und der Mac **eingeschaltet**. Kastideo verhindert den automatischen Ruhezustand während der Aktivität und in der Stunde davor, nicht aber das manuelle Ausschalten oder den manuellen Ruhezustand.
- Eine **macOS-Mitteilung** meldet Beginn und Ende von Aufnahmen und Downloads (abschaltbar).
- **Automatisches Aufräumen** (optional): Aufnahmen, die älter als die gewählte Anzahl Tage sind, werden in den Papierkorb verschoben.
- Eine Warnung meldet sich, wenn der Speicherplatz knapp wird.
- Die Kopierrechte hängen von den Bedingungen Ihres Anbieters ab: Kastideo nimmt für Ihren privaten Gebrauch auf, was Ihr Abonnement Ihnen ohnehin bietet.
<!--/mac-->

## Die Aufnahmeliste aufräumen {#nettoyer-liste}

<!--mac-->
Im Bereich **Aufnahmen** können Sie **beendete Aufnahmen aus der Liste entfernen** (Pläne, Downloads und die laufende Aufnahme bleiben stets unberührt).

- **Eine Aufnahme**: die Papierkorb-Schaltfläche der Zeile, oder Rechtsklick > **Aus der Liste entfernen …**.
- **Mehrere**: die Schaltfläche **Auswählen**, die Zeilen ankreuzen (oder **Alle auswählen**) und dann **Auswahl entfernen**.
- **Alles**: die Schaltfläche **Liste leeren …**.

Danach öffnet sich ein Dialog. Standardmäßig wird **nur die Liste bereinigt**: Die Datei bleibt im Aufnahmeordner und erscheint nicht wieder in der Liste. Kreuzen Sie **Datei(en) auch aus dem Speicher löschen** an, um sie ebenfalls zu löschen (Papierkorb auf dem Mac); der freigewordene Platz wird dann angezeigt. **Diese Auswahl merken** behält Ihre Antwort für das nächste Mal.

Nach einem einfachen Entfernen aus der Liste bleibt etwa zehn Sekunden lang ein Banner **Rückgängig** sichtbar.

Existiert eine Datei im Speicher nicht mehr oder lässt sie sich nicht löschen, wird das Entfernen trotzdem fortgesetzt: Eine Mitteilung warnt Sie, und bei mehreren Warnungen listet ein Fenster sie auf.
<!--/mac-->

# Organisieren und anpassen

## Einen Sender korrigieren {#corriger}

<!--mac-->
Manche Sender sind beim Anbieter schlecht referenziert (falscher Name, falsche Sendungen, fehlendes Logo). Rechtsklick auf den Sender > **Sender bearbeiten …**:

- **Name** und **Nummer** (für das Zappen per Nummer in der TV-Oberfläche);
- **Logo**: eine Bildadresse oder **Datei auswählen …** (das Bild wird in Kastideo kopiert);
- **Sendungen des TV-Programms**: Sind die angezeigten Sendungen falsch oder fehlen sie, suchen Sie den richtigen Sender in der Liste (Anbieter-Guide und Ersatz-Guide); die aktuell laufende Sendung hilft beim Erkennen.

Die Korrektur gilt nur für **diese Version** des Senders (FHD, HD, SD … werden getrennt korrigiert) und übersteht Aktualisierungen der Quellen. **Original wiederherstellen** macht sie rückgängig.
<!--/mac-->

<!--pc-->
Rechtsklick auf einen Sender > **Sender bearbeiten …**: Name, Nummer, Logo (Bildadresse oder eine in Kastideo kopierte Datei) und **TV-Programm**-Sender (Suche unter den Anbieter- und Ersatz-Guides). Die Korrektur gilt für diese Version des Senders (HD, FHD …) und übersteht jede Aktualisierung. **Wiederherstellen** kehrt zum Original zurück.
<!--/pc-->

## Kategorien organisieren {#categories}

<!--mac-->
Sie müssen die Kategorieliste und -reihenfolge Ihres Anbieters nicht hinnehmen. Öffnen Sie **Darstellung > Kategorien verwalten …** (**⌥⌘C**), die Schaltfläche neben dem Titel „Kategorien“ in der Seitenleiste oder klicken Sie mit rechts auf eine Kategorie. Wählen Sie den Bereich (**Live**, **Filme** oder **Serien**) und dann:

- **Neu anordnen**: Ziehen Sie Kategorien in der Liste oder nutzen Sie das Menü **…** > **Ganz nach oben / ganz nach unten**. **A → Z sortieren** sortiert alles alphabetisch.
- **Alle aus-/abwählen**: Das Kästchen über der Liste markiert oder entmarkiert alle aufgeführten Kategorien auf einmal. Bei einer Suche (zum Beispiel „PT“) betrifft es nur die gefundenen Kategorien: praktisch, um ein ganzes Land auf einmal auszublenden und dann nur die gewünschten einzublenden.
- **Ausblenden**: Entfernen Sie das Häkchen bei einer Kategorie (oder Rechtsklick > **Diese Kategorie ausblenden** in der Seitenleiste). Eine ausgeblendete Kategorie verschwindet **überall**: Seitenleiste, Listen von Live / Filme / Serien, Suche, TV-Programm, Kino- und TV-Oberfläche, hervorgehobenes Banner. Ihre Favoriten und zuletzt Gesehenes bleiben verfügbar.
- **Nach Stichwort ausblenden**: Geben Sie zum Beispiel „PAKISTAN“ oder „ARABIC“ ein: Jede Kategorie, deren Name es enthält, wird ausgeblendet, auch solche, die der Anbieter später hinzufügt. Klicken Sie auf das Kreuz eines Stichworts, um es rückgängig zu machen.
- **Umbenennen**: Der Stift gibt einen besser lesbaren Namen („FRANCE FHD | OTT“ → „Frankreich HD“); **Originalname** macht es rückgängig.
- **Alle anzeigen** blendet ausgeblendete Kategorien wieder ein; **Zurücksetzen …** kehrt vollständig zur Anordnung des Anbieters zurück.

Neue Kategorien, die der Anbieter hinzufügt, erscheinen neben ihrem ursprünglichen Nachbarn.
<!--/mac-->

<!--pc-->
- **Rechtsklick auf eine Kategorie** in der Seitenleiste: **Umbenennen …**, **Ganz nach oben**, **Nach oben**, **Nach unten**, **Ganz nach unten**, **Diese Kategorie ausblenden**, **Kategorien verwalten …**.
- **Einstellungen > Kategorien** (oder das Symbol neben „Kategorien“): für Live-TV, Filme oder Serien — zum Neuanordnen ziehen, zum Ausblenden überall abwählen, zum Umbenennen doppelklicken, **Stichwörter**, um alle Kategorien, die sie enthalten, auf einmal auszublenden (z. B. „PAKISTAN“), **A bis Z sortieren**, **Zurücksetzen**.
- **Alle aus-/abwählen**: Das Kästchen über der Liste markiert oder entmarkiert alle aufgeführten Kategorien auf einmal. Bei der **Suche** (z. B. „PT“) betrifft es nur die gefundenen Kategorien: Blenden Sie ein ganzes Land in zwei Klicks aus und markieren Sie dann nur die gewünschten.

Eine ausgeblendete Kategorie ist überall ausgeblendet: Listen, Suche, Startseite, Reihen.
<!--/pc-->

## Die Details eines Films oder einer Serie korrigieren {#corriger-fiche}

Sind Poster, Titel oder Zusammenfassung eines Films oder einer Serie falsch (zum Beispiel weil sich zwei Filme denselben Titel teilen), können Sie ihn **mit dem richtigen TMDB-Eintrag verknüpfen** oder **die Details selbst eingeben**. Das funktioniert für **Meine Videos** (Ordner, Jellyfin, Emby, Plex) ebenso wie für Filme und Serien des **IPTV-Abonnements**, auf Mac, Windows, Linux und Android.

### Das Fenster öffnen

Rechtsklick (oder langes Drücken) auf den Film oder die Serie, dann **Details korrigieren …**; der Link steht auch am Ende der Detailseite.

### Mit einem TMDB-Code verknüpfen

1. Suchen Sie auf **themoviedb.org** den richtigen Film. Die **Nummer** steht in der Seitenadresse: `themoviedb.org/movie/12345-hero` → **12345** (bei einer Serie: `…/tv/1399-…`).
2. Geben Sie in Kastideo diese Nummer ein oder **fügen Sie die vollständige Adresse ein**, dann **Prüfen**.
3. Eine Vorschau (Poster, Titel, Jahr, Zusammenfassung) erscheint: Ist es der richtige, wählen Sie **Diesen Eintrag verwenden**.

Ein [TMDB-Schlüssel](help:tmdb) ist erforderlich. Gehört die Adresse zu einer Serie, während Sie einen Film korrigieren (oder umgekehrt), weist Kastideo Sie darauf hin.

### Nach Titel suchen

Unter dem Code bietet die Suche nach Titel und Jahr eine Liste von Einträgen: Tippen Sie auf den richtigen. Die TMDB-Nummer steht neben jedem Ergebnis.

### Von Hand anpassen

**Den Eintrag von Hand anpassen** erlaubt die Eingabe von **Titel**, **Jahr**, **Poster-Adresse** (https://…) und **Zusammenfassung**. Diese Felder ersetzen die des Anbieters und von TMDB; leer gelassene Felder ändern nichts. Sie lassen sich mit einem TMDB-Code kombinieren.

### Eine Korrektur entfernen

Im Fenster kehrt **Korrektur entfernen** zur automatischen Suche zurück. **Einstellungen > Allgemein > Film- und Seriendetails** listet außerdem jeden korrigierten Eintrag (**Von Hand korrigierte Einträge**) mit einer Schaltfläche **Entfernen** für jeden auf.

### Sicherung

Korrekturen sind Teil der **Konfigurationssicherung** (Einstellungen > Sicherung): Sie begleiten Ihre Exporte und Importe von einem Gerät zum anderen.

### Gut zu wissen

- Bei Filmen des IPTV-Abonnements gilt die Korrektur für die **Detailseite**; die Miniatur in der Liste behält das Bild des Anbieters.
- Bei Meine Videos wird auch das Poster in der Liste aktualisiert.

## Reihenfolge von Sendern und Kategorien festlegen {#arranger}

Im Modus **Anordnen** bringen Sie **die Sender, Filme oder Serien einer Kategorie** in die gewünschte Reihenfolge und ordnen auch **die Kategorien** selbst neu. Er ist auf **Windows, Linux und Android** verfügbar (noch nicht auf dem Mac). Er funktioniert mit dem Finger ebenso wie mit der Maus: Die Liste scrollt normal, und nur der **Griff ⋮⋮** links bewegt eine Zeile.

### Die Einträge einer Kategorie neu ordnen

1. Öffnen Sie eine Kategorie in der Seitenleiste (zum Beispiel „SPORT“).
2. Tippen Sie auf die Schaltfläche **Anordnen** (Pfeile ↑↓) rechts vom Listentitel.
3. **Halten Sie den Griff ⋮⋮** einer Zeile gedrückt und **ziehen Sie sie** an ihren neuen Platz. Zum Scrollen der Liste berühren Sie eine beliebige Stelle außer dem Griff.
4. Tippen Sie auf **Fertig**, wenn Ihnen die Reihenfolge gefällt. Sie wird automatisch gespeichert.

Die drei Punkte rechts in einer Zeile bieten:

- **Ganz nach oben** und **Ganz nach unten** (praktisch in einer langen Liste);
- **In eine andere Kategorie verschieben …**: Wählen Sie eine Kategorie oder geben Sie den Namen einer **neuen persönlichen Liste** ein (zum Beispiel „Meine Auswahl“), um Sender aus mehreren Kategorien zu sammeln;
- **In die ursprüngliche Kategorie zurücklegen**.

Oben im Modus Anordnen:

- **A → Z** sortiert nach Namen; **Nach Nummer** sortiert Sender nach Nummer;
- **Reihenfolge des Anbieters** hebt Ihre Reihenfolge für diese Kategorie auf.

Anordnen ist während einer Suche nicht verfügbar, ebenso wenig in Favoriten und Zuletzt gesehen (sie haben ihre eigene Reihenfolge).

### Die Kategorien neu ordnen

Öffnen Sie **Einstellungen > Kategorien** (oder die Schaltfläche rechts vom Titel „Kategorien“ in der Seitenleiste). Halten Sie den großen Griff ⋮⋮ links von einer Kategorie gedrückt und ziehen Sie sie. **Zurücksetzen** löscht auch die Senderreihenfolgen und Verschiebungen.

### Sicherung

Ihre Reihenfolge, persönlichen Listen und Verschiebungen sind Teil der **Konfigurationssicherung** (Einstellungen > Sicherung): Sie begleiten Ihre Exporte und Importe.

## Startseite für Live, Filme und Serien {#page-depart}

Standardmäßig zeigt das Öffnen von **Live**, **Filme** oder **Serien** alle Sender oder alle Inhalte, beginnend mit der ersten Kategorie des Anbieters. Sie können stattdessen wählen, was zuerst angezeigt wird.

### Die Startseite wählen

<!--mac-->
1. Öffnen Sie **Einstellungen (⌘,) > Allgemein > Startseite**.
<!--/mac-->
<!--pc-->
1. Öffnen Sie **Einstellungen (Strg+,) > Allgemein > Startseite**.
<!--/pc-->
2. Wählen Sie für **Live**, **Filme** und **Serien** getrennt:
   - **Alle**: die vollständige Liste (Standard);
   - **Favoriten** oder **Zuletzt gesehen**;
   - **Zuletzt angesehen**: die Kategorie, in der Sie zuletzt waren;
   - oder **eine bestimmte Kategorie** des Anbieters.

### In der Seitenleiste

Klicken Sie mit **Rechtsklick** auf eine Kategorie, dann **Als Startkategorie festlegen**. Dasselbe Menü erlaubt es, sie **nicht mehr** als Startkategorie zu verwenden.

### Wann gilt das?

Jedes Mal, wenn Sie Live, Filme oder Serien aus einem anderen Bereich öffnen (Startseite, TV-Programm …), auch beim Start. Im Bereich selbst stöbern Sie frei: Klicken Sie in der Seitenleiste auf **Live**, **Filme** oder **Serien**, während Sie bereits dort sind, wird die vollständige Liste angezeigt.

Ist die gewählte Kategorie ausgeblendet, umbenannt oder beim Anbieter nicht mehr vorhanden, zeigt Kastideo die vollständige Liste. Wählen Sie sie in den Einstellungen erneut.

## Mehrere Konten: aktive Quelle, Duplikate und Diagnose {#sources-multiples}

Haben Sie **zwei oder mehr IPTV-Konten**, lässt Kastideo Sie das angezeigte wählen, **ohne die anderen** in den Einstellungen zu deaktivieren.

### Die aktive Quelle wählen

- Auf dem **Mac** erscheint ein Menü **Quelle** in der Seitenleiste. Auf **Windows, Linux und Android** befindet sich das Menü **Quelle** in der Seitenleiste (auf einem Smartphone: im Menüfach).
- Wählen Sie **Alle Quellen** oder ein bestimmtes Konto. Neben jedem Namen stehen drei Zahlen: **Sender · Filme · Serien**, vom Anbieter geliefert.
- Die Auswahl filtert **Live, Filme, Serien, die Suche und den TV-Programm** und wird **zwischen Starts gemerkt**.
- Ordner und Server von [Meine Videos](help:mes-videos) bleiben immer sichtbar.

### Duplikate zusammenführen

Bei **Alle Quellen** wird ein Film oder eine Serie, den mehrere Konten liefern (gleicher Titel, gleiches Jahr), nur **einmal** aufgeführt. Deaktivieren Sie **Duplikate zusammenführen**, um alles zu sehen. Bereits gespeicherte Favoriten und zuletzt Gesehenes funktionieren weiter.

### Warum haben zwei Konten derselben Stufe unterschiedliche Filme?

Die **Sender** sind oft identisch, aber die **Film- und Serienkataloge** hängen vom Konto ab: Viele Anbieter geben jedem Konto unterschiedliche Video-on-Demand-Pakete. Weichen die Zahlen ab, liegt es meistens **auf Seiten des Anbieters**.

### Die Schaltfläche Diagnose

In **Einstellungen > Quellen** zeigt die Schaltfläche **Diagnose** (Stethoskop) eines Kontos:

- den Kontostatus (Status, Ablauf, Verbindungen);
- für Sender, Filme und Serien: die Anzahl, die **vom Anbieter geliefert** wird, die Anzahl der Kategorien und die Anzahl, die **tatsächlich angezeigt** wird;
- was Kastideo **ausblendet**: ausgeblendete Kategorien, Inhalte für Erwachsene, zusammengeführte Duplikate.

Weicht „vom Anbieter geliefert“ zwischen Ihren beiden Konten ab, kommt der Unterschied vom Anbieter. Mit der Schaltfläche **Kopieren** können Sie das Ergebnis an eine Nachricht an Ihren Anbieter anhängen.

## Favoriten und Zuletzt gesehen {#favoris}

<!--mac-->
- Fügen Sie einen Favoriten über den Stern im Infopanel, per Rechtsklick oder mit **⌘D** hinzu.
- Der Bereich **Zuletzt gesehen** behält die letzten 60 Elemente, die Sie angesehen haben.
- **Aus Zuletzt gesehen entfernen**: Rechtsklick auf ein Element > **Aus „Zuletzt gesehen“ entfernen** (oder die Taste **⌫** beim ausgewählten Element in der Klassischen Oberfläche). Für mehrere Elemente klicken Sie auf **Bearbeiten**, kreuzen die Elemente an und wählen **Löschen**; **Alle auswählen** markiert die ganze Liste, und **Alles leeren** leert den Verlauf.
- Nach einem Löschen bleibt einige Sekunden lang ein Banner **Rückgängig** sichtbar, um alles wiederherzustellen.
- „Zuletzt gesehen“ lässt sich auch in den Einstellungen leeren, Reiter **Allgemein**.
<!--/mac-->

<!--pc-->
Stern in der Player-Leiste, Taste **F** oder Rechtsklick > Zu Favoriten hinzufügen. „Zuletzt gesehen“ behält die letzten 60 geöffneten Elemente.

- **Bearbeiten** (neben dem Titel „Zuletzt gesehen“): Elemente ankreuzen, dann **Auswahl entfernen**, oder das Kreuz einer Zeile, um sie allein zu entfernen; **Alle auswählen** und **Alles leeren** (für den angezeigten Bereich). **Fertig** kehrt zur Liste zurück.
- Rechtsklick auf ein Element > **Aus „Zuletzt gesehen“ entfernen**.
- Einstellungen > Allgemein > **Zuletzt gesehen leeren** löscht alle, in jedem Bereich.
<!--/pc-->

## Erinnerungen und Mitteilungen {#alertes}

<!--pc-->
- **Erinnere mich beim Start** in den Details einer kommenden Sendung (Glocke im Guide).
- **Stichwörter** (Einstellungen > Aufnahmen): Eine Sendung, deren Titel ein Stichwort enthält, löst eine Erinnerung aus, auf Ihren Lieblingssendern oder auf allen.
- Die Erinnerung erscheint oben rechts in Kastideo mit **Ansehen**, und das Fenster kommt zurück, wenn es minimiert war.
- **Systemmitteilungen** (Einstellungen > Allgemein > Mitteilungen, standardmäßig an): Erinnerungen, Beginn und Ende von Aufnahmen sowie abgeschlossene oder fehlgeschlagene Downloads erscheinen auch im Mitteilungscenter von Windows oder Linux, selbst wenn Kastideo hinter einem anderen Fenster liegt. Ein Klick auf die Mitteilung holt Kastideo zurück.
<!--/pc-->

## Darstellung {#apparence}

<!--pc-->
Einstellungen > **Darstellung**:

- **Design**: **Dunkel** (Standard), **Hell** oder **Wie das System** (folgt Windows oder Linux). Player, TV-Oberfläche, MultiView, Startbildschirm, Detailseiten und das hervorgehobene Banner bleiben dunkel, wie auf dem Mac.
- **Akzentfarbe**: Standard (Kastideo-Blau), Blau, Violett, Rosa, Rot, Orange, Grün oder Petrol — für Auswahlen, Schaltflächen, Schalter.
- **Listendichte** (Klassische Oberfläche): kompakt, standard oder großzügig.
- **Miniaturgröße** (Kino-Oberfläche): klein, mittel oder groß.
- **Oberfläche** je Inhaltstyp und **hervorgehobenes Banner** (siehe [Drei Oberflächen](help:interfaces)).

Änderungen gelten sofort, ohne Neustart.
<!--/pc-->

# YouTube

## YouTube: stöbern und abspielen {#youtube}

Der Bereich **YouTube** (Seitenleiste, Schaltfläche auf der Startseite,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Strg+9**<!--/pc-->) funktioniert in zwei Schritten: zuerst ein **Browser**, dann der **Player**, sobald Sie ein Video wählen.

![Vom Browser zum Player](img:youtube)

### Der Browser

- **Meine Kanäle**: Fügen Sie im Feld oben einen Kanallink oder seinen @Handle ein, um ihm zu folgen. Seine neuesten Videos erscheinen in einer Reihe, ohne Schlüssel und ohne Konto. Um alle Ihre Abos auf einmal zu übernehmen: [Meine Abos importieren](help:youtube-import).
- **Suche**: Geben Sie Ihre Suche im selben Feld ein (Ergebnisse mit Miniaturen, sortiert nach Relevanz, Datum oder Aufrufen, weitere Seiten). Dafür ist ein **kostenloser Google-API-Schlüssel** nötig: [die Schritt-für-Schritt-Anleitung](help:youtube-cle).
- **Eingefügte Links**: Ein Video wird abgespielt, eine Playlist wird zur Wiedergabeliste, einem Kanal wird gefolgt.
- **Favoriten und Verlauf**: Rechtsklick auf eine Miniatur; der Verlauf behält die letzten 80 Videos (mit einer Schaltfläche zum Leeren).
- **Später ansehen**: Rechtsklick auf eine Miniatur, um ein Video beiseitezulegen. Ein begonnenes Video **setzt dort fort, wo Sie aufgehört haben** (ein roter Balken zeigt den Fortschritt); es verschwindet aus der Liste, sobald es zu Ende gesehen wurde.

### Der Player

<!--mac-->
Ein Klick auf ein Video ersetzt den Browser durch den Player; die Liste, aus der Sie kommen, wird zur Wiedergabeliste. Die Schaltflächen Zurück / Weiter, **Nächstes automatisch abspielen**, **Wiederholen**, **Stumm** und **Auf YouTube öffnen** liegen in einer Leiste, die sich selbst ausblendet; **Esc** oder **YouTube-Browser** bringt Sie zur Liste zurück.
<!--/mac-->
<!--pc-->
Ein Klick auf ein Video öffnet den Player in **einem eigenen Fenster** (Edge oder Chrome unter Windows, Chrome oder Chromium unter Linux im „App“-Modus; sonst Ihr Standardbrowser); die Liste, aus der Sie kommen, wird zur Wiedergabeliste. Die Schaltflächen Zurück / Weiter, **Nächstes automatisch abspielen**, **Wiederholen**, **Stumm** und **Auf YouTube öffnen** liegen in einer Leiste, die sich selbst ausblendet. Ein Banner in Kastideo erinnert Sie an das aktuelle Video, mit **Fenster erneut öffnen**.
<!--/pc-->

Die IPTV-Wiedergabe stoppt, solange YouTube läuft (außer wenn eine Aufnahme läuft).

> Zu Werbung und Ihrem Google-Konto: siehe [Werbung, Konto und Datenschutz](help:youtube-confidentialite).

## Meine YouTube-Abos importieren {#youtube-import}

YouTube erlaubt einer App wie Kastideo nicht, sich in Ihrem Konto anzumelden. Google erlaubt aber den **Export Ihrer Daten**: Sie fordern nur Ihre Abo-Liste an, eine kleine Datei `subscriptions.csv`, die Kastideo **auf Ihrem Computer** liest.

![Die Importschritte](img:takeout)

### Schritt 1: Den Export bei Google anfordern

1. Öffnen Sie [Google Takeout](https://takeout.google.com/), angemeldet im **Google-Konto**, dessen Abos Sie möchten.
2. Klicken Sie auf **Alle Auswahlen aufheben** (oben in der Liste).
3. Scrollen Sie zu **YouTube und YouTube Music** und setzen Sie das Häkchen.
4. Klicken Sie auf **Alle YouTube-Daten enthalten**, klicken Sie auf **Alle Auswahlen aufheben**, wählen Sie nur **Abos** aus und dann **OK**.
5. Klicken Sie ganz unten auf **Nächster Schritt**. Behalten Sie **Downloadlink per E-Mail senden**, **Einmal exportieren** und das Format **.zip** bei und klicken Sie auf **Export erstellen**.
6. Google bereitet das Archiv vor (einige Minuten, manchmal länger) und schickt Ihnen eine E-Mail. Klicken Sie in der E-Mail auf **Dateien herunterladen** und speichern Sie die `.zip`.

### Schritt 2: Die Datei finden

1. Öffnen Sie die `.zip`: <!--mac-->Doppelklick im Finder<!--/mac--><!--pc-->Rechtsklick > **Alle extrahieren** (Windows) oder Doppelklick (Linux)<!--/pc-->.
2. Öffnen Sie **Takeout** > **YouTube und YouTube Music** > **Abos**.
3. Die Datei heißt **subscriptions.csv** (oder trägt einen Namen in der Sprache Ihres Kontos, zum Beispiel **abonnements.csv**, wenn Ihr Konto auf Französisch ist).

### Schritt 3: In Kastideo importieren

1. Öffnen Sie **YouTube** > **Meine Kanäle**.
2. Klicken Sie auf **Meine Abos importieren …** und wählen Sie die Datei.
3. Kastideo fügt die Kanäle hinzu und lädt ihre neuesten Videos (bei vielen Abos kann die erste Aktualisierung eine Minute dauern).

> Kanäle, denen Sie schon folgen, werden nicht doppelt hinzugefügt. Die Datei wird nur von Kastideo auf Ihrem Rechner gelesen: Es wird nichts an Google oder anderswohin gesendet, und Kastideo greift nie auf Ihr Konto zu.

### Wenn es nicht funktioniert

- **„In dieser Datei wurde kein neuer Kanal gefunden“**: Es ist nicht die richtige Datei (zum Beispiel der Wiedergabeverlauf), oder den Kanälen wird schon gefolgt. Gehen Sie zurück zu Schritt 2.
- **Keine E-Mail von Google**: Prüfen Sie Ihren Spam-Ordner oder gehen Sie zurück zu [Google Takeout](https://takeout.google.com/): Im Bereich „Exporte verwalten“ können Sie das Archiv erneut herunterladen.
- **Kein Ordner „Abos“**: Prüfen Sie in Schritt 1.4, dass das Kästchen **Abos** angekreuzt war.
- Ohne Datei können Sie einem Kanal nach dem anderen folgen, indem Sie seinen Link oder @Handle einfügen: siehe [YouTube](help:youtube).

## Einen Google-API-Schlüssel besorgen (Suche) {#youtube-cle}

Die **Suche** auf YouTube nutzt die offizielle Schnittstelle von Google („YouTube Data API v3“) mit **Ihrem eigenen Schlüssel**. Sie ist **kostenlos** und reicht für etwa **100 Suchen pro Tag**. Ohne Schlüssel funktioniert alles andere: Kanälen folgen, eingefügte Links abspielen, Favoriten, Verlauf.

### Den Schlüssel erstellen (5 Minuten, einmalig)

1. Öffnen Sie die [Google Cloud Console](https://console.cloud.google.com/) und melden Sie sich mit einem Google-Konto an.
2. Klicken Sie oben auf die Projektauswahl > **Neues Projekt**. Geben Sie ihm einen Namen (zum Beispiel „Kastideo“), klicken Sie auf **Erstellen** und wählen Sie es aus.
3. Öffnen Sie [die Seite der YouTube Data API v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com) und klicken Sie auf **Aktivieren**.
4. Menü **APIs und Dienste > Anmeldedaten** > **Anmeldedaten erstellen** > **API-Schlüssel**.
5. Kopieren Sie den angezeigten Schlüssel (etwa vierzig Zeichen, beginnend mit „AIza“).
6. Optional, aber empfohlen: **Schlüssel bearbeiten** > **API-Einschränkungen** > **Schlüssel einschränken** > **YouTube Data API v3** ankreuzen.

### Den Schlüssel an Kastideo geben

1. Öffnen Sie **Einstellungen > Allgemein > YouTube**.
2. Fügen Sie den Schlüssel in **Google-API-Schlüssel** ein und bestätigen Sie.
3. Gehen Sie zurück zu **YouTube**: Die Suche funktioniert jetzt.

<!--mac-->
Der Schlüssel wird im **macOS-Schlüsselbund** gespeichert, nie im Klartext auf der Festplatte, und nie veröffentlicht.
<!--/mac-->
<!--pc-->
Der Schlüssel wird im **Systemtresor** gespeichert und nie veröffentlicht.
<!--/pc-->

> Kontingent: Jede Suche verbraucht 100 der 10.000 kostenlosen Tageseinheiten. Erreichen Sie das Limit, zeigt Kastideo „YouTube-API-Fehler“; die Suche funktioniert am nächsten Tag wieder. Kanälen folgen und Videos abspielen verbraucht dieses Kontingent nicht.

### Wenn etwas schiefgeht

- **„API-Schlüssel fehlt“**: In den Einstellungen ist nichts gespeichert.
- **„API-Schlüssel ungültig“ / „YouTube-API-Fehler“**: Der Schlüssel wurde falsch kopiert, oder Schritt 3 (die API aktivieren) wurde für **dieses** Projekt nicht durchgeführt.
- **Einschränkungsfehler**: Haben Sie den Schlüssel eingeschränkt, prüfen Sie, dass **YouTube Data API v3** angekreuzt ist.

## Werbung, Konto und Datenschutz {#youtube-confidentialite}

### Werbung

Kastideo verwendet den **offiziellen YouTube-Player im „erweiterten Datenschutzmodus“** (youtube-nocookie.com), den Google Websites zum Einbetten von Videos zur Verfügung stellt: Er setzt keinen Tracking-Cookie und zeigt daher keine personalisierte Werbung, meist gar keine.

**Das ist kein Werbeblocker**: Nichts wird abgefangen oder umgangen, und YouTube kann weiterhin Werbung zeigen, die Kreative finanziert.
<!--pc-->
Hat Ihr Browser einen eigenen Werbeblocker, gilt er im Player-Fenster.
<!--/pc-->

### Warum kann ich mich nicht in mein Konto einloggen?

Der Player mit erweitertem Datenschutz erkennt Ihr Konto nicht: keine personalisierten Empfehlungen, keine automatisch synchronisierten Abos, kein YouTube Premium (das Werbung auf youtube.com entfernt, nicht in einem eingebetteten Player). Das ist der Preis für eine Wiedergabe ohne Tracking. Um Ihre Abos zurückzubekommen, nutzen Sie den [Import Schritt für Schritt](help:youtube-import).

### Was Kastideo speichert

Ihre abonnierten Kanäle, Favoriten, der Verlauf (80 Videos), die Liste „Später ansehen“ und die Fortsetzungspunkte werden **nur auf Ihrem Computer** gespeichert. Ein API-Schlüssel bleibt im Systemtresor. Es wird nichts an Kastideo oder an jemand anderen als YouTube / Google gesendet, wenn Sie suchen oder ein Video abspielen.

# Einstellungen und Wartung

## Tastenkürzel {#raccourcis}

<!--mac-->
- **⌘0**: Startseite
- **⌘1 bis ⌘7**: Live, Filme, Serien, Favoriten, Zuletzt gesehen, Aufnahmen, TV-Programm
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3**: Klassische / Kino- / TV-Oberfläche (für den angezeigten Inhaltstyp)
- TV-Oberfläche: **↑ ↓** Zappen, **←** Senderpanel, Ziffern = Sendernummer, **I** Banner, **B** vorheriger Sender, **G** TV-Programm, **H** Startseite, **F** Favorit, **M** stumm
- **⌘↑ / ⌘↓**: vorheriges / nächstes Element (Zappen)
- **⌘K**: Wiedergabe / Pause
- **⌘[ / ⌘]**: 10 s zurück / 30 s vor (Filme und Folgen)
- **⌘↩** oder Doppelklick auf das Video: Kinomodus (Esc zum Verlassen)
- **⌘.**: Wiedergabe stoppen
- **⇧⌘R**: den gesehenen Sender aufnehmen / Aufnahme stoppen
- **⌥⌘L**: Protokoll
- **⌘D**: zu Favoriten hinzufügen oder entfernen
- **⌘R**: alle Quellen aktualisieren
- **⌘,**: Einstellungen und Quellen
- **⌘?**: diese Hilfe (öffnet sich auf der Seite zum aktuellen Bildschirm)
- **⌘8**: Meine Videos, **⌘9**: YouTube
<!--/mac-->

<!--pc-->
- **Strg+0**: Startseite — **Strg+1**: Live — **Strg+2**: Filme — **Strg+3**: Serien — **Strg+7**: TV-Programm — **Strg+Alt+M**: MultiView — **Strg+,**: Einstellungen
- **Leertaste**: Wiedergabe / Pause — **M**: Ton — **F**: Favorit — **R**: aufnehmen / stoppen — **← / →**: −10 s / +30 s — **Strg+.**: Wiedergabe stoppen
- **Strg+Enter** oder Doppelklick auf das Bild: Kinomodus — **F11**: Vollbild — **Esc**: Kinomodus verlassen, zurück zu Details oder Reihen
- TV-Oberfläche: **↑ / ↓** Zappen, **Ziffern** Sendernummer, **←** Panel, **→ / I** Banner, **B** vorheriger Sender, **G** Guide, **H** Startseite
- MultiView: **1 bis 4** Ton, **G** vergrößern, **A** hinzufügen, **Entf** entfernen, **F** Vollbild, **Esc** verlassen
- **Strg+Alt+L**: Protokoll
- **Strg+8**: Meine Videos, **Strg+9**: YouTube
- **F1**: diese Hilfe (öffnet sich auf der Seite zum aktuellen Bildschirm)
<!--/pc-->

## Allgemeine Einstellungen {#reglages}

<!--mac-->
- **Sprache** (Reiter **Allgemein**): Kastideo ist auf **Französisch, Englisch, Spanisch, Deutsch, Italienisch und Portugiesisch** verfügbar. Die Sprache wird beim ersten Start gewählt und lässt sich danach unter **Einstellungen > Allgemein > Sprache** ändern (oder „System“, um der Sprache des Macs zu folgen). Die Änderung gilt nach einem Neustart der App, den Kastideo Ihnen anbietet. Hilfe und Menüs folgen der gewählten Sprache; die Versionshinweise bleiben auf Französisch.
- **Darstellung** (Reiter **Darstellung**): dunkles Design (Standard), helles oder wie das System; **Akzentfarbe** (System, Blau, Violett, Rosa, Rot, Orange, Grün, Petrol); **Oberfläche** Klassisch oder Kino für jeden Inhaltstyp; **Listendichte** (kompakt, standard, großzügig) für die Klassische Oberfläche; **Miniaturgröße** (klein, mittel, groß) für die Kino-Oberfläche.
- **Film- und Seriendetails** (Reiter **Allgemein**): optionaler **TMDB**-API-Schlüssel (kostenlos auf themoviedb.org > Einstellungen > API; v3-Schlüssel oder v4-Lesetoken), im Schlüsselbund gespeichert. **Speichern und prüfen** verifiziert ihn. Ohne Schlüssel stammen die Details von Ihrem IPTV-Anbieter.
- **Beim Start aktualisieren**: lädt Quellen neu, deren letzte Aktualisierung mehr als 6 Stunden zurückliegt.
- **Cache**: Kastideo behält eine lokale Kopie der Listen und des TV-Programms, um sofort zu starten. **Leeren und neu laden** löscht diese Kopie und startet das Laden neu.
<!--/mac-->

<!--pc-->
- **Allgemein**: Sprache (beim nächsten Start), Wiedergabe fortsetzen, Stream-Relay, Aktualisierung beim Start, „Zuletzt gesehen“ leeren, **gleichzeitige Verbindungen** (MultiView), **Systemmitteilungen**, TV-Programm und Ersatz-Guide, Inhalte für Erwachsene (standardmäßig ausgeblendet), TMDB-Schlüssel, **Start und .m3u-Dateien**, **Updates**.
- **Darstellung**: Design, Akzentfarbe, Listendichte, Miniaturgröße, Oberflächen, hervorgehobenes Banner.
- **Quellen**: hinzufügen, aktualisieren, löschen, Guide-Status.
- **Kategorien**: Reihenfolge, Ausblenden, Namen, Stichwörter.
- **Aufnahmen**: Ordner, Format, Vor- und Nachlauf, Downloads, Zeitversatz, Erinnerungen.
- **Sicherung**: Konfiguration exportieren oder importieren.
<!--/pc-->

## Einen TMDB-Schlüssel besorgen (kostenlos) {#tmdb}

<!--mac-->
TMDB (The Movie Database) ist eine von der Community gepflegte Film- und Fernsehdatenbank. Ihr Schlüssel ist für den privaten Gebrauch **kostenlos**; er erlaubt Kastideo, Fotos der Besetzung, HD-Poster und Hintergrundbilder, den Trailer und eine übersetzte Zusammenfassung anzuzeigen.

1. Erstellen Sie ein Konto auf **themoviedb.org** („Join TMDB“) und bestätigen Sie es mit dem per E-Mail gesendeten Link.
2. Öffnen Sie angemeldet **themoviedb.org/settings/api** (Avatar > Einstellungen > API) oder klicken Sie in den Einstellungen von Kastideo auf **Kostenlosen Schlüssel erhalten**.
3. Klicken Sie auf **Create**, wählen Sie **Developer** und akzeptieren Sie die Nutzungsbedingungen.
4. Füllen Sie das Formular aus: Nutzungsart **Personal**, Anwendungsname **Kastideo**, URL **https://github.com/jihemezes/kastideo**, eine kurze Zusammenfassung („Persönlicher IPTV-Player, zeigt Filmdetails an“), dann Ihre Kontaktdaten.
5. Senden Sie ab: Die Seite zeigt einen **API Key** (32 Zeichen) und einen **API Read Access Token** (lang, beginnt mit „eyJ“). Kastideo akzeptiert beide; der API-Schlüssel lässt sich leichter kopieren.
6. In Kastideo: **Einstellungen (⌘,) > Allgemein > Film- und Seriendetails**, fügen Sie den Schlüssel ein und klicken Sie auf **Speichern und prüfen**. „Gültiger Schlüssel ✓“ bestätigt es.
7. Öffnen Sie eine Detailseite erneut (oder klicken Sie unten auf **Aktualisieren**): Sie wird jetzt von TMDB ergänzt.

Der Schlüssel wird im Schlüsselbund des Macs gespeichert. **Schlüssel entfernen** kehrt zu den Informationen des IPTV-Anbieters allein zurück.
<!--/mac-->

<!--pc-->
Erstellen Sie ein Konto auf themoviedb.org, dann **Einstellungen > API** und fordern Sie einen Schlüssel an (private Nutzung). Fügen Sie den „API-Schlüssel“ (v3) oder das „Lesezugriffs-Token“ (v4) unter Einstellungen > Allgemein ein, dann **Speichern**. Die Details werden reichhaltiger (Poster, Besetzung, Trailer, Zusammenfassungen und Folgen in Ihrer Sprache).
<!--/pc-->

## Poster und Zusammenfassungen für Ihre eigenen Videos {#tmdb-perso}

Für die Filme und Serien in Ihren **Ordnern** kann Kastideo Poster und Zusammenfassung bei **TMDB** nachschlagen (ein [TMDB-Schlüssel](help:tmdb) ist erforderlich).

Da ein Dateiname weder Jahr noch Kennzeichnung enthält, ist die Suche **vorsichtig**: Eine Übereinstimmung wird nur akzeptiert, wenn ihr **Titel (oder Originaltitel) genau dem Dateinamen entspricht**. Mit inneren Großbuchstaben zusammengeschriebene Namen (**TearsOfSteel**) werden getrennt (Tears Of Steel). Namen komplett in zusammengeschriebenen Kleinbuchstaben („bigbuckbunny“) werden nicht erkannt.

- Einstellung: in den **Einstellungen**, Abschnitt **Film- und Seriendetails**: **Auch eigene Videos nachschlagen**. Standardmäßig an; schalten Sie sie aus, um jede Suche zu vermeiden.
- Fehlt eine Übereinstimmung oder ist sie falsch (zum Beispiel teilen sich zwei Filme denselben Titel), nutzen Sie [Details korrigieren](help:corriger-fiche): Sie können den Film mit dem richtigen **TMDB-Code** verknüpfen.

## Start und .m3u-Dateien {#demarrage}

<!--pc-->
Einstellungen > Allgemein > **Start und Dateien**:

- **Kastideo bei der Anmeldung starten** (Windows und Linux) und **Minimiert starten** in der Taskleiste: Geplante Aufnahmen und Erinnerungen finden nur statt, solange Kastideo geöffnet ist.
- **.m3u- und .m3u8-Dateien mit Kastideo öffnen** (optional): Ein Doppelklick auf eine Playlist bietet an, sie als Quelle hinzuzufügen (Einstellungen > Quellen); ist Kastideo bereits geöffnet, erhält das vorhandene Fenster sie. Öffnet Windows weiterhin ein anderes Programm, klicken Sie mit rechts auf die Datei > Öffnen mit > Andere App auswählen > Kastideo. Unter Linux wird die Zuordnung in Ihrem Profil gespeichert (Datei `~/.config/mimeapps.list`); erscheint unter dem Schalter eine Fehlermeldung, nennt sie die Ursache.

Beide Optionen bietet auch das Windows-Installationsprogramm an (standardmäßig nicht angekreuzt).
<!--/pc-->

## Sicherung und Übertragung {#sauvegarde}

<!--mac-->
Einstellungen > Allgemein > **Sicherung und Übertragung**:

- **Konfiguration exportieren …** speichert eine Datei `Kastideo-configuration.json`: Quellen (Xtream und M3U-Playlists per Adresse), Favoriten, Zuletzt gesehen, eigene Kategorien (Reihenfolge, ausgeblendet, Namen, Stichwörter), gewählte Oberflächen und TMDB-Schlüssel. Kreuzen Sie **Passwörter einschließen** an, damit nichts erneut eingegeben werden muss; bewahren Sie die Datei sicher auf.
- **Konfiguration importieren …** fügt den Inhalt einer Datei hinzu: auf einem neuen Mac oder aus Kastideo für Windows und Linux (gleiches Format). Bereits vorhandene Quellen werden erkannt, und nichts wird gelöscht.

Jellyfin-, Emby- und Plex-Server werden exportiert (mit ihrem Passwort oder Token, wenn Sie **Passwörter einschließen** ankreuzen). Als lokale Dateien hinzugefügte M3U-Playlists und Ordner werden auf einem anderen Mac nicht importiert (die Dateien existieren dort nicht oder müssen neu gewählt werden).
<!--/mac-->

<!--pc-->
Einstellungen > **Sicherung**: **Konfiguration exportieren …** (Quellen und ihr Guide, Passwörter nach Wunsch, Favoriten, Zuletzt gesehen, Kategorien, Oberflächen, Darstellung, Anzahl der Verbindungen, Inhalte für Erwachsene, Banner, TMDB-Schlüssel) und **Konfiguration importieren …**. Die Datei ist dieselbe wie bei Kastideo für Mac: Sie können in beide Richtungen von einem Computer zum anderen wechseln. Beim Import wird nichts gelöscht. Jellyfin-, Emby- und Plex-Server sind enthalten (auch Passwort oder Token, falls gewünscht); Ordner ebenfalls, mit ihren Pfaden (anzupassen, falls sie auf diesem Computer abweichen).
<!--/pc-->

## Updates {#mises-a-jour}

<!--mac-->
Kastideo aktualisiert sich selbst dank **Sparkle**, dem Standardwerkzeug für Mac-Apps, die außerhalb des App Stores vertrieben werden.

- **Beim Start** (einige Sekunden nach dem Öffnen), danach einmal täglich, wenn Kastideo geöffnet bleibt, prüft Kastideo unauffällig, ob auf GitHub eine neue Version verfügbar ist.
- Ist das der Fall, kündigt ein **Banner** oben im Fenster sie an — **nie beim Ansehen oder Aufnehmen** (es wartet, bis die Wiedergabe endet). Das Update ist **optional**: **Aktualisieren …** öffnet das Fenster mit den Versionshinweisen, dann **Update installieren** (Kastideo beendet sich, installiert und startet neu); **Später** blendet das Banner bis zum nächsten Start aus; **Diese Version überspringen** bietet sie nicht mehr an (die nächste wird angeboten).
- Sie können jederzeit mit **Kastideo > Nach Updates suchen …** prüfen.
- Jedes Update ist signiert: Kastideo weigert sich, eine Datei zu installieren, die nicht von seinem Herausgeber stammt.

Unter **Einstellungen > Updates**:

- **Beim Start nach Updates suchen**: schaltet die Prüfung beim Start und die tägliche Prüfung ein oder aus.
- **Testversionen erhalten (Beta)**: bietet auch Beta-Versionen an, die neue Funktionen früher bringen, aber weniger stabil sein können. Schalten Sie die Option aus, um beim nächsten Update zu den stabilen Versionen zurückzukehren.

> Versionen 0.1.0 und früher können sich nicht selbst aktualisieren: Installieren Sie 0.2.0 einmal von Hand, und die folgenden kommen von allein.
<!--/mac-->

<!--pc-->
Kastideo sucht beim Start und danach alle 12 Stunden auf GitHub nach neuen Versionen (Vorabversionen für Windows / Linux, solange diese Versionen in der Vorschau sind).

- Eine neue Version wird durch ein **Banner unten rechts** angekündigt, nur wenn Sie gerade nichts ansehen. **Ansehen** öffnet das Update-Fenster mit den Versionshinweisen; das Kreuz verschiebt es.
- **Installieren und neu starten** lädt die zu Ihrer Installation passende Datei herunter und dann:
  - **Windows, installiert**: führt das neue Installationsprogramm still aus und startet dann Kastideo neu;
  - **Windows, portabel**: ersetzt nach dem Schließen die Dateien des Ordners und startet dann Kastideo neu;
  - **AppImage**: speichert das neue AppImage neben dem alten, löscht das alte und startet es;
  - **.deb-Paket**: installiert es mit apt (Ihr Passwort wird abgefragt) und startet dann Kastideo neu.
- Eine laufende Aufnahme wird vor dem Schließen sauber beendet.
- **Diese Version überspringen**: Sie wird nicht erneut angeboten (eine manuelle Prüfung bietet sie wieder an).
- Einstellungen > Allgemein > **Updates**: installierte Version und Installationsart, **Jetzt prüfen**, automatische Prüfungen, **Neuigkeiten der letzten Versionen**, Release-Seite auf GitHub.
- Beim ersten Start nach einem Update fasst das Fenster **Neuigkeiten** die Änderungen zusammen.
<!--/pc-->

## Installation {#installation}

<!--pc-->
- **Windows (empfohlen)**: Führen Sie **Kastideo-…-windows-x64-setup.exe** aus. Standardmäßig installiert sich Kastideo nur für Sie, ohne Administratorrechte (in Ihrem AppData-Ordner); das Installationsprogramm bietet außerdem an, für alle Benutzer zu installieren, ein Desktop-Symbol anzulegen, .m3u-Dateien zu öffnen und bei der Anmeldung zu starten. Deinstallieren: Windows-Einstellungen > Apps > Kastideo.
- **Windows, portabel**: Entpacken Sie das Archiv „windows-x64.zip“ an beliebiger Stelle und führen Sie **kastideo.exe** aus (nichts wird installiert; Updates ersetzen die Dateien des Ordners).
- Die App ist nicht signiert: Sagt SmartScreen „Der Computer wurde durch Windows geschützt“, klicken Sie auf **Weitere Informationen** und dann auf **Trotzdem ausführen**.
- **Zorin OS 17 / Ubuntu 22.04**: Paket „ubuntu22.04_amd64.deb“ (Doppelklick oder `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: Paket „ubuntu24.04_amd64.deb“.
- **Jede Distribution und Raspberry Pi (64 Bit)**: AppImage-Datei; machen Sie sie ausführbar (Rechtsklick > Eigenschaften > Ausführen erlauben, oder `chmod +x`) und starten Sie sie.
<!--/pc-->

## Kastideo auf Android und Android TV {#android}

Kastideo gibt es auch für **Android-Smartphones und -Tablets** und für **Android TV** (Google TV, Chromecast mit Google TV, Nvidia Shield, Fernseher von Philips, Sony, TCL …). Es ist dieselbe App, mit denselben Quellen, Kategorien, Favoriten, demselben Guide, Replay, Aufnahmen, MultiView und YouTube, angepasst an Touch und Fernbedienung. Eine einzige **APK**-Datei funktioniert auf Smartphones und auf Fernsehern.

### Die richtige Datei wählen

Suchen Sie auf der Release-Seite von GitHub die Dateien `Kastideo-…-android-….apk`:

- **arm64-v8a**: fast alle neueren Smartphones, Tablets und TV-Boxen (im Zweifel die richtige Wahl);
- **armeabi-v7a**: ältere Geräte und einige 32-Bit-TV-Boxen;
- **x86_64**: Emulatoren und einige Intel-Tablets;
- **universal**: alle Prozessoren, aber größer.

### Installieren, ohne die Sicherheit auszuschalten

Android verlangt **nicht**, dass Sie seine Schutzfunktionen ausschalten: Es fragt nach einer Berechtigung für **nur eine App** (die, die die APK öffnet: Browser, Dateimanager oder Downloader).

1. Laden Sie die APK herunter und öffnen Sie sie.
2. Sagt Android „Aus Sicherheitsgründen ist die Installation unbekannter Apps blockiert“, tippen Sie auf **Einstellungen** und aktivieren Sie **Aus dieser Quelle zulassen** für die App, die Sie gerade verwenden (zum Beispiel Chrome). Andere Apps bleiben blockiert.
3. Gehen Sie zurück und tippen Sie auf **Installieren**.
4. Markiert **Play Protect** eine App eines unbekannten Entwicklers, tippen Sie auf **Weitere Details** und dann auf **Trotzdem installieren**: Kastideo ist nicht bei Google Play veröffentlicht und wird von seinem Entwickler signiert, nicht von einem bei Google registrierten Herausgeber.

Alle Kastideo-APKs sind mit demselben Schlüssel signiert: Android akzeptiert daher Updates über die bestehende Installation, ohne Ihre Einstellungen zu verlieren.

### Auf Android TV installieren

Ein Fernseher hat oft weder Browser noch Dateimanager. Drei Methoden:

- **Downloader** (kostenlose App aus dem Play Store des Fernsehers): Geben Sie die Download-Adresse der APK von GitHub ein und erlauben Sie Downloader dann, Apps zu installieren;
- **USB-Stick**: Kopieren Sie die APK auf den Stick, stecken Sie ihn in den Fernseher und öffnen Sie sie mit einem Dateimanager (Solid Explorer, File Commander …);
- **Vom Smartphone aus**: Senden Sie die APK mit „Send Files to TV“ oder installieren Sie sie mit `adb install`, wenn das Netzwerk-Debugging aktiviert ist.

Kastideo erscheint dann mit seinem Banner in der App-Liste des Fernsehers.

### Bedienung per Touch (Smartphone, Tablet)

- **Menü ☰** oben links: Die Bereiche (Live, Filme, Serien, Favoriten, Kategorien …) öffnen sich in einer Seitenleiste.
- **Langes Drücken** auf einen Sender, einen Film oder eine Folge: das Menü (Favorit, aufnehmen, Replay, Software-Dekodierung …), wie ein Rechtsklick am Computer.
- **Im Player**: Ein Tippen zeigt oder verbirgt die Leiste; **Doppeltippen** links = −10 s, rechts = +30 s, Mitte = Pause; **vertikal wischen** rechts = Lautstärke, links = Helligkeit; **horizontal wischen** = in einem Film vor- oder zurückspringen.
- **Zurück** (Android-Geste oder -Taste): schließt den Player und kehrt dann zum Startbildschirm zurück.
- Drehen Sie das Gerät ins **Querformat**: Der aktuelle Sender geht in den Vollbildmodus.

### Bedienung per Fernbedienung (Android TV)

- **Die Pfeile** bewegen die Auswahl (farbig umrandet); **OK** bestätigt; **Zurück** geht zurück.
- **Menütaste** bei einem Sender oder Film: das Kontextmenü.
- **Live**: Die TV-Oberfläche öffnet sich standardmäßig. **↑ / ↓** oder **Programm +/−** wechseln den Sender, **die Ziffern** geben eine Nummer ein, **←** öffnet die Senderliste, **→** zeigt das Info-Banner, **OK** öffnet oder schließt die Liste.
- **Filme und Serien**: Die Kino-Oberfläche öffnet sich standardmäßig. Während der Wiedergabe: **OK** = Pause, **←/→** = −10 s / +30 s, **↑ / ↓** = Lautstärke; **↓** blendet die Steuerleiste ein, auf der sich die Pfeile dann bewegen.
- Die Tasten **Wiedergabe/Pause** und **Vorspulen/Zurückspulen** der Fernbedienung werden unterstützt.

### Unterschiede zum Computer

- **Lokale Videos (Galerie)**: Einstellungen > Quellen > **Galerie-Videos hinzufügen** (oder Quelle hinzufügen > **Galerie**, um **Alben auszuwählen**: Kamera, Screenshots …). Die Videos des Smartphones erscheinen in **Meine Videos** mit ihrer Miniatur, nach Datum sortiert; ein korrekt benannter Film (exakter Titel) erhält sein TMDB-Poster und seine Zusammenfassung. Android fragt nach dem Zugriff auf Videos: Ab Android 14 können Sie nur eine **Auswahl** erlauben (Schaltfläche „Weitere Videos auswählen …“). Nichts wird kopiert oder anderswohin gesendet.
- **Cast**: Unter Android nutzt das Übertragen auf einen Chromecast oder einen Fernseher den **Direktmodus**: Die Stream-Adresse wird unverändert an den Fernseher gesendet (Sender wechseln zu HLS „.m3u8“). Lokale Dateien (Meine Videos) lassen sich nicht übertragen. Die auf Computern verfügbare ffmpeg-Umwandlung steht nicht zur Verfügung.
- **Aufnahmen und Downloads** werden im Ordner der App gespeichert (`Android/data/fr.jmezes.kastideo/files/Movies`, im Dateimanager sichtbar). Android kann eine im Hintergrund laufende App beenden: Lassen Sie Kastideo geöffnet und das Gerät angeschlossen, während eine Aufnahme läuft. Eine geplante Aufnahme startet nur, wenn Kastideo zur vorgesehenen Zeit läuft.
- **Kein Start bei der Anmeldung** und keine Zuordnung von .m3u-Dateien: Fügen Sie Ihre Playlists unter Einstellungen > Quellen hinzu.
- **YouTube** öffnet sich im Browser des Geräts.

### Updates

Kastideo sucht auf GitHub nach neuen Android-Versionen. Wird eine angeboten, lädt **Installieren** die APK herunter, und Android bittet Sie um Bestätigung. Beim ersten Mal bittet Android Sie außerdem, Kastideo die Installation von Apps zu erlauben (die Einstellung öffnet sich von selbst). Nach der Installation **öffnen Sie Kastideo erneut**: Android schließt die App während der Installation.

### Wenn etwas schiefgeht

- **„App nicht installiert“**: Eine andere, mit einem anderen Schlüssel signierte Kopie von Kastideo ist bereits installiert; deinstallieren Sie sie zuerst.
- **„Parsing-Fehler“ oder „App nicht kompatibel“**: falsche Datei für Ihren Prozessor; versuchen Sie die **universal**-APK.
- **Eingefrorenes Bild**: siehe die Seite „Eingefrorenes Bild: Software-Dekodierung“.
- **Das Wiedergabeprotokoll** (Einstellungen) bewahrt die Details von Wiedergabefehlern auf.

## Kastideo Compat: ältere Macs (macOS 12 und 13) {#mac-compat}

Die **Mac**-Version von Kastideo setzt **macOS 14 Sonoma** oder neuer voraus. Für ältere Macs ist **Kastideo Compat** die für den Mac neu gebaute „Windows- / Linux“-Version: **macOS 12 Monterey und neuer**, Intel oder Apple Silicon.

**Installation.** Laden Sie `Kastideo-Compat-…-macos.dmg` von der Seite [Releases](https://github.com/jihemezes/kastideo/releases) herunter (Vorabversionen, deren Nummer auf `-desktopN` endet), öffnen Sie es und ziehen Sie **Kastideo Compat** in **Programme**. Die App ist von Apple signiert und notarisiert. Sie lässt sich **neben** der nativen Version installieren.

**Was sich von der nativen Mac-Version unterscheidet.**

- Oberfläche und Funktionen entsprechen der Windows- und Linux-Version (Wiedergabe-Engine mpv): Live, TV-Programm, Themen, MultiView, Aufnahme, Filme und Serien, YouTube …
- Tastenkürzel verwenden die **Befehlstaste** (⌘) statt Strg: ⌘1, ⌘2, ⌘3 … für die Bereiche, ⌘, für die Einstellungen, ⌘K für Pause.
- **Kein automatisches Update**: Das Banner für eine neue Version öffnet die Download-Seite.
- **Auf einen Fernseher übertragen** benötigt **ffmpeg** (zum Beispiel `brew install ffmpeg` mit Homebrew). Ohne ffmpeg funktioniert alles andere normal.
- Aufnahmen werden unter **Filme > Kastideo** gespeichert.
- Start bei der Anmeldung und die Zuordnung von .m3u-Dateien werden nicht angeboten.

Einstellungen und Quellen lassen sich mit **Sicherung und Übertragung** zwischen den Versionen verschieben.

## Kastideo auf iPhone und iPad {#ios}

**Kastideo für iPhone und iPad** (iOS 17 oder neuer) wird über **TestFlight** verteilt, den Dienst von Apple zum Testen von Apps vor der Veröffentlichung. Es gibt keine Datei, die Sie von Hand installieren müssen: Sie erhalten eine Einladung, installieren die App **TestFlight** aus dem App Store und dann **Kastideo** aus TestFlight. Updates kommen über TestFlight.

**Erster Start.** Lesen und akzeptieren Sie den Haftungsausschluss. Tippen Sie auf dem Startbildschirm auf **Quelle hinzufügen** (Xtream Codes oder M3U-Liste) oder gehen Sie zu **Einstellungen > Konfiguration importieren …**, um Ihre Quellen, Favoriten und Kategorien von Mac, Windows, Linux oder Android zu übernehmen (siehe „Sicherung und Übertragung“). Tipp: Speichern Sie die Konfigurationsdatei in **iCloud Drive**, um sie auf allen Ihren Geräten zu finden.

**Was die App bietet.**

- **Startseite**: auf einem Farbverlauf mit dem Logo die großen Kacheln **Live, Filme, Serien, YouTube** und **Meine Videos** (wenn Sie eine Galerie, einen Ordner oder einen Server haben), mit der Anzahl ihrer Elemente; darunter die Schaltflächen **Fortsetzen, Zuletzt gesehen, Favoriten, TV-Programm** und **Aufnahmen**, und oben ein Suchfeld. **Fortsetzen / Zuletzt gesehen / Favoriten** öffnen eine Rasterseite: Halten Sie ein Element gedrückt oder tippen Sie auf **Auswählen**, um mehrere zu entfernen, **Alles leeren** im Menü ⋯ und **Rückgängig** direkt nach dem Entfernen.
- **Untere Leiste**: **Start** (kehrt von jedem Bildschirm zur Startseite zurück), **Inhalte** (Quellen, Galerie, Kategorien, TMDB-Detailseiten, YouTube, iCloud, Sicherung), **App** (Wiedergabe, MultiView, Aufnahmen, Replay, Kino, Darstellung, Info) und **Hilfe**. Die Angaben „Einstellungen > …“ auf dieser Seite gehören zu einer dieser beiden Gruppen.
- **MultiView im Hochformat**: Wird das Gerät aufrecht gehalten, werden die MultiView-Bildschirme **gestapelt** (übereinander, in voller Breite) statt nebeneinander; im Querformat bleibt Ihre gewählte Anordnung erhalten.
- **Apple TV** (Beta): empfängt Ihre Konfiguration vom iPhone (Einstellungen > Sicherung > An Apple TV senden), „Gesehen“-Abzeichen; Guide, der an der letzten Position wieder geöffnet wird (Einstellung); dieselbe App gibt es für Apple TV (tvOS 17) — Klassische, Kino- und TV-Ansicht (Live), pro Inhaltstyp gewählt (Schaltfläche „Ansicht“ oder Einstellungen > Ansicht); Startseite mit Kacheln (wie auf dem iPad), Meine Videos (Emby, Jellyfin, Plex), Live, Filme, Serien, ein TV-Programm als Zeitraster (3-Stunden-Fenster, Sendungs-Replay) und ein per Fernbedienung bedienbarer Player (↑ / ↓ wechseln den Sender; Klick = Tonspuren, Untertitel, Geschwindigkeit, letzter Sender, Sendernummer; automatische nächste Folge). Reiter Suche, Favoriten (langes Drücken), Einschlaf-Timer. Einstellungen: bearbeitbare Quellen, Startseite, Kategorien, Zappen (mit Bestätigung oder direkt). Fügen Sie Quellen von einem Smartphone aus hinzu (QR-Code + 4-stelliger Code, Einstellungen > Von einem Smartphone hinzufügen; das Formular passt sich dem Quellentyp an und akzeptiert den TMDB-Schlüssel) oder mit der Tastatur; die Synchronisierung mit iCloud Drive ist auf Apple TV nicht verfügbar.
- **Gesehen und Guide**: Abzeichen auf gesehenen Postern, „Als gesehen markieren“ (Details, langes Drücken auf eine Folge, Staffel); Einstellung „Beim Öffnen des Guides“ (Einstellungen > Replay).
- **Kategorien (Live, Filme, Serien)**: In der Listen- oder Rasteransicht wechselt die **Leiste oben** (Alle, Favoriten, Zuletzt gesehen, dann jede Kategorie) die Kategorie mit einem Tipp; die Schaltfläche ▦ links öffnet die **vollständige Liste** mit Suche und Elementzahlen.
- **Live**: Die Schaltfläche oben links ändert die Anzeige — **Liste** (Sender mit aktueller Sendung, Suche, Kategorien, Favoriten; einen Sender nach links wischen), **Kino** (ein „hervorgehobenes“ Banner, Reihen „läuft jetzt“ nach Thema, „Nochmal ansehen“, Zuletzt gesehen, Favoriten, eine Reihe pro Kategorie), **Themen** (Sport, Nachrichten, Filme …: läuft jetzt, heute Abend, alle Sender; langes Drücken, um das Thema eines Senders zu ändern) und **TV-Programm**.
- **TV-Programm**: ein **Raster** wie auf dem Mac — der Tag als waagerechte Zeitleiste, eine Zeile pro Sender, **Senderspalte** und **Uhrzeiten immer sichtbar**, roter „Jetzt“-Marker, aktuelle Sendung in Orange. Ziehen Sie in beide Richtungen, **zoomen Sie mit zwei Fingern** auf der Zeitskala (oder Menü > Zeitskala). Wählen Sie den Tag (bis zu 14 vergangene Tage je nach Einstellungen > Replay und 3 im Voraus) und tippen Sie auf eine Uhrzeit, um dorthin zu springen. Tippen Sie auf eine Sendung für ihre Seite (**Live ansehen**, **Replay**, **Erinnern**, Favorit); langes Drücken bietet dieselben Aktionen. Das Menü filtert nach **Favoriten, Zuletzt gesehen, Thema oder Kategorie** und wechselt zurück zur Ansicht **Zeitfenster** (eine Zeile pro Sender zur gewählten Uhrzeit).
- **Replay**: Bei mit ↺ markierten Sendern können Sie eine Sendung aus dem Archiv des Anbieters **nochmal ansehen** (Sendungsdetails oder langes Drücken auf einen Sender > Nochmal ansehen). Im Player **Zurück zu Live**; endet ein Replay, kehren Sie automatisch zu Live zurück (einstellbar). Einstellungen > Replay: vergangene Tage, Zeitkorrektur, falls ein Replay zur falschen Zeit beginnt.
- **Filme** und **Serien**: **Kino**-Anzeige (scrollendes „hervorgehobenes“ Banner, Fortsetzen, Zuletzt gesehen, Favoriten, eine Reihe pro Kategorie — die **Startkategorie** (Einstellungen > Organisation) zuerst —, Länderfilter wie auf dem Mac) oder **Raster** (gesamter Katalog); Suche, Detailseite mit Zusammenfassung, dort weiterschauen, wo Sie aufgehört haben, Staffeln und Folgen. Einstellungen > Kino-Anzeige: Inhalt und Geschwindigkeit des Banners.
- **Player**: Tippen Sie, um die Steuerelemente anzuzeigen. **Gesten**: Doppeltippen links = −10 s, rechts = +30 s, in der Mitte = Pause; **vertikal wischen** rechts = Lautstärke, links = Helligkeit; **horizontal wischen** = in einem Film spulen (Zeitvorschau) oder bei Live den **Sender wechseln**. Der Lautsprecher unten stellt die **Lautstärke** ein und schaltet **stumm / Ton ein**; das Zeichen oben rechts (Empfangsfarbe, HD / 4K) öffnet die **Stream-Info**: Auflösung, Bitrate, Bilder pro Sekunde, verworfene Bilder, Unterbrechungen. Bei einem Film oder einer Folge zeigt die Leiste die verstrichene Zeit, die **Restzeit** und die **Endzeit**. Bei Live werden die **aktuelle Sendung** (Fortschrittsbalken) und die nächste unter dem Sendernamen angezeigt, und die Schaltflächen |◀ ▶| wechseln zum vorherigen / nächsten Sender der Kategorie. Die Schaltfläche ⋯ bietet die **Wiedergabegeschwindigkeit** (0,5× bis 2×), das **Bildformat** (einpassen, Bildschirm füllen, 16:9, 4:3), den **zuletzt gesehenen Sender** und bei einer Serie die **Folgenliste**; die Schaltfläche **Weiter** startet die nächste Folge, und Folgen **laufen nacheinander** (Einstellungen > App > Wiedergabe).
- **Meine Videos**: Die Schaltfläche oben rechts **sortiert** (Name A→Z / Z→A, Datum, Größe, Dauer), **gruppiert** (Menü Gruppieren nach: Quelle, Kategorie / Ordner / Album, Typ, Jahr oder Monat des Hinzufügens — **mehrere Kriterien gleichzeitig**, z. B. Quelle dann Kategorie, mit einklappbaren Abschnitten; die Sortierung gilt innerhalb jedes Abschnitts) und **filtert** (Typ, Ansehen: ungesehen / begonnen / gesehen / Favoriten, Quelle). Das Sortieren nach Größe misst die Dateien beim ersten Mal; Videos mit unbekannter Größe (Server) kommen zuletzt. Ihre Auswahl wird gemerkt.
- **Kategorien**: Einstellungen > Kategorien verwalten — **Alle abwählen / Alle auswählen** oben in der Liste (praktisch, um nur wenige Kategorien zu behalten), Reihenfolge (ziehen), ausblenden, umbenennen, nach Stichwort ausblenden (z. B. PAKISTAN), A→Z sortieren, zurücksetzen; Länder und Sprachen für die Kino-Anzeige. Um die **Sender** einer Kategorie neu zu ordnen: Live in der Listenansicht, die Kategorie wählen, Menü oben rechts > „Sender neu anordnen …“.
- **Einen Sender bearbeiten** (langes Drücken): Name, Nummer, Logo (Webadresse oder Foto), Thema, zugeordneter TV-Programm-Sender, wenn der Guide falsch ist.
- **Darstellung**: Design, Akzentfarbe, Postergröße, Listendichte, Standardanzeige für Live, Filme und Serien.
- **Start**: beim Start angezeigter Reiter und Startseite von Live, Filme und Serien (alle, Favoriten, Zuletzt gesehen, zuletzt angesehen oder eine Kategorie).
- **Eine Quelle bearbeiten**: Einstellungen > Quellen, tippen Sie auf eine Quelle (oder wischen Sie sie > Bearbeiten), um Name, Adresse, Zugangsdaten (leeres Passwort oder Token = bleibt erhalten), TV-Programm oder Ordner zu ändern und die Verbindung eines Xtream-Kontos zu testen.
- **iCloud-Synchronisierung**: Einstellungen > **iCloud**. Finden Sie Quellen, Favoriten, Wiedergabe-Fortsetzung … auf Ihrem iPhone, iPad und Mac über einen Ordner in iCloud Drive. Siehe die Seite [Mit iCloud synchronisieren](#icloud).
- **Lokale Videos (Galerie)**: Einstellungen > **Galerie-Videos hinzufügen** (oder Quelle hinzufügen > iPhone-Galerie, um **Alben auszuwählen**: Kamera, Screenshots …). Videos erscheinen unter Filme, in **Meine Videos**, mit ihrer Miniatur, nach Aufnahmedatum sortiert; ein korrekt benannter Film (exakter Titel) erhält sein TMDB-Poster und seine Zusammenfassung. iOS fragt nach dem Zugriff auf Ihre Fotos: Erlauben Sie nur eine **Auswahl**, erscheinen nur diese Videos (Einstellungen > Lokale Videos > Weitere Videos auswählen …). Ein nur in iCloud gespeichertes Video wird vor der Wiedergabe heruntergeladen. Nichts wird kopiert oder anderswohin gesendet. Einstellung: beim Öffnen der App aktualisieren.
- **TMDB-Seiten**: Mit einem kostenlosen TMDB-Schlüssel (Einstellungen > Film- und Seriendetails) zeigt die Seite eines Films oder einer Serie das HD-Poster, die übersetzte Zusammenfassung, Genres, Bewertung, Besetzung mit Fotos und den Trailer, und das hervorgehobene Banner bietet **die Trends dieser Woche**, die sich in Ihrem Katalog finden. Eine Seite ist falsch? Auf der Seite **Details korrigieren …**: Fügen Sie die Nummer oder Adresse der Seite von themoviedb.org ein, suchen Sie nach Titel oder geben Sie Titel, Jahr, Poster und Zusammenfassung von Hand ein. **Korrektur entfernen** kehrt zur automatischen Seite zurück; die Liste der Korrekturen steht in den Einstellungen.
- **Mehrere Abonnements**: Einstellungen > Abonnements, um nur eine Quelle anzuzeigen, ohne die andere zu deaktivieren, Duplikate zwischen Konten zusammenzuführen und die **Diagnose** einer Quelle (nach links wischen).
- **Live-TV aufnehmen**: Während eines Live-Senders nimmt ihn der rote runde Knopf im Player auf (automatischer Stopp einstellbar). Die .ts-Dateien liegen in der **App Dateien > Auf meinem iPhone > Kastideo > Enregistrements**; spielen Sie sie in Kastideo oder VLC ab, teilen Sie sie oder löschen Sie sie (wischen). Geplante Aufnahmen sind auf dem iPhone nicht möglich (die App kann sich nicht selbst aufwecken): Nutzen Sie Erinnerungen oder den Mac.
- Einen Film oder eine Folge **herunterladen**: die Schaltfläche ↓ auf ihrer Seite (oder „Staffel herunterladen“). Downloads laufen bei geschlossener App weiter; pausieren, fortsetzen und löschen Sie unter **Aufnahmen** (Ablagesymbol oben rechts oder Einstellungen). Die Dateien gehen nach Dateien > Kastideo > Téléchargements. Downloads laufen **einer nach dem anderen** (eine Staffel geht Folge für Folge, die anderen zeigen „Wartet“). Viele Anbieter erlauben nur eine Verbindung: Ein Download kann die laufende Wiedergabe unterbrechen.
- **Live mit Zeitversatz**: Pausieren Sie den Live-Sender, er wird weiter gespeichert. Gehen Sie 10 s zurück, 30 s vor, ziehen Sie die Zeitleiste, beschleunigen Sie (×1,25 bis ×2) und tippen Sie auf **Zurück zu Live**. Maximale Dauer und Geschwindigkeit: Einstellungen > Live mit Zeitversatz.
- **Sendungserinnerungen** (Einstellungen): nach Stichwort, nach Thema auf Ihren Lieblingssendern oder „Zu Beginn benachrichtigen“ auf der Seite einer Sendung. Es sind iPhone-Mitteilungen, die auch bei geschlossener App ankommen; tippen Sie auf eine, um den Sender zu öffnen. Erlauben Sie Mitteilungen, wenn iOS fragt.
- **Meine Videos**: Einstellungen > Quelle hinzufügen > **Jellyfin, Emby, Plex** oder **Videoordner** (iPhone, iCloud Drive, USB-Laufwerk, in Dateien hinzugefügtes NAS). Unter Filme und Serien wählt die Schaltfläche oben rechts **Alle / IPTV / Meine Videos**.
- **YouTube** (Reiter YouTube oder die Kachel auf der Startseite): Folgen Sie Kanälen (Link oder @Handle im Suchfeld einfügen, ohne Schlüssel oder Konto), fügen Sie einen Video- oder Playlist-Link zum Abspielen ein, **suchen** Sie mit Ihrem eigenen kostenlosen Google-API-Schlüssel (Einstellungen > YouTube, Schritte inklusive), legen Sie Videos **beiseite** (langes Drücken), fügen Sie Favoriten hinzu, finden Sie Ihren **Verlauf** und die Fortsetzungsposition (roter Balken auf der Miniatur). Importieren Sie Ihre Abos aus einem **Google-Takeout**-Export (subscriptions.csv). Die Wiedergabe nutzt den offiziellen YouTube-Player im „erweiterten Datenschutzmodus“; er ist kein Werbeblocker. Das Starten eines Videos stoppt die IPTV-Wiedergabe.
- **MultiView**: mehrere Sender gleichzeitig (2 bis 4 Bildschirme), wie auf dem Mac. Sie wird nur angeboten, wenn Ihre Quellen mindestens zwei gleichzeitige Streams erlauben: Legen Sie die Anzahl der Verbindungen jedes Abonnements unter **Einstellungen > MultiView** fest (1 bei den meisten; eine öffentliche Liste erlaubt 4). Öffnen Sie sie mit der Schaltfläche ▦ in **Live** oder im Player (der aktuelle Sender wird hinzugefügt). Jeder Bildschirm ist einer Quelle vorbehalten; wählen Sie Sender, Anordnung (nebeneinander, gestapelt, Raster, **ein großer + verschiebbare Miniaturen**) und Anzahl der Bildschirme im oberen Menü. Tippen Sie auf einen Bildschirm, um ihm den Ton zu geben, doppeltippen Sie auf eine Miniatur, um sie groß zu machen, langes Drücken, um Sender oder Quelle zu wechseln oder den Bildschirm zu entfernen. Das Öffnen von MultiView stoppt die Hauptwiedergabe (außer wenn eine Aufnahme läuft).
- **Vollbild-Player**: Tippen Sie auf das Bild, um die Steuerelemente anzuzeigen, ziehen Sie die Leiste zum Spulen, wählen Sie Tonspur und Untertitel. Schließen Sie ihn mit dem Pfeil: Die Wiedergabe läuft weiter, mit einem **Mini-Player** über der Tab-Leiste. Der Ton läuft bei gesperrtem Bildschirm weiter.
- **AirPlay**: Die Schaltfläche im Player sendet den Ton an einen Apple TV oder HomePod; für Video nutzen Sie die Bildschirmspiegelung von iOS.
- Gleiche Wiedergabe-Engine (VLC) und gleiche Puffer-Einstellungen wie auf dem Mac; Stream-Relay für Anbieter, die direkte Verbindungen ablehnen.

**Noch nicht auf iPhone / iPad**: Bild-in-Bild (mit der aktuellen Wiedergabe-Engine nicht verfügbar). Eine Version für **Apple TV** ist für später geplant.

Schlägt die Wiedergabe fehl: **Einstellungen > Info > Wiedergabeprotokoll teilen**.
## Mit iCloud synchronisieren (iPhone, iPad, Mac) {#icloud}

Kastideo kann **Ihre Apple-Geräte identisch halten**: iPhone, iPad und Mac teilen Ihre Quellen, Favoriten, den Verlauf, Kategorien, Anzeigeeinstellungen, die **Wiedergabe-Fortsetzung**, korrigierte Detailseiten und — optional — **Passwörter**. Die Synchronisierung läuft über **einen Ordner in Ihrem iCloud Drive**: Kastideo legt dort kleine Dateien ab.

**Einrichtung (auf jedem Gerät).**

1. Erstellen Sie in iCloud Drive einen Ordner, zum Beispiel **Kastideo** (einmalig). Stellen Sie sicher, dass iCloud Drive auf jedem Gerät eingeschaltet ist.
2. Öffnen Sie Kastideo > Einstellungen > **iCloud** und schalten Sie **Mit iCloud Drive synchronisieren** ein.
3. Tippen Sie auf **Synchronisierungsordner** und wählen Sie **denselben Ordner**.
4. Wählen Sie, was synchronisiert werden soll.
5. Wenn Sie Passwörter oder den TMDB-Schlüssel synchronisieren, geben Sie das **Kennwort** ein — auf allen Geräten dasselbe — und dann **Kennwort sichern**.

**Gut zu wissen.**

- Die jüngste Änderung gewinnt. Bei der ersten Synchronisierung werden die Listen (Quellen, Favoriten, Verlauf) zusammengeführt.
- Passwörter werden mit Ihrem Kennwort **verschlüsselt**, bevor sie gespeichert werden: Ohne es kann sie niemand lesen. Notieren Sie es: Es lässt sich nicht wiederherstellen.
- Videoordner, M3U-Dateien und die Galerie bleiben gerätespezifisch. Anzeigeeinstellungen, die nur für Mac oder iPhone gelten, werden getrennt behalten.
- Die Synchronisierung läuft alle 30 Sekunden, bei der Rückkehr in die App und wenn sie in den Hintergrund wechselt; **Jetzt synchronisieren** erzwingt sie. Auf dem Mac zeigt ein kleines Wolkensymbol unten in der Seitenleiste den Status.
- „Synchronisierungsdateien löschen“ entfernt die Dateien im Ordner für alle Ihre Geräte (Ihre lokalen Daten bleiben erhalten).
- Windows, Linux und Android sind nicht abgedeckt: Nutzen Sie Export / Import der Konfiguration.

## Neuigkeiten {#nouveautes}

Nach jedem Update fasst das Fenster **Neuigkeiten** die Änderungen der installierten Version zusammen.

<!--mac-->
Sie können es mit **Hilfe > Neuigkeiten in dieser Version** oder per Klick auf die Versionsnummer unten rechts auf der Startseite erneut öffnen und dort frühere Versionen durchblättern.
<!--/mac-->
<!--pc-->
Sie können es per Klick auf die Versionsnummer unten rechts auf der Startseite erneut öffnen und dort frühere Versionen durchblättern.
<!--/pc-->

Der vollständige Verlauf wird außerdem auf der Seite [GitHub Releases](https://github.com/jihemezes/kastideo/releases) veröffentlicht.

# Fehlerbehebung

## Fehlerbehebung {#depannage}

<!--mac-->
- **Ein Sender hat keinen Ton**: Kastideo erkennt das innerhalb weniger Sekunden und repariert es selbst: Ist die Stream-Uhr verschoben (Ton wird verworfen, „buffer too late“ im Protokoll), wird der Sender mit Ton und Bild synchronisiert neu geöffnet, und Kastideo merkt es sich; andernfalls startet es die Tonspur neu oder probiert die nächste. Bleibt ein oranges 🔇-Symbol neben dem Statusindikator, sendet der Anbieter einen Stream ohne Ton oder eine unlesbare Spur: Probieren Sie eine andere Version des Senders (HD, SD …) oder wählen Sie eine andere Tonspur im Infopanel (⌘I). Das Wiedergabeprotokoll (Zeilen „Son :“) zeigt das empfangene Format.

- **„Der Anbieter lehnt diesen Sender ab (HTTP 403)“**: Der Anbieter selbst sperrt diesen Sender (außer Betrieb oder nicht in Ihrem Abonnement). Kastideo besteht nicht darauf; probieren Sie eine andere Version (HD, SD …) oder später.
- **Eingefrorenes Bild, „Fehlerhafter Stream beim Anbieter“**: Die Stream-Uhr ist inkonsistent. Kastideo öffnet den Sender einmal neu, mit Ton und Bild synchronisiert; reicht das nicht, schaltet es auf **nur Bild** (ohne Ton), damit das Bild nicht mehr einfriert, und merkt es sich. Rechtsklick auf den Sender > **Nur Bild (ohne Ton)**, um es von Hand ein- oder auszuschalten. Einstellungen > Allgemein > Wiedergabe > **Zurücksetzen** hebt diese gemerkten Reparaturen auf.
- **Stream-Relay** (Einstellungen > Allgemein > Wiedergabe, standardmäßig an): Kastideo öffnet die Verbindung zum Anbieter selbst und reicht sie an die VLC-Engine weiter, wie Piboard, sodass es nie zwei gleichzeitig gibt. Das Wiedergabeprotokoll zeigt dann Zeilen „Relais :“ mit der genauen Antwort des Anbieters (z. B. „HTTP 200 en 0,35 s“).
- **Langsamer oder abgelehnter Senderwechsel („HTTP 404“, „403“, „401“ oder „520“ im Wiedergabeprotokoll)**: Bei einem Abonnement mit einer Verbindung braucht der Anbieter einen Moment, um den vorherigen Sender freizugeben. Kastideo wartet 1,5 s, bevor es den neuen Sender öffnet, und versucht es einmal erneut, wenn er abgelehnt wird („Attente…“ und „nouvel essai“ im Protokoll). Halten die Ablehnungen an, warten Sie eine Minute und versuchen Sie es erneut.

Kastideo meldet sich gegenüber Servern als **VLC**-Player: Viele IPTV-Anbieter antworten nur Playern, die sie erkennen.

- **„Der Server hat nicht rechtzeitig geantwortet“**: Der Server ist überlastet oder nicht verfügbar. Versuchen Sie es später erneut; sieht Ihre Adresse wie `get.php?username=…` aus, prüfen Sie, dass sie in Xtream Codes umgewandelt wurde (Typ in den Quelleneinstellungen angezeigt).

- **„Benutzername oder Passwort abgelehnt“**: Prüfen Sie Ihre Zugangsdaten mit **Verbindung testen**.
- **„Konto nicht aktiv“**: Das Abonnement ist abgelaufen oder bei Ihrem Anbieter gesperrt.
- **Keine Sendung im Guide**: Der Sender hat keine TV-Programm-Kennung, oder der Guide Ihrer Quelle enthält keine für ihn.
- **„App Transport Security“**: Diese Meldung erschien in den Versionen 0.1.0 und 0.2.0 bei http://-Quellen. Seit Version 0.2.1 ist sie behoben.
- **Wiedergabe nicht möglich**: Der Server hat den Stream nicht geliefert. Prüfen Sie, dass kein anderes Gerät Ihr Abonnement nutzt (nur eine Verbindung erlaubt), und klicken Sie dann auf **Erneut versuchen**. Probieren Sie auch den Puffer **Stabil**.
<!--/mac-->

<!--pc-->
- **Ein Sender startet nicht**: Öffnen Sie das **Protokoll** (Strg+Alt+L, Thema *Wiedergabe und Relay*). Zeilen „Relais :“ geben die genaue Antwort des Anbieters (z. B. „HTTP 200 en 0,35 s“ oder „HTTP 403“).
- **Das Update lässt sich nicht installieren**: Das Wiedergabeprotokoll (Strg+Alt+L) nennt den Grund. .deb-Paket: Erscheint das Passwortfenster nicht, wird der im Terminal einzugebende Befehl im Update-Fenster angezeigt. Sie können die neue Version immer von der Release-Seite auf GitHub herunterladen.
- **MultiView: Eine Kachel bleibt schwarz**: Der Anbieter lehnt eine zusätzliche Verbindung ab. Prüfen Sie die Anzahl der Verbindungen Ihres Abonnements (Einstellungen > Allgemein > Wiedergabe > Erkennen).
- **Keine Mitteilung**: Prüfen Sie Einstellungen > Allgemein > Mitteilungen, dann die Mitteilungseinstellungen von Windows (Einstellungen > System > Benachrichtigungen) oder Ihres Linux-Desktops. Unter Linux wird das Paket libnotify benötigt (vom .deb installiert, im AppImage enthalten).
- **Leere Aufnahme**: Der Anbieter hat nichts gesendet (Sender abgelehnt, Verbindung bereits von einem anderen Gerät genutzt). Die Zeilen „Enregistrement“ im Protokoll geben die Antwort des Anbieters (z. B. „HTTP 403“) und sagen, ob nach 30 s keine Daten ankamen.
- **Der Zeitversatz geht nicht weiter zurück**: Seine Tiefe hängt vom temporären Speicherplatz ab; ohne Festplatten-Cache (manche libmpv-Versionen unter Linux) ist er auf 512 MB im Arbeitsspeicher begrenzt.
- **Details in einer anderen Sprache**: Manche Anbieter haben nur eine Sprache. Mit einem **TMDB-Schlüssel** stammen Zusammenfassungen, Genres und Folgen aus TMDB in Ihrer Sprache.
- **Einzelnes Fenster**: Wird Kastideo gestartet, obwohl es schon läuft, holt es nur das vorhandene Fenster in den Vordergrund.
- **Kein Bild unter Linux**: Stellen Sie sicher, dass das Paket **libmpv** installiert ist (das .deb installiert es; das AppImage bringt es mit).
- **VPN**: Ein aktives VPN kann verhindern, dass der Anbieter Streams ausliefert.
- **Keine Sendungen im Guide**: Einstellungen > Quellen zeigt den Guide-Status jeder Quelle; der Ersatz-Guide ergänzt gängige französische Sender.
- **Passwörter unter Linux**: Ohne Schlüsselbund (GNOME Keyring oder KWallet) behält Kastideo Passwörter in seinen Einstellungen und weist im Protokoll darauf hin.
<!--/pc-->

## Das Fenster liegt außerhalb des Bildschirms (Windows und Linux) {#fenetre-hors-ecran}

Bei mehreren Bildschirmen konnte sich ein Fenster halb außerhalb des Bildschirms öffnen, ohne erreichbare Titelleiste. Seit Version 1.12.1 **merkt sich Kastideo die Fensterposition** und prüft beim Start, dass seine Titelleiste auf einem Bildschirm sichtbar ist. Ist sie das nicht (Bildschirm abgesteckt, Auflösung oder Skalierung geändert), wird das Fenster **auf dem Hauptbildschirm neu zentriert**.

Ist ein Fenster weiterhin außer Reichweite: Drücken Sie unter Windows **Alt + Leertaste**, dann **V** (Verschieben), dann die Pfeiltasten; oder schließen Sie Kastideo und starten Sie es neu.

# Info

## Haftungsausschluss {#avertissement}

Danke, dass Sie Kastideo nutzen. Kastideo ist ein Medienplayer: Er spielt Playlists (M3U), IPTV-Konten (Xtream Codes), Ihre eigenen Server (Jellyfin, Emby, Plex), die Videos auf Ihren Laufwerken und YouTube ab.

- **Keine Inhalte.** Kastideo stellt keinen Sender, Film, keine Playlist und kein Abonnement bereit, hostet oder verkauft sie nicht.
- **Keine Verbindung.** Kastideo ist weder mit einem Anbieter von Inhalten oder IPTV-Abonnements noch mit YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple oder Microsoft verbunden. Genannte Marken gehören ihren jeweiligen Inhabern. Dieses Produkt verwendet die TMDB-API, wird aber von TMDB weder unterstützt noch zertifiziert.
- **Ihre eigenen Inhalte.** Sie müssen Ihre eigenen Quellen und Inhalte mitbringen. Sie allein sind dafür verantwortlich zu prüfen, dass sie legal sind und dass Sie alle Rechte besitzen, die zum Ansehen, Aufnehmen, Herunterladen und Streamen nötig sind.
- **Urheberrecht.** Kastideo fördert nicht das Streamen urheberrechtlich geschützten Materials ohne Erlaubnis des Rechteinhabers. Aufnahmen, Downloads und die Übertragung auf einen Fernseher sind nur für den privaten Gebrauch bestimmt, im Rahmen der Gesetze Ihres Landes.
- **Haftung.** Der Autor von Kastideo ist nicht verantwortlich für Ihre Nutzung der Software, noch für Inhalt, Verfügbarkeit oder Rechtmäßigkeit der Dienste Dritter, mit denen Sie sie verbinden. Kastideo wird kostenlos, „wie besehen“, ohne Gewährleistung bereitgestellt.
- **Ihre Daten.** Ihre Zugangsdaten bleiben auf Ihrem Gerät und werden nur an die von Ihnen konfigurierten Dienste gesendet.

Mit einem Klick auf „Ich verstehe und akzeptiere“ bestätigen Sie, dass Sie diese Bedingungen gelesen haben und akzeptieren. Andernfalls beenden Sie bitte die Anwendung.

Dieser Hinweis erscheint beim ersten Start und nach jedem Update. Sie können ihn jederzeit erneut lesen unter <!--mac-->**Einstellungen (⌘,) > Info**<!--/mac--><!--pc-->**Einstellungen (Strg+,) > Info**<!--/pc-->.

## Kastideo unterstützen {#soutenir}

<!--mac-->
Kastideo ist **kostenlos**. Gefällt Ihnen die App, können Sie ihre Entwicklung unterstützen, indem Sie mir auf [Ko-fi](https://ko-fi.com/jihemezes) einen Kaffee spendieren: völlig freiwillig.

Die Schaltfläche **Spendiere mir einen Kaffee** erscheint dezent auf dem Startbildschirm und im Fenster Neuigkeiten sowie unter **Einstellungen > Info** und **Hilfe > Kastideo unterstützen (Ko-fi)**. Um die Schaltflächen auf dem Startbildschirm und in den Neuigkeiten auszublenden, kreuzen Sie **Die Schaltflächen „Spendiere mir einen Kaffee“ ausblenden** unter **Einstellungen > Info** an.
<!--/mac-->

<!--pc-->
Kastideo ist **kostenlos**. Gefällt Ihnen die App, können Sie ihre Entwicklung unterstützen, indem Sie mir auf [Ko-fi](https://ko-fi.com/jihemezes) einen Kaffee spendieren: völlig freiwillig.

Die Schaltfläche **Spendiere mir einen Kaffee** erscheint dezent auf dem Startbildschirm und im Fenster Neuigkeiten sowie unter **Einstellungen > Info**. Um die Schaltflächen auf dem Startbildschirm und in den Neuigkeiten auszublenden, kreuzen Sie **Die Schaltflächen „Spendiere mir einen Kaffee“ ausblenden** unter **Einstellungen > Info** an.
<!--/pc-->

## Datenschutz {#confidentialite}

<!--mac-->
Kastideo läuft in der macOS-Sandbox. Es greift nur auf das Netzwerk und die Dateien zu, die Sie wählen. Ihre Passwörter bleiben im Schlüsselbund. Daten werden nirgendwohin gesendet außer an Ihre eigenen Quellen.
<!--/mac-->

<!--pc-->
Kastideo erhebt keine Daten. Es kontaktiert nur Ihre IPTV-Anbieter, die von Ihnen gewählten TV-Programme, GitHub für Updates und, falls Sie einen Schlüssel eingegeben haben, TMDB. Ihre Einstellungen, Favoriten und Passwörter bleiben auf Ihrem Computer.
<!--/pc-->

## Lizenzen {#licences}

<!--mac-->
Kastideo verwendet **VLCKit** (die Engine von VLC, © VideoLAN, Lizenz LGPL 2.1 oder neuer, https://www.videolan.org/vlc/libvlc.html) und **Sparkle** (MIT-Lizenz, https://sparkle-project.org). VLCKit ist als unveränderte dynamische Bibliothek eingebettet.
<!--/mac-->
