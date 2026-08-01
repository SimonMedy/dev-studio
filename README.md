# Dev Studio

Environnement de développement accessible depuis un navigateur, construit autour de LinuxServer code-server.

Il fournit un espace de travail complet avec des assistants IA et un moteur Docker de développement isolé du moteur Docker principal de l’hôte.

## Fonctionnalités principales

Dev Studio inclut notamment :

- code-server ;
- Node.js 24 LTS ;
- npm ;
- pnpm ;
- Python 3 ;
- OpenJDK 17 ;
- Git ;
- OpenCode ;
- OpenAI Codex CLI ;
- Bubblewrap pour le sandbox Codex ;
- Docker CLI ;
- Docker Compose ;
- Docker Buildx ;
- outils de compilation natifs.

Un démon Docker rootless séparé permet à OpenCode, Codex et au terminal intégré de :

- construire des images ;
- lancer des projets Docker Compose ;
- consulter les logs ;
- redémarrer des services ;
- exécuter des commandes dans les conteneurs de développement.

Ce démon ne donne pas accès au moteur Docker principal de la machine hôte.

## Architecture

```text
Docker principal
├── dev-studio
│   ├── code-server
│   ├── OpenCode
│   ├── Codex CLI
│   └── client Docker
│
├── dev-docker-init
│   └── initialise les permissions des volumes
│
└── dev-docker
    ├── démon Docker rootless
    ├── images de développement
    ├── conteneurs de développement
    ├── volumes de développement
    └── cache BuildKit
```

La communication entre `dev-studio` et `dev-docker` utilise TLS sur le réseau Docker interne.

Le socket Docker principal de l’hôte n’est pas monté dans `dev-studio`.

## Structure du dépôt

```text
dev-studio/
├── Dockerfile
├── compose.yaml
├── deploy.sh
├── README.md
├── LICENSE
├── .gitignore
└── .dockerignore
```

Le fichier `.env` est créé localement et ne doit pas être versionné.

## Prérequis

- Docker ;
- Docker Compose v2 ;
- un système Linux compatible avec les chemins `/DATA` ;
- une architecture `amd64` ;
- le support nécessaire à Docker-in-Docker rootless ;
- Tailscale, uniquement pour l’accès HTTPS privé à distance.

Ce projet est principalement prévu pour ZimaOS.

Il est lancé directement avec Docker Compose, sans passer par l’interface d’applications ZimaOS.

## Services Docker Compose

Le projet utilise trois services.

### `certs-init`

Service temporaire chargé d’initialiser les permissions des volumes utilisés par Docker rootless.

Il se termine normalement avec le statut :

```text
Exited (0)
```

### `dev-docker`

Démon Docker rootless dédié aux projets de développement.

Il conserve :

- les images ;
- les conteneurs ;
- les volumes ;
- le cache BuildKit ;
- les certificats TLS.

Il fonctionne indépendamment du moteur Docker principal de la machine hôte.

### `app`

Conteneur principal nommé `dev-studio`.

Il contient :

- code-server ;
- les outils de développement ;
- OpenCode ;
- Codex CLI ;
- le client Docker ;
- Docker Compose ;
- Docker Buildx.

Le client Docker communique uniquement avec `dev-docker`.

## Stockage persistant

### Données présentes sur l’hôte

```text
/DATA/AppData/dev-studio/config
/DATA/Workspace
```

Correspondance dans `dev-studio` :

```text
/DATA/AppData/dev-studio/config -> /config
/DATA/Workspace                  -> /config/workspace
```

Le dossier `/config` contient notamment :

- la configuration de code-server ;
- les extensions ;
- les préférences utilisateur ;
- les configurations et authentifications des outils ;
- les données persistantes de l’environnement.

Les projets sont stockés séparément dans :

```text
/DATA/Workspace
```

### Volumes Docker nommés

Le projet crée également :

```text
dev-studio_dev-docker-data
dev-studio_dev-docker-certs
```

`dev-docker-data` contient :

- les images du Docker de développement ;
- ses conteneurs ;
- ses volumes ;
- son cache de construction.

`dev-docker-certs` contient les certificats TLS utilisés entre `dev-studio` et `dev-docker`.

Ces données persistent après :

```bash
sudo docker compose down
```

Elles sont en revanche supprimées avec :

```bash
sudo docker compose down -v
```

Ne pas utiliser `-v` sauf si la réinitialisation complète du Docker de développement est volontaire.

## Configuration

Créer un fichier `.env` à la racine du projet :

```dotenv
CODE_SERVER_PASSWORD=REMPLACER_PAR_UN_MOT_DE_PASSE_SOLIDE
SUDO_PASSWORD=REMPLACER_PAR_UN_AUTRE_MOT_DE_PASSE_SOLIDE
```

