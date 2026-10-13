# Release

Console usa versiones semanticas independientes. Cada release registra las
versiones exactas de CLI, WeTTY, k9s, kubectl, Helm, OpenTofu, Ansible,
herramientas de acceso remoto, proxy de autenticacion, builders e imagen base.

Los tags de prerelease usan identificadores Semantic Versioning como
`v0.1.0-alpha.1`. Publican imagenes inmutables de evaluacion, pero no declaran
completa la definicion V1. El tag estable `v0.1.0` queda reservado hasta cerrar
el workspace de configuracion, OIDC real, despliegue OpenShip y evidencia de
release.

El gate de compatibilidad del ecosistema esta cerrado. Console consume los
archivos publicados del CLI `0.9.69` para Linux AMD64 y ARM64 solamente despues
de verificar sus checksums SHA256 exactos. CLI `0.9.69` fija Core `0.9.6`, Infra
`0.9.66-0.9.6` y el Catalog inmutable `0.9.66`.

Antes del primer tag productivo:

1. Ejecutar `make test-local-all`, `make docs-build` y
   `make smoke VERSION=<version>`.
2. Confirmar que el BOM contiene CLI `0.9.69`, el toolchain de Profiles,
   checksums y paquetes exactos, la matriz de compatibilidad, la revision
   fuente esperada y el digest del lock.
3. Revisar la evidencia de autenticacion y despliegue mediante OpenShip.
4. Mergear el PR verde a `main`, sincronizar `development` y crear un tag
   anotado `vX.Y.Z[-prerelease]` sobre ese commit exacto de `main`.

El workflow del tag repite la validacion fuente, construye la imagen final con
su version, comprueba sus labels OCI de version/revision, ejecuta el smoke del
contenedor y solo entonces publica los tags de version y commit SHA en GHCR.

No se publica el tag mutable `latest`.
