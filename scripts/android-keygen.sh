#!/bin/bash
# Crée la clé de signature des APK Kastideo (une seule fois pour toute la vie de l'application).
# À lancer sur le Mac depuis le dossier ~/Documents/kastideo :   bash scripts/android-keygen.sh
#
# Ce que fait le script :
#   1. génère un fichier de clé (kastideo-release.jks) et des mots de passe aléatoires ;
#   2. les range dans ~/kastideo-android-key/ ;
#   3. enregistre les 4 secrets dans GitHub (commande « gh »), ou affiche quoi saisir à la main.
#
# IMPORTANT : sauvegardez le dossier ~/kastideo-android-key/ (gestionnaire de mots de passe, disque externe).
# Sans cette clé, plus aucune mise à jour ne pourra s'installer par-dessus Kastideo : il faudrait le désinstaller.
set -euo pipefail

DIR="$HOME/kastideo-android-key"
JKS="$DIR/kastideo-release.jks"
ALIAS="kastideo"
REPO="jihemezes/kastideo"

if ! command -v keytool >/dev/null 2>&1 || ! keytool -help >/dev/null 2>&1; then
  echo "keytool (Java) est introuvable. Installez Java une fois :"
  echo "    brew install --cask temurin@17"
  echo "puis relancez ce script."
  exit 1
fi

if [ -f "$JKS" ]; then
  echo "Une clé existe déjà : $JKS"
  echo "Elle n'est PAS remplacée (une nouvelle clé empêcherait les mises à jour)."
  echo "Pour republier les secrets GitHub avec cette clé, lisez $DIR/secrets.txt."
  exit 1
fi

mkdir -p "$DIR"
chmod 700 "$DIR"
PASS="$(openssl rand -base64 36 | tr -dc 'A-Za-z0-9' | cut -c1-24)"

keytool -genkeypair -v \
  -keystore "$JKS" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 36500 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=Kastideo, OU=Kastideo, O=Kastideo, C=FR"

base64 -i "$JKS" | tr -d '\n' > "$DIR/keystore.base64.txt"
cat > "$DIR/secrets.txt" <<EOF
ANDROID_KEYSTORE_BASE64  = contenu du fichier keystore.base64.txt
ANDROID_KEYSTORE_PASSWORD = $PASS
ANDROID_KEY_ALIAS         = $ALIAS
ANDROID_KEY_PASSWORD      = $PASS
EOF
chmod 600 "$DIR/secrets.txt" "$DIR/keystore.base64.txt" "$JKS"

echo
echo "Clé créée : $JKS"
echo "Empreinte (SHA-256) de la clé :"
keytool -list -v -keystore "$JKS" -storepass "$PASS" | grep "SHA256:" | head -1

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo
  echo "Enregistrement des 4 secrets dans GitHub ($REPO)…"
  gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO" < "$DIR/keystore.base64.txt"
  gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPO" --body "$PASS"
  gh secret set ANDROID_KEY_ALIAS --repo "$REPO" --body "$ALIAS"
  gh secret set ANDROID_KEY_PASSWORD --repo "$REPO" --body "$PASS"
  echo "Secrets enregistrés."
else
  echo
  echo "La commande « gh » n'est pas disponible : ajoutez les 4 secrets à la main."
  echo "  GitHub > $REPO > Settings > Secrets and variables > Actions > New repository secret"
  echo "  Les valeurs sont dans : $DIR/secrets.txt (le premier : collez le contenu de keystore.base64.txt)."
fi
echo
echo "N'oubliez pas de SAUVEGARDER le dossier $DIR."
