import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n.dart';
import '../theme.dart';
import '../version.dart';

/// Avertissement légal affiché au premier lancement et après chaque mise à jour (texte français et anglais).
/// Le texte est le même dans l'aide (page « Avertissement ») et dans le README.
class _LegalText {
  const _LegalText({
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.points,
    required this.closing,
    required this.accept,
    required this.quit,
    required this.close,
  });
  final String title, subtitle, intro, closing, accept, quit, close;
  final List<(String, String)> points;
}

const _spanish = _LegalText(
  title: 'Aviso legal',
  subtitle: 'Para leer antes de usar Kastideo',
  intro: 'Gracias por usar Kastideo. Kastideo es un reproductor multimedia: reproduce listas de reproducción (M3U), cuentas IPTV (Xtream Codes), sus servidores personales (Jellyfin, Emby, Plex), los vídeos de sus discos y YouTube.',
  points: [
    ('Ningún contenido proporcionado.', 'Kastideo no proporciona, aloja ni vende ningún canal, película, lista de reproducción ni suscripción.'),
    ('Ninguna afiliación.', 'Kastideo no está afiliado a ningún proveedor de contenidos o de suscripciones IPTV, ni a YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple o Microsoft. Las marcas citadas pertenecen a sus propietarios. Este producto utiliza la API de TMDB, pero TMDB no lo respalda ni lo certifica.'),
    ('Sus propios contenidos.', 'Usted debe aportar sus propias fuentes y contenidos. Es el único responsable de comprobar que son legales y de que dispone de todos los derechos necesarios para verlos, grabarlos, descargarlos y retransmitirlos.'),
    ('Derechos de autor.', 'Kastideo no fomenta la difusión de contenidos protegidos por derechos de autor sin la autorización de sus titulares. Las grabaciones, las descargas y la transmisión a un televisor (Cast) están reservadas al uso privado, dentro de los límites de la ley de su país.'),
    ('Responsabilidad.', 'El autor de Kastideo no es responsable del uso que usted haga del software ni del contenido, la disponibilidad o la legalidad de los servicios de terceros a los que lo conecte. Kastideo se ofrece gratuitamente, «tal cual», sin garantía.'),
    ('Sus datos.', 'Sus credenciales se conservan en su dispositivo y solo se envían a los servicios que usted configure.'),
  ],
  closing: 'Al hacer clic en «Lo he entendido y acepto», usted reconoce haber leído estas condiciones y las acepta. En caso contrario, cierre la aplicación.',
  accept: 'Lo he entendido y acepto',
  quit: 'Salir',
  close: 'Cerrar',
);

const _german = _LegalText(
  title: 'Rechtlicher Hinweis',
  subtitle: 'Bitte vor der Nutzung von Kastideo lesen',
  intro: 'Vielen Dank, dass Sie Kastideo verwenden. Kastideo ist ein Medienplayer: Er spielt Wiedergabelisten (M3U), IPTV-Konten (Xtream Codes), Ihre eigenen Server (Jellyfin, Emby, Plex), die Videos auf Ihren Laufwerken und YouTube ab.',
  points: [
    ('Keine Inhalte bereitgestellt.', 'Kastideo stellt keine Sender, Filme, Wiedergabelisten oder Abonnements bereit, hostet oder verkauft sie nicht.'),
    ('Keine Zugehörigkeit.', 'Kastideo ist weder mit einem Anbieter von Inhalten oder IPTV-Abonnements noch mit YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple oder Microsoft verbunden. Die genannten Marken gehören ihren jeweiligen Inhabern. Dieses Produkt verwendet die TMDB-API, wird von TMDB jedoch weder unterstützt noch zertifiziert.'),
    ('Ihre eigenen Inhalte.', 'Sie müssen Ihre eigenen Quellen und Inhalte bereitstellen. Sie allein sind dafür verantwortlich zu prüfen, dass diese rechtmäßig sind und dass Sie alle erforderlichen Rechte besitzen, um sie anzusehen, aufzunehmen, herunterzuladen und zu übertragen.'),
    ('Urheberrecht.', 'Kastideo fördert nicht die Verbreitung urheberrechtlich geschützter Inhalte ohne die Erlaubnis der Rechteinhaber. Aufnahmen, Downloads und die Übertragung auf einen Fernseher (Cast) sind ausschließlich für den privaten Gebrauch im Rahmen der Gesetze Ihres Landes bestimmt.'),
    ('Haftung.', 'Der Autor von Kastideo ist weder für Ihre Nutzung der Software noch für den Inhalt, die Verfügbarkeit oder die Rechtmäßigkeit der Dienste Dritter verantwortlich, mit denen Sie sie verbinden. Kastideo wird kostenlos, „wie besehen“ und ohne Gewähr bereitgestellt.'),
    ('Ihre Daten.', 'Ihre Zugangsdaten werden auf Ihrem Gerät gespeichert und nur an die Dienste gesendet, die Sie einrichten.'),
  ],
  closing: 'Mit dem Klick auf „Verstanden und akzeptiert“ bestätigen Sie, diese Bedingungen gelesen zu haben und sie zu akzeptieren. Andernfalls beenden Sie bitte die App.',
  accept: 'Verstanden und akzeptiert',
  quit: 'Beenden',
  close: 'Schließen',
);

