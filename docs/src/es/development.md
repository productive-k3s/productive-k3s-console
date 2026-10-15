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
estado persistente, ejercita el selector fijo y el workspace Config confinado
con Landlock usando datos sinteticos, y luego elimina contenedores y volumenes.

`AUTH_MODE` usa `oidc` por defecto. El valor `disabled` selecciona el override
Compose de desarrollo, inicia solamente `console`, usa `.env.example` y
publica WeTTY exclusivamente en `127.0.0.1`. El Makefile rechaza cualquier
otro valor. Abri `http://localhost:3000`, que coincide con el origen configurado,
y usa el mismo modo para `up`, `down` y `logs`.

El contenedor de desarrollo persiste `.cache`, `.pk3s`, `.kube` y `.ssh`.
Tambien monta el directorio ignorado `PK3S_CONFIG_DIR` en
`/home/pk3s/config`; prepara esa ruta dedicada para UID/GID `10001:10001`
antes de ejecutar `make up`. Los
Profiles de Multipass se rechazan por politica de runtime porque el contenedor
no esta conectado al daemon Multipass del host. Los Profiles cloud y
remote-host usan las mismas herramientas pineadas que produccion. Las
credenciales de prueba solo pertenecen al volumen SSH y nunca se versionan.

La documentacion consume el submodulo del theme compartido. `docs-build` y
`docs-up` ejecutan `docs/sync-shared-theme.sh` antes de MkDocs. Las copias
sincronizadas se versionan y Ops valida el drift con
`make docs-theme-drift-check`.

Las versiones viven en `materials.lock.yaml`, argumentos del Docker build y
`package-lock.json`. El build de Docker descarga el archivo publicado del CLI
PK3S para la arquitectura objetivo y verifica su checksum antes de extraerlo;
Console nunca recompila CLI desde un branch o revision fuente. Esos inputs se
actualizan juntos y `make bom` regenera el BOM resuelto no versionado.
