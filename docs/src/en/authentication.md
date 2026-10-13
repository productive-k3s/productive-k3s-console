# Authentication

Console delegates authentication to `oauth2-proxy`. Configure an OIDC client
with this callback, replacing the example host:

```text
https://console.example.com/oauth2/callback
```

Copy `.env.example` to `.env` and set the issuer URL, client ID, client secret,
redirect URL, allowed email domains, and cookie secret. Production deployments
must use HTTPS and `OIDC_COOKIE_SECURE=true`.

```bash
openssl rand -base64 32 | tr -- '+/' '-_'
```

The ignored `.env` file is for local operation. OpenShip may inject the same
values through its secret/configuration mechanism. No credential is included
in either image. `make up AUTH_MODE=disabled` is the explicit loopback-only
development bypass and must not be exposed to a shared network. Stop that mode
with `make down AUTH_MODE=disabled`. The `dev-up` and `dev-down` targets remain
aliases for those commands.
