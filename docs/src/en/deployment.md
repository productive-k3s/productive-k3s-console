# Deployment And State

Initialize submodules, configure `.env`, and start the authenticated Compose
application:

```bash
git submodule update --init --recursive
cp .env.example .env
make build
make up
```

Only the authentication proxy publishes a host port. Named volumes persist
the CLI-owned paths `/home/pk3s/.pk3s` and `/home/pk3s/.kube`. The application
does not mount the Docker socket or a host kubeconfig.

OpenShip should deploy `docker-compose.yml` as an ordinary Compose
application, inject the OIDC values as secrets/configuration, retain both
named volumes, and terminate TLS before the auth proxy. The
`docker-compose.dev.yml` file is strictly a local override and is not part of
the production deployment.
