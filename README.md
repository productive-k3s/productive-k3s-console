# Productive K3S Console

Productive K3S Console exposes the existing `pk3s` terminal UI in a browser.
It packages WeTTY, the Productive K3S CLI, k9s, kubectl, and Helm behind an
OIDC-compatible authentication proxy. It does not implement another control
plane or duplicate PK3S behavior.

```text
Browser -> oauth2-proxy -> WeTTY -> pk3s -> k9s -> Kubernetes
```

## Status

This is the first V1 implementation. It uses an immutable CLI source revision
while the first compatible CLI release is being validated. A production image
release remains blocked until that revision is available as an immutable CLI
release asset and the P1 compatibility gate is closed.

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
# Open http://127.0.0.1:3000
make down AUTH_MODE=disabled
```

This starts only the Console service and binds WeTTY to `127.0.0.1:3000`.
`make dev-up` and `make dev-down` are aliases for the same flow. The bypass is
never enabled by default or by the production Compose file.

## State

Named volumes persist the existing CLI-owned state paths:

- `/home/pk3s/.pk3s`
- `/home/pk3s/.kube`

No Docker socket, host kubeconfig, SSH server, or embedded credentials are
used.

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
