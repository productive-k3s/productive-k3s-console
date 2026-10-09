# Development And Tests

The root Makefile is the stable repository interface:

```bash
make validate
make test-local-all
make build
make smoke
make up AUTH_MODE=disabled
make down AUTH_MODE=disabled
make docs-build
make docs-up
make docs-down
make test-logs-clean
```

`test-local-all` does not start containers. `smoke` is explicit because it
builds the image, starts a loopback-only instance, validates locked tools and
persistent state, and removes its containers and volumes.

`AUTH_MODE` defaults to `oidc`. Setting it to `disabled` selects the separate
development Compose override, starts only `console`, uses `.env.example`, and
publishes WeTTY exclusively on `127.0.0.1`. Any other value is rejected by the
Makefile. Use the same mode for `up`, `down`, and `logs`.

Documentation consumes the shared theme submodule. Both `docs-build` and
`docs-up` run `docs/sync-shared-theme.sh` before MkDocs. Commit synchronized
theme copies and validate workspace drift from Ops with
`make docs-theme-drift-check`.

Dependency versions live in `materials.lock.yaml`, Docker build arguments, and
`package-lock.json`. Update them together and regenerate the untracked resolved
BOM with `make bom`.