const _italian = _LegalText(
  title: 'Avvertenza legale',
  subtitle: 'Da leggere prima di usare Kastideo',
  intro: 'Grazie per aver scelto Kastideo. Kastideo è un lettore multimediale: riproduce playlist (M3U), account IPTV (Xtream Codes), i tuoi server personali (Jellyfin, Emby, Plex), i video dei tuoi dischi e YouTube.',
  points: [
    ('Nessun contenuto fornito.', 'Kastideo non fornisce, non ospita e non vende alcun canale, film, playlist o abbonamento.'),
    ('Nessuna affiliazione.', 'Kastideo non è affiliato ad alcun fornitore di contenuti o di abbonamenti IPTV, né a YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple o Microsoft. I marchi citati appartengono ai rispettivi proprietari. Questo prodotto utilizza l\'API di TMDB, ma non è approvato né certificato da TMDB.'),
    ('I tuoi contenuti.', 'Devi fornire le tue sorgenti e i tuoi contenuti. Sei l\'unico responsabile della verifica che siano legali e che tu disponga di tutti i diritti necessari per guardarli, registrarli, scaricarli e trasmetterli.'),
    ('Diritto d\'autore.', 'Kastideo non incoraggia la diffusione di contenuti protetti dal diritto d\'autore senza l\'autorizzazione dei titolari. Le registrazioni, i download e la trasmissione su un televisore (Cast) sono riservati all\'uso privato, nei limiti della legge del tuo paese.'),
    ('Responsabilità.', 'L\'autore di Kastideo non è responsabile dell\'uso che fai del software, né del contenuto, della disponibilità o della legalità dei servizi di terze parti a cui lo colleghi. Kastideo è fornito gratuitamente, «così com\'è», senza garanzia.'),
    ('I tuoi dati.', 'Le tue credenziali sono conservate sul tuo dispositivo e vengono inviate solo ai servizi che configuri.'),
  ],
  closing: 'Facendo clic su «Ho capito e accetto», confermi di aver letto queste condizioni e di accettarle. In caso contrario, chiudi l\'applicazione.',
  accept: 'Ho capito e accetto',
  quit: 'Esci',
  close: 'Chiudi',
);

const _portugueseBR = _LegalText(
  title: 'Aviso legal',
  subtitle: 'Para ler antes de usar o Kastideo',
  intro: 'Obrigado por usar o Kastideo. O Kastideo é um player de mídia: ele reproduz playlists (M3U), contas IPTV (Xtream Codes), seus servidores pessoais (Jellyfin, Emby, Plex), os vídeos dos seus discos e o YouTube.',
  points: [
    ('Nenhum conteúdo fornecido.', 'O Kastideo não fornece, não hospeda nem vende nenhum canal, filme, playlist ou assinatura.'),
    ('Nenhuma afiliação.', 'O Kastideo não é afiliado a nenhum provedor de conteúdos ou de assinaturas IPTV, nem ao YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. As marcas citadas pertencem aos seus respectivos proprietários. Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.'),
    ('Seus próprios conteúdos.', 'Você deve fornecer suas próprias fontes e conteúdos. Você é o único responsável por verificar se eles são legais e se você tem todos os direitos necessários para assisti-los, gravá-los, baixá-los e transmiti-los.'),
    ('Direitos autorais.', 'O Kastideo não incentiva a difusão de conteúdos protegidos por direitos autorais sem a autorização de seus titulares. As gravações, os downloads e a transmissão para uma TV (Cast) são reservados ao uso privado, dentro dos limites da lei do seu país.'),
    ('Responsabilidade.', 'O autor do Kastideo não é responsável pelo uso que você faz do software, nem pelo conteúdo, pela disponibilidade ou pela legalidade dos serviços de terceiros aos quais você o conecta. O Kastideo é fornecido gratuitamente, “como está”, sem garantia.'),
    ('Seus dados.', 'Suas credenciais ficam guardadas no seu dispositivo e só são enviadas aos serviços que você configurar.'),
  ],
  closing: 'Ao clicar em “Entendi e aceito”, você confirma que leu estas condições e as aceita. Caso contrário, feche o aplicativo.',
  accept: 'Entendi e aceito',
  quit: 'Sair',
  close: 'Fechar',
);

