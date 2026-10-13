# Productive K3S Console

Productive K3S Console exposes the existing `pk3s` terminal UI in a browser.
It packages WeTTY, the Productive K3S CLI, k9s, kubectl, Helm, and the pinned
remote/cloud Profile toolchain behind an OIDC-compatible authentication proxy.
It does not implement another control plane or duplicate PK3S behavior.

```text
Browser -> oauth2-proxy -> WeTTY -> pk3s -> k9s -> Kubernetes
```

## Status

This is the first V1 implementation. It consumes the checksum-verified PK3S
CLI `0.9.69` release for Linux AMD64 and ARM64. That CLI release fixes Core
`0.9.6`, Infra `0.9.66-0.9.6`, and immutable Catalog `0.9.66`; the complete
compatibility identities remain unchanged from the previously validated release
set. Console verifies the exact CLI archive checksum before installing it.

## Quick Start

1. Copy `.env.example` to `.env` and replace every example OIDC value.
2. Run `make build`.
3. Run `make up`.
4. Open `http://localhost:3000`.

The `console` service has no host port. Only `auth` is externally reachable.
Terminate the application with `make down`.

For explicit local development without OIDC, run:

```bash
make up AUTH_MODE=disabled
# Open http://localhost:3000
make down AUTH_MODE=disabled
```

This starts only the Console service and binds WeTTY to `127.0.0.1:3000`.
`make dev-up` and `make dev-down` are aliases for the same flow. The bypass is
never enabled by default or by the production Compose file.

## State

Named volumes persist the existing CLI-owned state paths:

- `/home/pk3s/.pk3s`
- `/home/pk3s/.kube`
- `/home/pk3s/.cache`
- `/home/pk3s/.ssh`

The cache volume contains downloaded bundles and Profile runtime state and is
therefore persistent rather than temporary. The container intentionally marks
the host-local `multipass` scenario unavailable: Console has no access to the
host Multipass daemon. CLI reports that boundary before starting an operation.
Cloud Profiles use the pinned OpenTofu and `jq` binaries in the image. On-prem
Profiles use the pinned Ansible/Python runtime and the SSH client; operators
must provision keys and `known_hosts` in the dedicated SSH volume at runtime.

No Docker socket, host kubeconfig, SSH server, host Multipass daemon, or
embedded credentials are used.

## Common Commands

```bash
make validate
make test-local-all
make build
make smoke
make test-logs-clean
```

`make test-local-all` is non-live. `make smoke` builds and starts local
containers and is therefore explicit.

Run `make docs-build` for strict portal validation or `make docs-up` to serve
the docs at `http://127.0.0.1:8000`. The portal consumes the shared Productive
K3S docs theme from `.shared/productive-k3s-docs-theme`; initialize submodules
before building a fresh checkout.

See the [English documentation](docs/src/en/index.md) or
[documentacion en espanol](docs/src/es/index.md) for the V1 boundaries,
authentication model, deployment, and development workflow.

## Branches

- `main`: stable integration baseline.
- `development`: active development branch.
