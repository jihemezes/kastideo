#!/bin/bash
# kastideo-release — intègre un zip livré par Claude et publie la version sur GitHub.
#
# Usage :
#   kastideo-release <version> ["descriptif"] [-y]
#
# Exemples :
#   kastideo-release 0.2.0 "Moteur de lecture étendu"
#   kastideo-release 0.2.0            # descriptif lu dans CHANGELOG.md
#   kastideo-release 0.3.0-beta1 "Test du nouveau lecteur"   # version de test (canal bêta)
#
# Fait la même chose que le bloc de mise à jour habituel, avec des vérifications :
#   zip présent, structure kastideo/ correcte, tag inexistant, version cohérente avec project.yml,
#   récapitulatif des fichiers modifiés et confirmation avant commit / tag / push.
#
# Tout le script est dans une fonction : il peut se mettre à jour lui-même pendant son exécution.

main() {
    set -euo pipefail

    local REPO="${KASTIDEO_REPO:-$HOME/Documents/kastideo}"
    local DOWNLOADS="${KASTIDEO_DOWNLOADS:-$HOME/Downloads}"
    local GITHUB_URL="https://github.com/jihemezes/kastideo"

    local bold=$'\033[1m' red=$'\033[31m' green=$'\033[32m' yellow=$'\033[33m' reset=$'\033[0m'
    die()  { echo "${red}✖ $*${reset}" >&2; exit 1; }
    info() { echo "${bold}▸ $*${reset}"; }
    ok()   { echo "${green}✔ $*${reset}"; }
    warn() { echo "${yellow}⚠ $*${reset}"; }

    local VERSION="" MESSAGE="" ASSUME_YES=0
    for arg in "$@"; do
        case "$arg" in
            -y|--yes) ASSUME_YES=1 ;;
            -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
            *) if [ -z "$VERSION" ]; then VERSION="$arg"; elif [ -z "$MESSAGE" ]; then MESSAGE="$arg"; fi ;;
        esac
    done

    [ -n "$VERSION" ] || die "Version manquante. Usage : kastideo-release 0.2.0 \"Descriptif\""
    VERSION="${VERSION#v}"
    [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-beta[0-9]+)?$ ]] || die "Version invalide « $VERSION » (format attendu : X.Y.Z ou X.Y.Z-betaN)."
    local BASE_VERSION="${VERSION%%-*}"

    local ZIP="$DOWNLOADS/kastideo-v$VERSION.zip"
    local TMP="/tmp/kastideo-$VERSION"

    [ -d "$REPO/.git" ] || die "Dépôt Git introuvable : $REPO"
    [ -f "$ZIP" ] || die "Zip introuvable : $ZIP"
    cd "$REPO"

    info "Vérification du tag v$VERSION"
    git fetch --tags --quiet origin || warn "Impossible de joindre GitHub pour vérifier les tags distants."
    if git rev-parse -q --verify "refs/tags/v$VERSION" > /dev/null; then
        die "Le tag v$VERSION existe déjà. Choisissez une nouvelle version."
    fi

    if [ -n "$(git status --porcelain)" ]; then
        warn "Le dépôt contient des modifications locales non commitées :"
        git status --short
        warn "Elles seront incluses dans le commit de la version $VERSION."
    fi

    info "Décompression de $(basename "$ZIP")"
    rm -rf "$TMP"
    ditto -x -k "$ZIP" "$TMP"
    [ -d "$TMP/kastideo" ] || die "Structure inattendue : le zip doit contenir un dossier racine « kastideo/»."

    local ZIP_VERSION
    ZIP_VERSION=$(grep -E '^[[:space:]]*MARKETING_VERSION:' "$TMP/kastideo/project.yml" 2>/dev/null | head -1 | sed -E 's/.*"?([0-9]+\.[0-9]+\.[0-9]+)"?.*/\1/' || true)
    if [ -n "$ZIP_VERSION" ] && [ "$ZIP_VERSION" != "$BASE_VERSION" ]; then
        warn "project.yml du zip indique la version $ZIP_VERSION (vous publiez $VERSION)."
    fi
    if [ "$VERSION" != "$BASE_VERSION" ]; then
        info "Version de test : publiée en pré-version et sur le canal bêta de Sparkle."
    fi

    if [ -z "$MESSAGE" ] && [ -f "$TMP/kastideo/CHANGELOG.md" ]; then
        MESSAGE=$(awk -v v="$VERSION" '
            $0 ~ "^## \\[?" v "\\]?([ ]|$)" { found=1; next }
            found && /^## / { exit }
            found && /^- / { sub(/^- /, ""); print; exit }
        ' "$TMP/kastideo/CHANGELOG.md")
    fi
    [ -n "$MESSAGE" ] || MESSAGE="Mise à jour de Kastideo"

    info "Copie des fichiers dans $REPO"
    cp -R "$TMP/kastideo/." .

    echo
    git status --short
    echo
    echo "Commit : ${bold}$VERSION - $MESSAGE${reset}"
    echo "Tag    : ${bold}v$VERSION${reset}"
    echo

    if [ "$ASSUME_YES" -ne 1 ]; then
        local answer
        read -r -p "Publier cette version sur GitHub ? [o/N] " answer
        case "$answer" in
            o|O|oui|OUI|y|Y) ;;
            *) warn "Publication annulée. Les fichiers copiés restent en place (git status pour les voir)."; exit 0 ;;
        esac
    fi

    git add -A
    git commit -m "$VERSION - $MESSAGE"
    git tag "v$VERSION"
    git push
    git push origin "v$VERSION"
    rm -rf "$TMP"

    echo
    ok "Version $VERSION publiée."
    echo "  Compilation et DMG : $GITHUB_URL/actions"
    echo "  Release (≈ 10 min) : $GITHUB_URL/releases/tag/v$VERSION"
}

main "$@"; exit $?
