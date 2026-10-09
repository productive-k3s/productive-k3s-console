# Productive K3S Console

PK3S Console empaqueta WeTTY, Productive K3S CLI, k9s, kubectl y Helm detras
de un proxy de autenticacion compatible con OIDC. Es una superficie web para
el CLI y la TUI existentes, no un nuevo control plane.

```text
Navegador -> oauth2-proxy -> WeTTY -> pk3s -> k9s -> Kubernetes
```

La primera implementacion se ejecuta como una aplicacion Compose comun,
incluyendo su despliegue mediante OpenShip.
