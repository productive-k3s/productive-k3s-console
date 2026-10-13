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
the CLI-owned paths `/home/pk3s/.cache`, `/home/pk3s/.pk3s`,
`/home/pk3s/.kube`, and `/home/pk3s/.ssh`. The SSH volume starts empty;
deployments inject private keys and trusted host entries at runtime rather than
embedding them in the image. The application does not mount the Docker socket,
a host kubeconfig, or the host Multipass daemon.

The image includes checksum-locked OpenTofu `1.12.6`, ansible-core `2.15.13`,
and exact Debian packages for `jq`, Python, `curl`, and the OpenSSH client.
This enables cloud and remote-host Profiles. Multipass Profiles remain visible
but unavailable by explicit runtime policy.

OpenShip should deploy `docker-compose.yml` as an ordinary Compose
application, inject the OIDC values as secrets/configuration, retain all named
volumes, and terminate TLS before the auth proxy. The
`docker-compose.dev.yml` file is strictly a local override and is not part of
the production deployment.
