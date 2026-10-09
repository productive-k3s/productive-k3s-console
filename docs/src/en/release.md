# Release

Console versions are independent semantic versions. Each release records the
exact CLI, WeTTY, k9s, kubectl, Helm, auth proxy, builder, and base-image
materials.

Before the first production tag:

1. Close the ecosystem compatibility gate.
2. Replace the development CLI source revision with a released archive and
   verified checksum.
3. Run `make test-local-all`, `make docs-build`, and `make smoke`.
4. Confirm the BOM contains the intended revisions and lock digest.
5. Tag the reviewed commit as `vX.Y.Z`.

Mutable `latest` publication is intentionally absent.