Protéger le fichier :

```bash
chmod 600 .env
```

Le fichier `.env` ne doit jamais être ajouté au dépôt Git.

`CODE_SERVER_PASSWORD` est obligatoire.

`SUDO_PASSWORD` peut être laissé vide si l’accès à `sudo` depuis le terminal intégré n’est pas nécessaire :

```dotenv
CODE_SERVER_PASSWORD=REMPLACER_PAR_UN_MOT_DE_PASSE_SOLIDE
SUDO_PASSWORD=
```

## Installation et déploiement

Le script `deploy.sh` peut être utilisé pour le premier lancement comme pour les mises à jour suivantes.

Le rendre exécutable lors de la première utilisation :

```bash
chmod +x deploy.sh
```

Construire l’image et démarrer l’environnement :

```bash
./deploy.sh
```

Le script effectue les opérations suivantes :

```bash
sudo docker compose build \
  --pull \
  --build-arg AI_TOOLS_CACHE_BUST="$(date +%s)"

sudo docker compose up -d --force-recreate
sudo docker compose ps
sudo docker image prune -f
```

Le paramètre `AI_TOOLS_CACHE_BUST` force la vérification et la réinstallation des dernières versions de :

- pnpm ;
- OpenCode ;
- OpenAI Codex CLI.

Les couches plus stables, comme Node.js, Java et le client Docker, restent normalement en cache.

## État attendu

Après un déploiement réussi :

```bash
sudo docker compose ps -a
```

doit afficher un résultat similaire à :

```text
dev-docker-init   Exited (0)
dev-docker        Up (...) (healthy)
dev-studio        Up (...)
```

Le service `dev-docker-init` n’a pas vocation à rester actif.

## Commandes utiles

Afficher l’état des services :

```bash
sudo docker compose ps -a
```

Afficher tous les journaux en temps réel :

```bash
sudo docker compose logs -f
```

Afficher les logs de Dev Studio :

```bash
sudo docker logs --tail 100 dev-studio
```

Afficher les logs du Docker de développement :

```bash
sudo docker logs --tail 100 dev-docker
```

Redémarrer les services :

```bash
sudo docker compose restart
```

Arrêter les services sans les supprimer :

```bash
sudo docker compose stop
```

Relancer les services arrêtés :

```bash
sudo docker compose start
```

Arrêter et supprimer les conteneurs et le réseau Compose :

```bash
sudo docker compose down
```

Cette commande ne supprime pas :

- `/DATA/AppData/dev-studio/config` ;
- `/DATA/Workspace` ;
- les volumes Docker nommés.

## Utilisation de Docker dans Dev Studio

Depuis le terminal intégré de code-server :

```bash
docker version
docker info
docker ps
```

La sortie de `docker version` doit contenir une section `Client` et une section `Server`.

Le serveur doit correspondre au démon `dev-docker`, et non au moteur Docker principal.

Test simple :

```bash
docker run --rm hello-world
```

Exemples d’opérations disponibles :

```bash
docker compose build
docker compose up -d
docker compose ps
docker compose logs
docker compose restart
docker exec
docker inspect
docker compose down
```

Les conteneurs créés par ces commandes sont stockés dans le Docker de développement.

Ils n’apparaissent pas avec la commande exécutée sur l’hôte :

```bash
sudo docker ps
```

Pour voir les conteneurs de développement depuis l’hôte :

```bash
sudo docker exec --user abc dev-studio docker ps
```

## Chemins et bind mounts

Le workspace est monté au même chemin dans `dev-studio` et `dev-docker` :

```text
/config/workspace
```

Cette correspondance est nécessaire pour que les bind mounts relatifs utilisés par Docker Compose fonctionnent correctement.

Par exemple, un projet situé dans :

```text
/DATA/Workspace/Projets/MonProjet
```

est visible dans les deux services sous :

```text
/config/workspace/Projets/MonProjet
```

## Accès aux ports des projets

Les ports publiés par les conteneurs du Docker imbriqué sont exposés sur `dev-docker`, pas automatiquement sur le NAS.

Par exemple :

```yaml
ports:
  - "5173:5173"
```

rend le service accessible depuis `dev-studio` avec :

```text
http://dev-docker:5173
```

Pour accéder à ce port directement depuis le LAN ou un navigateur externe, il faut également publier le port correspondant sur le service `dev-docker` dans le `compose.yaml` principal.

## Accès local à code-server

Accès avec le nom du serveur :

```text
http://nom-du-serveur:8443
```

Accès avec l’adresse IP locale :

```text
http://adresse-ip-du-serveur:8443
```

Le navigateur demande le mot de passe défini dans :

