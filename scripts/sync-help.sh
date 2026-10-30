#!/bin/bash
# Copie l'aide (source unique : docs/help) vers la version Windows / Linux.
# À lancer depuis la racine du dépôt après toute modification de docs/help.
set -e
cd "$(dirname "$0")/.."
rm -rf desktop/assets/help
mkdir -p desktop/assets/help/img
cp docs/help/aide-fr.md docs/help/aide-en.md desktop/assets/help/
cp docs/help/img/*.png desktop/assets/help/img/
echo "Aide synchronisée : $(ls desktop/assets/help | wc -l) éléments dans desktop/assets/help"
