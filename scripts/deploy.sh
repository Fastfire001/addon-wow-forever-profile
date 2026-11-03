#!/bin/sh
# Exécuté dans le conteneur : copie ProfilBarres/ dans le dossier AddOns du jeu
# (monté sur /wow-addons depuis WOW_ADDONS_DIR).
set -eu

ADDON_DIR="ProfilBarres"
TARGET="/wow-addons"

if [ ! -d "$ADDON_DIR" ]; then
  echo "Dossier $ADDON_DIR/ absent : rien à déployer." >&2
  exit 1
fi
if [ ! -d "$TARGET" ] || [ ! -w "$TARGET" ]; then
  echo "Dossier cible inaccessible en écriture. Vérifie WOW_ADDONS_DIR dans .env." >&2
  exit 1
fi

rsync -rt --delete "$ADDON_DIR/" "$TARGET/$ADDON_DIR/"
# version affichée en jeu pour une copie de développement
sed -i "s/@project-version@/dev/g" "$TARGET/$ADDON_DIR/$ADDON_DIR.toc"
echo "Déployé dans WOW_ADDONS_DIR/$ADDON_DIR. Faire /reload en jeu."