const _portuguesePT = _LegalText(
  title: 'Aviso legal',
  subtitle: 'Para ler antes de usar o Kastideo',
  intro: 'Obrigado por usar o Kastideo. O Kastideo é um leitor multimédia: ele reproduz playlists (M3U), contas IPTV (Xtream Codes), os seus servidores pessoais (Jellyfin, Emby, Plex), os vídeos dos seus discos e o YouTube.',
  points: [
    ('Nenhum conteúdo fornecido.', 'O Kastideo não fornece, não aloja nem vende nenhum canal, filme, playlist ou subscrição.'),
    ('Nenhuma afiliação.', 'O Kastideo não é afiliado a nenhum fornecedor de conteúdos ou de subscrições IPTV, nem ao YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. As marcas citadas pertencem aos seus respectivos proprietários. Este produto usa a API do TMDB, mas não é endossado nem certificado pelo TMDB.'),
    ('Os seus próprios conteúdos.', 'Deve fornecer as suas próprias fontes e conteúdos. É o único responsável por verificar se eles são legais e se tem todos os direitos necessários para vê-los, gravá-los, baixá-los e transmiti-los.'),
    ('Direitos de autor.', 'O Kastideo não incentiva a difusão de conteúdos protegidos por direitos de autor sem a autorização dos seus titulares. As gravações, os downloads e a transmissão para uma TV (Cast) são reservados ao uso privado, dentro dos limites da lei do seu país.'),
    ('Responsabilidade.', 'O autor do Kastideo não é responsável pelo uso que faz do software, nem pelo conteúdo, pela disponibilidade ou pela legalidade dos serviços de terceiros aos quais o conecta. O Kastideo é fornecido gratuitamente, “como está”, sem garantia.'),
    ('Os seus dados.', 'As suas credenciais ficam guardadas no seu dispositivo e só são enviadas aos serviços que configurar.'),
  ],
  closing: 'Ao clicar em “Li e aceito”, confirma que leu estas condições e as aceita. Caso contrário, feche o app.',
  accept: 'Li e aceito',
  quit: 'Sair',
  close: 'Fechar',
);

const _french = _LegalText(
  title: 'Avertissement',
  subtitle: 'À lire avant d\'utiliser Kastideo',
  intro: 'Merci d\'utiliser Kastideo. Kastideo est un lecteur multimédia : il lit les listes de lecture (M3U), les comptes IPTV (Xtream Codes), vos serveurs personnels (Jellyfin, Emby, Plex), les vidéos de vos disques et YouTube.',
  points: [
    (
      'Aucun contenu fourni.',
      'Kastideo ne fournit, n\'héberge ni ne vend aucune chaîne, aucun film, aucune liste de lecture ni aucun abonnement.',
    ),
    (
      'Aucune affiliation.',
      'Kastideo n\'est affilié à aucun fournisseur de contenus ou d\'abonnements IPTV, ni à YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple ou Microsoft. Les marques citées appartiennent à leurs propriétaires. Ce produit utilise l\'API TMDB mais n\'est ni approuvé ni certifié par TMDB.',
    ),
    (
      'Vos propres contenus.',
      'Vous devez fournir vos propres sources et contenus. Vous êtes seul responsable de vérifier qu\'ils sont légaux et que vous avez tous les droits nécessaires pour les regarder, les enregistrer, les télécharger et les diffuser.',
    ),
    (
      'Droit d\'auteur.',
      'Kastideo n\'encourage pas la diffusion de contenus protégés par le droit d\'auteur sans l\'autorisation de leurs titulaires. Les enregistrements, les téléchargements et la diffusion vers un téléviseur (Cast) sont réservés à un usage privé, dans les limites de la loi de votre pays.',
    ),
    (
      'Responsabilité.',
      'L\'auteur de Kastideo n\'est pas responsable de l\'usage que vous faites du logiciel, ni du contenu, de la disponibilité ou de la légalité des services tiers auxquels vous le connectez. Kastideo est fourni gratuitement, « tel quel », sans garantie.',
    ),
    (
      'Vos données.',
      'Vos identifiants sont conservés sur votre appareil et ne sont transmis qu\'aux services que vous configurez.',
    ),
  ],
  closing: 'En cliquant sur « J\'ai compris et j\'accepte », vous reconnaissez avoir lu ces conditions et vous les acceptez. Dans le cas contraire, quittez l\'application.',
  accept: 'J\'ai compris et j\'accepte',
  quit: 'Quitter',
  close: 'Fermer',
);

