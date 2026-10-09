# Autenticacion

Console delega la autenticacion a `oauth2-proxy`. Configura el cliente OIDC
con este callback, reemplazando el host de ejemplo:

```text
https://console.example.com/oauth2/callback
```

Copia `.env.example` a `.env` y define issuer URL, client ID, client secret,
redirect URL, dominios de email permitidos y cookie secret. Produccion debe
usar HTTPS y `OIDC_COOKIE_SECURE=true`.

```bash
openssl rand -base64 32 | tr -- '+/' '-_'
```

OpenShip puede inyectar esas variables mediante su mecanismo de secretos y
configuracion. Ninguna credencial forma parte de las imagenes.
`make up AUTH_MODE=disabled` es el bypass explicito limitado a loopback y no
debe exponerse a una red compartida. Se detiene con
`make down AUTH_MODE=disabled`. `dev-up` y `dev-down` quedan como aliases de
esos comandos.
