# Desarrollo Y Pruebas

El Makefile raiz es la interfaz estable del repositorio:

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

`test-local-all` no inicia contenedores. `smoke` es explicito porque construye
la imagen, inicia una instancia limitada a loopback, valida herramientas y
estado persistente, y luego elimina contenedores y volumenes.

`AUTH_MODE` usa `oidc` por defecto. El valor `disabled` selecciona el override
Compose de desarrollo, inicia solamente `console`, usa `.env.example` y
publica WeTTY exclusivamente en `127.0.0.1`. El Makefile rechaza cualquier
otro valor. Usa el mismo modo para `up`, `down` y `logs`.

La documentacion consume el submodulo del theme compartido. `docs-build` y
`docs-up` ejecutan `docs/sync-shared-theme.sh` antes de MkDocs. Las copias
sincronizadas se versionan y Ops valida el drift con
`make docs-theme-drift-check`.

Las versiones viven en `materials.lock.yaml`, argumentos del Docker build y
`package-lock.json`. Se actualizan juntas y `make bom` regenera el BOM resuelto
no versionado.
