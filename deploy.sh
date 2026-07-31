#!/usr/bin/env bash
set -Eeuo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

echo "Construction de la nouvelle image..."
sudo docker compose build --pull

echo "Recréation du conteneur..."
sudo docker compose up -d --force-recreate

echo "Vérification du service..."
sudo docker compose ps

echo "Nettoyage des anciennes images..."
sudo docker image prune -f

echo "✅ Dev Studio est à jour et fonctionnel !"