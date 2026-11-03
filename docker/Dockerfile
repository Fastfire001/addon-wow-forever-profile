# Outils de développement de l'addon : Lua 5.1 (même version que le client WoW),
# luacheck (analyse statique), zip/unzip (packaging) et rsync (déploiement).
FROM debian:bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      lua5.1 \
      lua-check \
      zip \
      unzip \
      rsync \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
