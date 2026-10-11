# Release

Console versions are independent semantic versions. Each release records the
exact CLI, WeTTY, k9s, kubectl, Helm, auth proxy, builder, and base-image
materials.

The ecosystem compatibility gate is closed. Console consumes the released CLI
`0.9.65` archives for Linux AMD64 and ARM64 only after verifying their exact
SHA256 checksums. CLI `0.9.65` fixes Core `0.9.6`, Infra `0.9.65-0.9.6`, and
immutable Catalog `0.9.65`.

Before the first production tag:

1. Run `make test-local-all`, `make docs-build`, and `make smoke`.
2. Confirm the BOM contains CLI `0.9.65`, its checksums, compatibility matrix,
   intended source revision, and lock digest.
3. Review the authentication and OpenShip deployment evidence.
4. Tag the reviewed commit as `vX.Y.Z`.

Mutable `latest` publication is intentionally absent.
