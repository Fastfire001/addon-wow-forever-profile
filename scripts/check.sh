#!/bin/sh
# Exécuté dans le conteneur : vérification de la syntaxe Lua 5.1, puis luacheck.
set -eu

ADDON_DIR="ProfilBarres"

if [ ! -d "$ADDON_DIR" ]; then
  echo "Dossier $ADDON_DIR/ absent : rien à vérifier."
  exit 0
fi

echo "== Syntaxe (luac5.1 -p) =="
status=0
for f in $(find "$ADDON_DIR" -name '*.lua' | sort); do
  if ! luac5.1 -p "$f"; then status=1; fi
done
[ "$status" -eq 0 ] && echo "OK"

echo "== luacheck =="
luacheck "$ADDON_DIR" || status=1

exit "$status"
