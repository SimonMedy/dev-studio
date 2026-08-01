FROM lscr.io/linuxserver/code-server:latest

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ── 1. Dépendances système ──
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bubblewrap \
        build-essential \
        ca-certificates \
        curl \
        git \
        jq \
        openjdk-17-jdk-headless \
        python3 \
        python3-pip \
        python3-venv \
        wget \
    && rm -rf /var/lib/apt/lists/*

# ── 2. Client Docker + Buildx + Compose ──
# Le démon Docker tourne dans le service dev-docker.
# Seuls le client et ses plugins sont installés ici.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && source /etc/os-release \
    && printf '%s\n' \
        "Types: deb" \
        "URIs: https://download.docker.com/linux/ubuntu" \
        "Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}" \
        "Components: stable" \
        "Architectures: $(dpkg --print-architecture)" \
        "Signed-By: /etc/apt/keyrings/docker.asc" \
        > /etc/apt/sources.list.d/docker.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-buildx-plugin \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# ── 3. Node.js 24 LTS ──
RUN curl -fsSL https://deb.nodesource.com/setup_24.x \
        -o /tmp/nodesource-setup.sh \
    && bash /tmp/nodesource-setup.sh \
    && rm -f /tmp/nodesource-setup.sh \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── 4. Outils Node globaux ──
# Cette valeur change à chaque deploy.sh afin de rechercher les dernières
# versions de Codex et OpenCode sans reconstruire les couches précédentes.
ARG AI_TOOLS_CACHE_BUST=initial

RUN echo "Actualisation des outils IA : ${AI_TOOLS_CACHE_BUST}" \
    && npm install --global \
        pnpm@latest \
        opencode-ai@latest \
        @openai/codex@latest \
    && npm cache clean --force

# ── 5. Validation stricte ──
RUN node --version \
    && npm --version \
    && pnpm --version \
    && docker --version \
    && docker compose version \
    && docker buildx version \
    && command -v bwrap \
    && bwrap --version \
    && command -v opencode \
    && opencode --version \
    && command -v codex \
    && codex --version