```dotenv
CODE_SERVER_PASSWORD=
```

## Accès HTTPS privé avec Tailscale Serve

Configurer Tailscale Serve :

```bash
sudo tailscale serve --bg http://127.0.0.1:8443
```

Vérifier son état :

```bash
sudo tailscale serve status
```

Tailscale affiche une URL HTTPS privée semblable à :

```text
https://nom-du-serveur.votre-tailnet.ts.net/
```

Désactiver Tailscale Serve :

```bash
sudo tailscale serve --https=443 off
```

Tailscale Serve reste privé au tailnet.

Ne pas utiliser Tailscale Funnel sauf si une exposition publique à Internet est volontaire.

## Mise à jour

Pour actualiser l’image de base, OpenCode, Codex et les autres outils concernés :

```bash
./deploy.sh
```

Le script conserve :

```text
/DATA/AppData/dev-studio/config
/DATA/Workspace
dev-studio_dev-docker-data
dev-studio_dev-docker-certs
```

## Reconstruction complète de l’image

Pour ignorer entièrement le cache de construction :

```bash
sudo docker compose build --pull --no-cache
sudo docker compose up -d --force-recreate
```

Cette opération reconstruit l’image `dev-studio`, mais ne supprime pas les volumes persistants.

## Réinitialisation du Docker de développement

Pour supprimer toutes les images, tous les conteneurs, tous les volumes et tous les certificats du Docker de développement :

```bash
sudo docker compose down -v
./deploy.sh
```

Cette opération ne supprime pas `/DATA/Workspace`, mais supprime entièrement l’état interne de `dev-docker`.

## Vérification des outils

Depuis le terminal intégré :

```bash
node --version
npm --version
pnpm --version
python3 --version
java -version
git --version
bwrap --version
opencode --version
codex --version
docker --version
docker compose version
docker buildx version
```

## Vérification du workspace

```bash
touch /config/workspace/test-write
ls -l /config/workspace/test-write
rm /config/workspace/test-write
```

## Vérification des montages

Afficher les montages de `dev-studio` :

```bash
sudo docker inspect dev-studio \
  --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
```

Afficher les montages de `dev-docker` :

```bash
sudo docker inspect dev-docker \
  --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
```

## Ressources Docker

Afficher la consommation CPU et mémoire :

```bash
sudo docker stats dev-studio dev-docker
```

Afficher la taille de l’image :

```bash
sudo docker image ls yxtomix-dev-studio
```

Afficher les couches de l’image :

```bash
sudo docker history yxtomix-dev-studio:latest
```

Afficher l’espace utilisé par le Docker principal :

```bash
sudo docker system df -v
```

Afficher l’espace utilisé par le Docker de développement :

```bash
sudo docker exec --user abc dev-studio docker system df -v
```

Supprimer les images inutilisées du Docker principal :

```bash
sudo docker image prune -f
```

Supprimer les images inutilisées du Docker de développement :

```bash
sudo docker exec --user abc dev-studio docker image prune -f
```

## Sécurité

- Ne jamais publier le fichier `.env`.
- Ne jamais placer de mots de passe ou de clés API dans le Dockerfile.
- Utiliser des mots de passe différents pour code-server et sudo.
- Ne pas exposer directement le port `8443` sur Internet.
- Privilégier Tailscale Serve pour l’accès distant.
- Ne pas utiliser Tailscale Funnel sans besoin explicite.
- Ne pas monter `/var/run/docker.sock` dans `dev-studio`.
- Le Docker de développement est séparé du Docker principal de l'hôte.
- `dev-docker` utilise le mode rootless, mais son conteneur parent nécessite `privileged: true` pour Docker-in-Docker.
- Les outils exécutés dans Dev Studio peuvent modifier les fichiers présents dans `/DATA/Workspace`.
- Les outils peuvent créer librement des images et conteneurs dans le Docker de développement.
- Ils ne peuvent pas administrer directement les autres conteneurs du NAS.
- Vérifier les modifications proposées par les assistants IA avant un déploiement sensible.

## Composants tiers

Ce projet assemble notamment :

- LinuxServer code-server ;
- Docker Engine ;
- Docker Compose ;
- Docker Buildx ;
- Alpine Linux ;
- Node.js ;
- npm ;
- pnpm ;
- Python ;
- OpenJDK ;
- Git ;
- Bubblewrap ;
- OpenCode ;
- OpenAI Codex CLI.

Chaque composant reste soumis à sa propre licence.

La licence MIT de ce dépôt couvre uniquement les fichiers et configurations propres à ce projet.

## Licence

Ce projet est distribué sous licence MIT.

Voir le fichier [`LICENSE`](LICENSE).
