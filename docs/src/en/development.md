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
persistent state, exercises the fixed selector and Landlock-confined Config
workspace with synthetic data, and removes its containers and volumes.

`AUTH_MODE` defaults to `oidc`. Setting it to `disabled` selects the separate
development Compose override, starts only `console`, uses `.env.example`, and
publishes WeTTY exclusively on `127.0.0.1`. Any other value is rejected by the
Makefile. Open `http://localhost:3000`, which matches the configured browser
origin, and use the same mode for `up`, `down`, and `logs`.

The development container persists `.cache`, `.pk3s`, `.kube`, and `.ssh`.
It bind-mounts the ignored `PK3S_CONFIG_DIR` at `/home/pk3s/config`; prepare
that dedicated path for UID/GID `10001:10001` before `make up`.
Multipass Profiles are rejected by runtime policy because the container is not
connected to the host Multipass daemon. Cloud and remote-host Profiles use the
same pinned tools as production. Test credentials belong only in the SSH
volume and must never be committed.

Documentation consumes the shared theme submodule. Both `docs-build` and
`docs-up` run `docs/sync-shared-theme.sh` before MkDocs. Commit synchronized
theme copies and validate workspace drift from Ops with
`make docs-theme-drift-check`.

Dependency versions live in `materials.lock.yaml`, Docker build arguments, and
`package-lock.json`. The Docker build downloads the released PK3S CLI archive
for its target architecture and verifies the checksum from the lock before
extracting it; Console never rebuilds CLI from a branch or source revision.
Update these inputs together and regenerate the untracked resolved BOM with
`make bom`.
