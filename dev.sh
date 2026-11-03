#!/usr/bin/env bash
# Point d'entrée unique : tous les outils tournent dans Docker, rien n'est installé sur la machine.
set -euo pipefail
cd "$(dirname "$0")"

export HOST_UID="$(id -u)"
export HOST_GID="$(id -g)"

usage() {
  cat <<'EOF'
Usage : ./dev.sh <commande>

  build     Construit l'image Docker des outils
  check     Vérifie la syntaxe Lua 5.1 et lance luacheck
  test      Lance les tests (API WoW simulée)
  package [version]  Crée l'archive .release/ProfilBarres-<version>.zip (défaut : dev)
  deploy    Copie l'addon dans le dossier AddOns du jeu (WOW_ADDONS_DIR dans .env)
  shell     Ouvre un shell dans le conteneur d'outils
EOF
}

case "${1:-}" in
  build)   docker compose build tools ;;
  check)   docker compose run --rm tools sh scripts/check.sh ;;
  test)    docker compose run --rm tools sh scripts/test.sh ;;
  package) docker compose run --rm tools sh scripts/package.sh "${2:-dev}" ;;
  deploy)
    if [ ! -f .env ]; then
      echo "Fichier .env absent : copier .env.example en .env et renseigner WOW_ADDONS_DIR." >&2
      exit 1
    fi
    docker compose run --rm deploy ;;
  shell)   docker compose run --rm tools bash ;;
  *)       usage ;;
esac
