#!/bin/sh
# Exécuté dans le conteneur : tests de la logique contre l'API WoW simulée.
set -eu
lua5.1 tests/run.lua
