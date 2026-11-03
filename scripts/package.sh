#!/bin/sh
# Exécuté dans le conteneur : crée .release/ProfilBarres-<version>.zip, avec le
# dossier ProfilBarres/ à la racine de l'archive. Le TOC de l'archive reçoit la
# version à la place de @project-version@ (le dépôt garde le placeholder).
#
# Usage : sh scripts/package.sh [version]   (ex. v0.2.0 ou 0.2.0 ; défaut : dev)
set -eu

ADDON_DIR="ProfilBarres"
TOC_NAME="$ADDON_DIR.toc"

if [ ! -f "$ADDON_DIR/$TOC_NAME" ]; then
  echo "Fichier $ADDON_DIR/$TOC_NAME introuvable." >&2
  exit 1
fi

VERSION="${1:-dev}"
VERSION="${VERSION#v}"   # tag v0.2.0 -> 0.2.0
case "$VERSION" in
  ''|*[!0-9A-Za-z.+-]*)
    echo "Version invalide : « $VERSION » (caractères autorisés : 0-9 A-Z a-z . + -)." >&2
    exit 1 ;;
esac

if ! grep -q '^## Version: @project-version@' "$ADDON_DIR/$TOC_NAME"; then
  echo "Le TOC doit contenir « ## Version: @project-version@ »." >&2
  exit 1
fi

STAGE=".release/stage"
OUT=".release/$ADDON_DIR-$VERSION.zip"
rm -rf "$STAGE" "$OUT"
mkdir -p "$STAGE"
cp -r "$ADDON_DIR" "$STAGE/"
find "$STAGE" \( -name '.DS_Store' -o -name '.git*' \) -exec rm -rf {} +
sed -i "s/@project-version@/$VERSION/g" "$STAGE/$ADDON_DIR/$TOC_NAME"

(cd "$STAGE" && zip -rq "../$ADDON_DIR-$VERSION.zip" "$ADDON_DIR")
rm -rf "$STAGE"

# Vérification de l'archive : TOC à la bonne place, version inscrite.
TOC_VERSION=$(unzip -p "$OUT" "$ADDON_DIR/$TOC_NAME" | sed -n 's/^## Version:[[:space:]]*//p' | tr -d '\r')
if [ "$TOC_VERSION" != "$VERSION" ]; then
  echo "Archive invalide : version du TOC « $TOC_VERSION », attendu « $VERSION »." >&2
  exit 1
fi

echo "Archive créée : $OUT (version $TOC_VERSION)"
unzip -Z1 "$OUT" | sed 's/^/  /'
