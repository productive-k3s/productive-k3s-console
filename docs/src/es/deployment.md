# Despliegue Y Estado

Inicializa submodulos, configura `.env` e inicia la aplicacion autenticada:

```bash
git submodule update --init --recursive
cp .env.example .env
mkdir -p ./config
sudo chown -R 10001:10001 ./config
sudo chmod 0700 ./config
make build
make up
```

Solo el proxy de autenticacion publica un puerto. Los volumenes nombrados
persisten las rutas del CLI `/home/pk3s/.cache`, `/home/pk3s/.pk3s`,
`/home/pk3s/.kube` y `/home/pk3s/.ssh`. El volumen SSH comienza vacio; el
despliegue inyecta las claves privadas y los hosts confiables durante la
operacion, sin incluirlos en la imagen. La aplicacion no monta el socket de
Docker, un kubeconfig del host ni el daemon Multipass del host.

`PK3S_CONFIG_DIR` selecciona el unico directorio del host expuesto a PK3S y a
la accion Config restringida en `/home/pk3s/config`. Debe ser accesible para
UID/GID `10001:10001`; el inicio falla en lugar de cambiar ownership del host.
Consulta [Workspace de configuracion](configuration.md) para conocer los
comandos y el contrato de aislamiento Landlock.

La imagen incluye OpenTofu `1.12.6` y ansible-core `2.15.13` verificados por
checksum, junto con paquetes Debian exactos para `jq`, Python, `curl` y el
cliente OpenSSH. Esto habilita Profiles cloud y remote-host. Los Profiles
Multipass siguen visibles pero no disponibles por politica explicita.

OpenShip debe desplegar `docker-compose.yml` como una aplicacion Compose comun,
inyectar los valores OIDC, conservar todos los volumenes y terminar TLS antes del
proxy. `docker-compose.dev.yml` es solo un override local y no forma parte del
despliegue productivo.
