# Deployment And State

Initialize submodules, configure `.env`, and start the authenticated Compose
application:

```bash
git submodule update --init --recursive
cp .env.example .env
mkdir -p ./config
sudo chown -R 10001:10001 ./config
sudo chmod 0700 ./config
make build
make up
```

Only the authentication proxy publishes a host port. Named volumes persist
the CLI-owned paths `/home/pk3s/.cache`, `/home/pk3s/.pk3s`,
`/home/pk3s/.kube`, and `/home/pk3s/.ssh`. The SSH volume starts empty;
deployments inject private keys and trusted host entries at runtime rather than
embedding them in the image. The application does not mount the Docker socket,
a host kubeconfig, or the host Multipass daemon.

`PK3S_CONFIG_DIR` selects the single host directory exposed to both PK3S and
the restricted Config action at `/home/pk3s/config`. It must be accessible to
UID/GID `10001:10001`; startup fails instead of changing host ownership. See
[Configuration workspace](configuration.md) for the command surface and
Landlock isolation contract.

The image includes checksum-locked OpenTofu `1.12.6`, ansible-core `2.15.13`,
and exact Debian packages for `jq`, Python, `curl`, and the OpenSSH client.
This enables cloud and remote-host Profiles. Multipass Profiles remain visible
but unavailable by explicit runtime policy.

OpenShip should deploy `docker-compose.yml` as an ordinary Compose
application, inject the OIDC values as secrets/configuration, retain all named
volumes, and terminate TLS before the auth proxy. The
`docker-compose.dev.yml` file is strictly a local override and is not part of
the production deployment.
