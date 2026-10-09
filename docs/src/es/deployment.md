# Despliegue Y Estado

Inicializa submodulos, configura `.env` e inicia la aplicacion autenticada:

```bash
git submodule update --init --recursive
cp .env.example .env
make build
make up
```

Solo el proxy de autenticacion publica un puerto. Los volumenes nombrados
persisten las rutas del CLI `/home/pk3s/.pk3s` y `/home/pk3s/.kube`. La
aplicacion no monta el socket de Docker ni un kubeconfig del host.

OpenShip debe desplegar `docker-compose.yml` como una aplicacion Compose comun,
inyectar los valores OIDC, conservar ambos volumenes y terminar TLS antes del
proxy. `docker-compose.dev.yml` es solo un override local y no forma parte del
despliegue productivo.
