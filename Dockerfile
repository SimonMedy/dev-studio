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

# ── 2. Node.js 24 LTS ──
RUN curl -fsSL https://deb.nodesource.com/setup_24.x \
        -o /tmp/nodesource-setup.sh \
    && bash /tmp/nodesource-setup.sh \
    && rm -f /tmp/nodesource-setup.sh \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── 3. Outils Node globaux ──
RUN npm install --global \
        pnpm@latest \
        opencode-ai@latest \
        @openai/codex@latest \
    && npm cache clean --force

# ── 4. Validation stricte ──
RUN node --version \
    && npm --version \
    && pnpm --version \
    && command -v opencode \
    && opencode --version \
    && command -v codex \
    && codex --version