const _english = _LegalText(
  title: 'Disclaimer',
  subtitle: 'Please read before using Kastideo',
  intro: 'Thank you for using Kastideo. Kastideo is a media player: it plays playlists (M3U), IPTV accounts (Xtream Codes), your own servers (Jellyfin, Emby, Plex), the videos on your drives and YouTube.',
  points: [
    (
      'No content provided.',
      'Kastideo does not provide, host or sell any channel, movie, playlist or subscription.',
    ),
    (
      'No affiliation.',
      'Kastideo is not affiliated with any content or IPTV subscription provider, nor with YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple or Microsoft. Trademarks mentioned belong to their respective owners. This product uses the TMDB API but is not endorsed or certified by TMDB.',
    ),
    (
      'Your own content.',
      'You must supply your own sources and content. You are solely responsible for checking that they are legal and that you have all the rights needed to watch, record, download and stream them.',
    ),
    (
      'Copyright.',
      'Kastideo does not encourage the streaming of copyright-protected material without the permission of the copyright holder. Recordings, downloads and casting to a TV are for private use only, within the limits of the law in your country.',
    ),
    (
      'Liability.',
      'The author of Kastideo is not responsible for how you use the software, nor for the content, availability or legality of the third-party services you connect it to. Kastideo is provided free of charge, “as is”, without warranty.',
    ),
    (
      'Your data.',
      'Your credentials are kept on your device and are only sent to the services you configure.',
    ),
  ],
  closing: 'By clicking “I understand and accept”, you confirm that you have read and accept these terms. Otherwise, please quit the application.',
  accept: 'I understand and accept',
  quit: 'Quit',
  close: 'Close',
);

class LegalNotice {
  static const acceptedKey = 'legal.acceptedVersion';

  /// Affiche l'avertissement tant qu'il n'a pas été accepté pour cette version (quitte l'application en cas de refus).
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(acceptedKey) == kVersion || !context.mounted) return;
    final accepted = await show(context, requireAcceptance: true);
    if (accepted == true) {
      await prefs.setString(acceptedKey, kVersion);
    } else {
      exit(0);
    }
  }

  /// Fenêtre de l'avertissement. Avec [requireAcceptance] : « J'ai compris et j'accepte » ou « Quitter » ; sinon relecture simple.
  static Future<bool?> show(
    BuildContext context, {
    bool requireAcceptance = false,
  }) {
    final text = switch (L10n.lang) {
      'fr' => _french,
      'es' => _spanish,
      'de' => _german,
      'it' => _italian,
      'pt-BR' => _portugueseBR,
      'pt-PT' => _portuguesePT,
      _ => _english,
    };
    return showKDialog<bool>(
      context: context,
      barrierDismissible: !requireAcceptance,
      builder: (c) => PopScope(
        canPop: !requireAcceptance,
        child: AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.title, style: kText(20, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                text.subtitle,
                style: kText(13, color: KPalette.secondaryText),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.intro, style: kText(14)),
                  for (final point in text.points) ...[
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: point.$1,
                            style: kText(14, weight: FontWeight.w700),
                          ),
                          TextSpan(text: ' ${point.$2}', style: kText(14)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(text.closing, style: kText(14, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          actions: requireAcceptance
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(text.quit),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(text.accept),
                  ),
                ]
              : [
                  FilledButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(text.close),
                  ),
                ],
        ),
      ),
    );
  }
}
