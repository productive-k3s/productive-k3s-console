# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE=node:22.20.0-bookworm-slim@sha256:b21fe589dfbe5cc39365d0544b9be3f1f33f55f3c86c87a76ff65a02f8f5848e

FROM ${NODE_IMAGE} AS wetty-builder
WORKDIR /opt/console
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential python3 \
    && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts=false --no-audit --no-fund \
    && npm cache clean --force

FROM ${NODE_IMAGE} AS tool-downloader
ARG TARGETARCH
ARG PK3S_CLI_VERSION=0.9.69
ARG PK3S_CLI_SHA256_AMD64=7b5cc23392dd0f17e343a507697ff879daf9aa5245c80ac0e6eea30633400dca
ARG PK3S_CLI_SHA256_ARM64=31e1c5332da241c76247738f325d11e04b381d057ab2030cb19d46b0fd12aac2
ARG OPENTOFU_VERSION=1.12.6
ARG OPENTOFU_SHA256_AMD64=5dc43da4f750f33873dc25e94587128709e819e544b7be9016b255316153c3a8
ARG OPENTOFU_SHA256_ARM64=e573979ba68a17fe7b881752051a694a7efcd970e39521f6a25775197861ed4d
ARG ANSIBLE_CORE_VERSION=2.15.13
ARG ANSIBLE_CORE_SHA256=e7f50bbb61beae792f5ecb86eff82149d3948d078361d70aedb01d76bc483c30
ARG KUBECTL_VERSION=v1.35.5
ARG KUBECTL_SHA256_AMD64=90f75ea6ecc9ea5633262e1c0b83a40560003b30fc94a04cb099404fcef0c224
ARG KUBECTL_SHA256_ARM64=ac69e06fd6860d69786692f5af1c3a1208ed54f8366a4d97ab15c172e99765ee
ARG HELM_VERSION=v3.21.0
ARG HELM_SHA256_AMD64=0093eb572e3d2380f094df162ddb525e219249de88957afe24cfbb19632acd36
ARG HELM_SHA256_ARM64=8de5a0c9a47431e59fd560e91e0779c8cf9316c383da7efb84128a4c339ecb2d
ARG K9S_VERSION=v0.51.0
ARG K9S_SHA256_AMD64=c3752ad51a5a4015a113819c4eeb6e55a4d0e4b8e652494797532f6fc8161dd7
ARG K9S_SHA256_ARM64=3ee05c82e5f9198928a4e86133608ba6a2c10a2244d6a7789e820f78319d640c
WORKDIR /downloads
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/* \
    && case "${TARGETARCH}" in \
         amd64) pk3s_sha="${PK3S_CLI_SHA256_AMD64}"; tofu_sha="${OPENTOFU_SHA256_AMD64}"; kubectl_sha="${KUBECTL_SHA256_AMD64}"; helm_sha="${HELM_SHA256_AMD64}"; k9s_sha="${K9S_SHA256_AMD64}" ;; \
         arm64) pk3s_sha="${PK3S_CLI_SHA256_ARM64}"; tofu_sha="${OPENTOFU_SHA256_ARM64}"; kubectl_sha="${KUBECTL_SHA256_ARM64}"; helm_sha="${HELM_SHA256_ARM64}"; k9s_sha="${K9S_SHA256_ARM64}" ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && curl -fsSLo pk3s.tgz "https://github.com/productive-k3s/productive-k3s-cli/releases/download/${PK3S_CLI_VERSION}/pk3s-${PK3S_CLI_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && echo "${pk3s_sha}  pk3s.tgz" | sha256sum -c - \
    && tar -xzf pk3s.tgz pk3s \
    && curl -fsSLo tofu.zip "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${TARGETARCH}.zip" \
    && echo "${tofu_sha}  tofu.zip" | sha256sum -c - \
    && unzip -q tofu.zip tofu \
    && curl -fsSLo "ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl" "https://files.pythonhosted.org/packages/9b/2c/19ac50eca9d32a9524329f023a459ebb6ca5a546380eb15af384306c170a/ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl" \
    && echo "${ANSIBLE_CORE_SHA256}  ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl" | sha256sum -c - \
    && curl -fsSLo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    && echo "${kubectl_sha}  kubectl" | sha256sum -c - \
    && curl -fsSLo helm.tgz "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && echo "${helm_sha}  helm.tgz" | sha256sum -c - \
    && tar -xzf helm.tgz "linux-${TARGETARCH}/helm" \
    && mv "linux-${TARGETARCH}/helm" helm \
    && curl -fsSLo k9s.tgz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz" \
    && echo "${k9s_sha}  k9s.tgz" | sha256sum -c - \
    && tar -xzf k9s.tgz k9s \
    && chmod 0755 pk3s tofu kubectl helm k9s

FROM ${NODE_IMAGE}
ARG PK3S_CONSOLE_VERSION=0.1.0-dev
ARG PK3S_CLI_VERSION=0.9.69
ARG OPENTOFU_VERSION=1.12.6
ARG ANSIBLE_CORE_VERSION=2.15.13
ARG WETTY_VERSION=4.0.0
ARG K9S_VERSION=v0.51.0
ARG KUBECTL_VERSION=v1.35.5
ARG HELM_VERSION=v3.21.0

LABEL org.opencontainers.image.title="Productive K3S Console" \
      org.opencontainers.image.description="Authenticated browser-hosted Productive K3S CLI/TUI" \
      org.opencontainers.image.source="https://github.com/productive-k3s/productive-k3s-console" \
      org.opencontainers.image.version="${PK3S_CONSOLE_VERSION}"

COPY --from=tool-downloader /downloads/ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl /downloads/
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates=20250419~deb12u1 \
       curl=7.88.1-10+deb12u15 \
       jq=1.6-2.1+deb12u2 \
       openssh-client=1:9.2p1-2+deb12u10 \
       python3=3.11.2-1+b1 \
       python3-cryptography=38.0.4-3+deb12u1 \
       python3-jinja2=3.1.2-1+deb12u3 \
       python3-packaging=23.0-1 \
       python3-resolvelib=0.9.0-2 \
       python3-venv=3.11.2-1+b1 \
       python3-yaml=6.0-3+b2 \
       util-linux=2.38.1-5+deb12u3 \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv --system-site-packages /opt/ansible \
    && /opt/ansible/bin/pip install --no-deps "/downloads/ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl" \
    && rm -f "/downloads/ansible_core-${ANSIBLE_CORE_VERSION}-py3-none-any.whl" \
    && groupadd --gid 10001 pk3s \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin pk3s \
    && install -d -m 0700 -o pk3s -g pk3s /home/pk3s/.ssh \
    && install -d -o pk3s -g pk3s /home/pk3s/.cache /home/pk3s/.pk3s /home/pk3s/.kube /opt/console

WORKDIR /opt/console
COPY --from=wetty-builder /opt/console/node_modules ./node_modules
COPY --from=wetty-builder /opt/console/package.json /opt/console/package-lock.json ./
COPY --from=tool-downloader /downloads/pk3s /usr/local/bin/pk3s
COPY --from=tool-downloader /downloads/tofu /usr/local/bin/tofu
COPY --from=tool-downloader /downloads/kubectl /usr/local/bin/kubectl
COPY --from=tool-downloader /downloads/helm /usr/local/bin/helm
COPY --from=tool-downloader /downloads/k9s /usr/local/bin/k9s
COPY console/entrypoint.sh console/session.sh /usr/local/bin/
COPY materials.lock.yaml dist/bom.json /usr/share/productive-k3s-console/

RUN chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/session.sh \
    /usr/local/bin/pk3s /usr/local/bin/tofu /usr/local/bin/kubectl /usr/local/bin/helm /usr/local/bin/k9s

ENV HOME=/home/pk3s \
    PATH=/opt/ansible/bin:/usr/local/bin:/usr/bin:/bin \
    ANSIBLE_HOME=/home/pk3s/.cache/ansible \
    ANSIBLE_LOCAL_TEMP=/home/pk3s/.cache/ansible/tmp \
    TF_PLUGIN_CACHE_DIR=/home/pk3s/.cache/opentofu/plugins \
    XDG_CONFIG_HOME=/home/pk3s/.cache/config \
    XDG_STATE_HOME=/home/pk3s/.cache/state \
    NODE_ENV=production \
    PORT=3000 \
    TITLE="Productive K3S Console" \
    COMMAND=/usr/local/bin/session.sh \
    WETTY_VERSION=${WETTY_VERSION} \
    PK3S_CLI_VERSION=${PK3S_CLI_VERSION} \
    OPENTOFU_VERSION=${OPENTOFU_VERSION} \
    ANSIBLE_CORE_VERSION=${ANSIBLE_CORE_VERSION} \
    K9S_VERSION=${K9S_VERSION} \
    KUBECTL_VERSION=${KUBECTL_VERSION} \
    HELM_VERSION=${HELM_VERSION}

EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
