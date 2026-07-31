# Dev Studio

Environnement de développement accessible depuis un navigateur, construit autour de LinuxServer code-server.

Il inclut notamment :

- code-server
- Node.js 24 LTS
- npm
- pnpm
- Python 3
- OpenJDK 17
- Git
- OpenCode
- OpenAI Codex CLI
- Outils de compilation natifs

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

- Docker
- Docker Compose
- Un système Linux compatible avec les chemins `/DATA`
- Une architecture `amd64`
- Tailscale, uniquement pour l’accès HTTPS privé à distance

Ce projet est principalement prévu pour ZimaOS, mais il est lancé directement avec Docker Compose, sans passer par l’interface d’applications ZimaOS.

## Stockage persistant

L’application utilise les dossiers suivants :

```text
/DATA/AppData/dev-studio/config
/DATA/Workspace
```

Correspondance dans le conteneur :

```text
/DATA/AppData/dev-studio/config -> /config
/DATA/Workspace                  -> /config/workspace
```

Le dossier `/config` contient notamment :

- la configuration de code-server ;
- les extensions ;
- les préférences utilisateur ;
- les données persistantes de l’environnement.

Les projets sont stockés séparément dans `/DATA/Workspace`.

Les données persistent lors de la reconstruction ou de la suppression du conteneur.

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

Le fichier `compose.yaml` utilise ces variables :

```yaml
environment:
  PASSWORD: ${CODE_SERVER_PASSWORD:?CODE_SERVER_PASSWORD doit être défini}
  SUDO_PASSWORD: ${SUDO_PASSWORD:-}
```

`CODE_SERVER_PASSWORD` est obligatoire.

`SUDO_PASSWORD` peut être laissé vide si l’accès à `sudo` depuis le terminal intégré n’est pas nécessaire :

```dotenv
CODE_SERVER_PASSWORD=REMPLACER_PAR_UN_MOT_DE_PASSE_SOLIDE
SUDO_PASSWORD=
```

## Installation et déploiement

Le script `deploy.sh` peut être utilisé aussi bien pour le premier lancement que pour les mises à jour suivantes.

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
sudo docker compose build --pull
sudo docker compose up -d --force-recreate
sudo docker compose ps
sudo docker image prune -f
```

Lors du premier lancement, Docker :

1. récupère la dernière image de base ;
2. construit l’image `yxtomix-dev-studio:latest` ;
3. crée le conteneur `dev-studio` ;
4. démarre le service ;
5. affiche son état ;
6. supprime les anciennes images Docker inutilisées.

## Commandes utiles

Afficher l’état du service :

```bash
sudo docker compose ps
```

Afficher les journaux en temps réel :

```bash
sudo docker compose logs -f
```

Afficher uniquement les 100 dernières lignes :

```bash
sudo docker logs --tail=100 dev-studio
```

Redémarrer le service :

```bash
sudo docker compose restart
```

Arrêter le service sans supprimer le conteneur :

```bash
sudo docker compose stop
```

Relancer un service arrêté :

```bash
sudo docker compose start
```

Arrêter et supprimer le conteneur :

```bash
sudo docker compose down
```

Cette commande ne supprime pas les données persistantes situées sous `/DATA`.

## Accès local

Accès avec le nom du serveur :

```text
http://nom-du-serveur:8443
```

Accès avec son adresse IP locale :

```text
http://adresse-ip-du-serveur:8443
```

Le navigateur demandera le mot de passe défini dans :

```dotenv
CODE_SERVER_PASSWORD=
```

## Accès HTTPS privé avec Tailscale Serve

Tailscale Serve permet d’accéder à Dev Studio en HTTPS depuis les appareils autorisés du tailnet.

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

Ne pas utiliser Tailscale Funnel sauf si une exposition publique sur Internet est volontaire.

## Mise à jour

Pour mettre à jour l’image de base et les outils installés, relancer simplement :

```bash
./deploy.sh
```

Le script reconstruit l’image avec les versions disponibles, recrée le conteneur et conserve les données persistantes.

Les éléments suivants ne sont pas supprimés lors d’une mise à jour :

```text
/DATA/AppData/dev-studio/config
/DATA/Workspace
```

## Reconstruction complète

En cas de problème de cache ou pour forcer une reconstruction complète :

```bash
sudo docker compose build --pull --no-cache
sudo docker compose up -d --force-recreate
```

Cette opération est plus longue qu’un déploiement normal, car toutes les couches doivent être reconstruites.

## Vérification des outils

Depuis le terminal intégré de code-server :

```bash
node --version
npm --version
pnpm --version
python3 --version
java -version
git --version
opencode --version
codex --version
```

## Vérification du workspace

Tester l’écriture dans le workspace :

```bash
touch /config/workspace/test-write
ls -l /config/workspace/test-write
rm /config/workspace/test-write
```

## Vérification des volumes

Afficher les montages du conteneur :

```bash
sudo docker inspect dev-studio \
  --format '{{range .Mounts}}{{println .Source "->" .Destination}}{{end}}'
```

Résultat attendu :

```text
/DATA/AppData/dev-studio/config -> /config
/DATA/Workspace -> /config/workspace
```

## Ressources Docker

Afficher la consommation CPU et mémoire :

```bash
sudo docker stats dev-studio
```

Afficher la taille de l’image :

```bash
sudo docker image ls yxtomix-dev-studio
```

Afficher les couches de l’image :

```bash
sudo docker history yxtomix-dev-studio:latest
```

Afficher l’espace disque utilisé par Docker :

```bash
sudo docker system df -v
```

Supprimer les images inutilisées :

```bash
sudo docker image prune -f
```

## Sécurité

- Ne jamais publier le fichier `.env`.
- Ne jamais placer de mots de passe ou de clés API dans le Dockerfile.
- Utiliser des mots de passe différents pour code-server et sudo.
- Ne pas exposer directement le port `8443` sur Internet.
- Privilégier Tailscale Serve pour l’accès distant.
- Ne pas utiliser Tailscale Funnel sans besoin explicite.
- Toute personne disposant d’un accès administrateur au NAS ou à Docker peut inspecter les variables d’environnement du conteneur.
- Toute personne disposant d’un accès administrateur au NAS peut accéder aux données persistantes.
- Vérifier les changements des images et outils distants avant une utilisation dans un environnement sensible.

## Composants tiers

Ce projet assemble plusieurs logiciels tiers, notamment :

- LinuxServer code-server ;
- Node.js ;
- npm ;
- pnpm ;
- Python ;
- OpenJDK ;
- Git ;
- OpenCode ;
- OpenAI Codex CLI.

Chaque composant reste soumis à sa propre licence.

La licence MIT de ce dépôt couvre uniquement les fichiers et configurations propres à ce projet.

## Licence

Ce projet est distribué sous licence MIT.

Voir le fichier [`LICENSE`](LICENSE).