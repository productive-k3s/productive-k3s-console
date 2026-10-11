# Release

Console usa versiones semanticas independientes. Cada release registra las
versiones exactas de CLI, WeTTY, k9s, kubectl, Helm, proxy de autenticacion,
builders e imagen base.

El gate de compatibilidad del ecosistema esta cerrado. Console consume los
archivos publicados del CLI `0.9.65` para Linux AMD64 y ARM64 solamente despues
de verificar sus checksums SHA256 exactos. CLI `0.9.65` fija Core `0.9.6`, Infra
`0.9.65-0.9.6` y el Catalog inmutable `0.9.65`.

Antes del primer tag productivo:

1. Ejecutar `make test-local-all`, `make docs-build` y `make smoke`.
2. Confirmar que el BOM contiene CLI `0.9.65`, sus checksums, la matriz de
   compatibilidad, la revision fuente esperada y el digest del lock.
3. Revisar la evidencia de autenticacion y despliegue mediante OpenShip.
4. Etiquetar el commit revisado como `vX.Y.Z`.

No se publica el tag mutable `latest`.
