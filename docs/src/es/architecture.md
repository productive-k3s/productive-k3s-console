# Arquitectura

La aplicacion Compose tiene dos servicios. `auth` es el unico servicio
publicado externamente. `console` solo pertenece a la red interna y ofrece el
upstream fijo de WeTTY.

WeTTY 4 usa comandos locales solamente cuando su servidor inicia con UID 0.
Console evita el servidor SSH y las contrasenas fijas del ejemplo historico.
WeTTY recibe solo `CHOWN`, `SETUID` y `SETGID`; el wrapper de sesion elimina
inmediatamente todas las capacidades, cambia a UID/GID 10001 y ejecuta
`pk3s ui`. Los comandos y hosts elegidos por URL permanecen deshabilitados.

La excepcion es deliberadamente acotada: el proceso interactivo no es root y
la terminal web nunca abre un login shell.
