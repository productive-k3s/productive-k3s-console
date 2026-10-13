# Release

Console versions are independent semantic versions. Each release records the
exact CLI, WeTTY, k9s, kubectl, Helm, OpenTofu, Ansible, remote access tools,
auth proxy, builder, and base-image materials.

Pre-release tags use Semantic Versioning identifiers such as
`v0.1.0-alpha.1`. They publish immutable evaluation images but do not claim the
V1 definition of done. The stable `v0.1.0` tag remains reserved until the
configuration workspace, real OIDC, OpenShip deployment, and release evidence
gates are complete.

The ecosystem compatibility gate is closed. Console consumes the released CLI
`0.9.69` archives for Linux AMD64 and ARM64 only after verifying their exact
SHA256 checksums. CLI `0.9.69` fixes Core `0.9.6`, Infra `0.9.66-0.9.6`, and
immutable Catalog `0.9.66`.

Before the first production tag:

1. Run `make test-local-all`, `make docs-build`, and
   `make smoke VERSION=<version>`.
2. Confirm the BOM contains CLI `0.9.69`, the Profile runtime toolchain, exact
   checksums/packages, compatibility matrix, intended source revision, and
   lock digest.
3. Review the authentication and OpenShip deployment evidence.
4. Merge the green PR to `main`, synchronize `development`, and create an
   annotated `vX.Y.Z[-prerelease]` tag on that exact `main` commit.

The tag workflow repeats source validation, builds the final versioned image,
checks its OCI version/revision labels, runs the container smoke test, and only
then publishes version and commit-SHA tags to GHCR.

Mutable `latest` publication is intentionally absent.
