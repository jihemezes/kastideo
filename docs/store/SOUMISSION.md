# Soumission à l'App Store — iPhone, iPad et Apple TV

Le Mac reste distribué hors de l'App Store (DMG signé, Sparkle). Cette liste concerne **iPhone/iPad** et **Apple TV** (même app « fr.jmezes.kastideo », deux plateformes).

## 0. Déjà fait dans l'app
- Aucun lien de don (Ko-fi) dans les apps iPhone/iPad et Apple TV, ni dans leur aide.
- Bouton **Essayer la démo** à l'accueil (iPhone/iPad) et sur l'écran de bienvenue (Apple TV) : l'examinateur teste sans abonnement.
- Avertissement légal au premier lancement, aucun contenu fourni, aucun achat intégré, aucun compte, aucune publicité.
- Textes d'autorisation (réseau local, galerie), `ITSAppUsesNonExemptEncryption = false`.
- Fiches `appstore-{fr,en,es,de,it,pt}.md`, politique de confidentialité `../PRIVACY.md`, playlist `demo.m3u`.

## 1. Avant de soumettre
1. **Page de confidentialité en ligne** : https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md (ou la page Confidentialité de kastideo.com, de préférence : une URL de site est mieux vue qu'un fichier GitHub).
2. **URL d'assistance** : https://kastideo.com ; **e-mail** : contact@kastideo.com.
3. **Captures** : iPhone 6,9" et iPad 13" (Actions > « iOS (captures d'écran) »), Apple TV 4K (Actions > « tvOS (captures d'écran) »). Gardez 3 à 5 images par appareil, sans nom de chaîne ni service payant.
4. Un build **TestFlight récent** et testé sur chaque plateforme (le build soumis est choisi dans la fiche).

## 2. App Store Connect > Kastideo > fiche de la version
| Rubrique | Réponse conseillée |
|---|---|
| Nom / sous-titre / description / mots-clés | `appstore-xx.md` (une langue à la fois ; renseignez au moins fr, en) |
| Catégorie | Divertissement (secondaire : Photo et vidéo) |
| Prix | **Gratuit**, tous les pays ; aucun achat intégré |
| Connexion requise pour la revue | **Non** (aucun compte) |
| Notes pour l'examinateur | Coller `review-notes-en.md` |
| Contact de la revue | Vos coordonnées (nom, e-mail, téléphone) |
| Publication de la version | « Manuelle » pour la première version (vous choisissez le jour) |

## 3. Confidentialité de l'app (« App Privacy »)
- **Collecte de données** : *Data Not Collected* (l'éditeur ne reçoit rien).
- **Suivi (tracking)** : Non.
- Les connexions vers le fournisseur de l'utilisateur, TMDB et YouTube se font à sa demande, directement depuis l'appareil : ce n'est pas une collecte par l'éditeur.

## 4. Classification d'âge
Répondez **honnêtement** au questionnaire. Kastideo lit des sources choisies par l'utilisateur (contenus non filtrés possibles) : attendez-vous à la classification la plus haute (17+/18+ selon le nouveau barème). Ne cochez rien de plus que la réalité : une réponse inexacte est un motif de refus.

## 5. Chiffrement (conformité à l'exportation)
HTTPS et chiffrement standard du système uniquement : **exempt** (déjà déclaré dans l'app).

## 6. Apple TV
- Ajoutez la plateforme tvOS à la même fiche (fait en novembre 2026), sa propre description facultative, ses captures 3840×2160 ou 1920×1080.
- Notes d'examen : l'écran de bienvenue propose **Essayer la démo** (pas besoin de saisir d'adresse à la télécommande).

## 7. Soumettre et suivre
1. Choisir le build, remplir les captures et notes, **Ajouter pour examen**.
2. Délai habituel : 24 à 48 h. Un premier refus est fréquent pour les lecteurs IPTV : répondez avec `review-responses-en.md`, sans modifier l'app tant que le motif n'est pas précisé.
3. Après acceptation : publier manuellement, puis annoncer sur le site et le README (liens App Store).

## 8. À ne pas faire
- Aucune mention de chaînes, de bouquets ou de fournisseurs précis dans la fiche, les captures ou les notes.
- Ne promettez pas de « gratuit pour toujours ».
- Ne pas ajouter de lien de don, de lien de téléchargement externe ni d'indice sur la manière de trouver des abonnements.
