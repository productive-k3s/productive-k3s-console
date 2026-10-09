# Productive K3S Console

PK3S Console packages WeTTY, the Productive K3S CLI, k9s, kubectl, and Helm
behind an OIDC-compatible authentication proxy. It is a browser delivery
surface for the existing CLI and TUI, not another control plane.

```text
Browser -> oauth2-proxy -> WeTTY -> pk3s -> k9s -> Kubernetes
```

The first implementation is intended to run as an ordinary Compose
application, including deployment through OpenShip.
