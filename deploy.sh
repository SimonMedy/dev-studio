#!/usr/bin/env bash
set -Eeuo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

echo "Construction de la nouvelle image..."
sudo docker compose build \
    --pull \
    --build-arg AI_TOOLS_CACHE_BUST="$(date +%s)"

echo "Recréation des conteneurs..."
sudo docker compose up -d --force-recreate

echo "Vérification des services..." 
sudo docker compose ps

echo "Nettoyage des anciennes images..."
sudo docker image prune -f

echo "✅ Dev Studio est à jour et fonctionnel !"