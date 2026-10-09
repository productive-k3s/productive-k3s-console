# Release

Console usa versiones semanticas independientes. Cada release registra las
versiones exactas de CLI, WeTTY, k9s, kubectl, Helm, proxy de autenticacion,
builders e imagen base.

Antes del primer tag productivo:

1. Cerrar el gate de compatibilidad del ecosistema.
2. Reemplazar la revision de desarrollo del CLI por un archivo publicado con
   checksum verificado.
3. Ejecutar `make test-local-all`, `make docs-build` y `make smoke`.
4. Confirmar las revisiones y el digest del lock en el BOM.
5. Etiquetar el commit revisado como `vX.Y.Z`.

No se publica el tag mutable `latest`.
