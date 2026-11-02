#!/bin/sh
# Exécuté dans le conteneur : crée .release/ProfilBarres-<version>.zip
# (le dossier ProfilBarres/ à la racine de l'archive).
set -eu

ADDON_DIR="ProfilBarres"
TOC="$ADDON_DIR/$ADDON_DIR.toc"

if [ ! -f "$TOC" ]; then
  echo "Fichier $TOC introuvable." >&2
  exit 1
fi

VERSION=$(sed -n 's/^## Version:[[:space:]]*//p' "$TOC" | tr -d '\r' | head -n1)
VERSION=${VERSION:-dev}

mkdir -p .release
OUT=".release/$ADDON_DIR-$VERSION.zip"
rm -f "$OUT"
zip -rq "$OUT" "$ADDON_DIR" -x '*.DS_Store' '*/.git*'
echo "Archive créée : $OUT"
