# Workspace de configuracion

Console monta un unico directorio administrado por el operador en
`/home/pk3s/config`. Alli se pueden preparar archivos de entrada para Profiles
y material SSH que deba referenciarse por ruta, sin exponer una shell de uso
general en el navegador.

Defini la ruta del host en `.env`:

```dotenv
PK3S_CONFIG_DIR=./config
```

Crea un directorio dedicado y asignalo a la identidad no root fija de Console
antes de iniciar:

```bash
mkdir -p ./config
sudo chown -R 10001:10001 ./config
sudo chmod 0700 ./config
```

Estos comandos cambian el propietario de forma intencional. Ejecutalos
solamente sobre el directorio dedicado indicado mediante `PK3S_CONFIG_DIR`.
Console verifica el acceso al iniciar y nunca cambia automaticamente el
propietario de archivos del host.

El selector de la sesion ofrece exactamente `Productive K3S`, `Config` y
`Exit`. La accion `Config` inicia un workspace de archivos construido para
este fin como UID/GID `10001:10001`. Admite `help`, `pwd`, `ls`, `cd`, `view`,
`edit`, `touch`, `mkdir`, `rm`, `rmdir` y `exit`. No ejecuta comandos de shell.

El workspace aplica una politica de filesystem Landlock antes de aceptar
entradas. Solo `/home/pk3s/config` puede leerse o modificarse; ademas se
rechazan rutas absolutas, navegacion al padre y enlaces simbolicos. El proceso
no puede leer estado PK3S, kubeconfigs, estado SSH, caches, archivos del sistema
ni herramientas de la imagen. Si el kernel del host no ofrece Landlock,
Config falla de forma cerrada y la accion normal de PK3S sigue disponible.

Los archivos se crean con modo `0600` y los directorios con modo `0700`. Por
ejemplo, crea un archivo de entrada AWS con `edit aws.env`, terminalo con una
linea que contenga solamente `.save` y usalo desde PK3S como:

```text
--env-file /home/pk3s/config/aws.env
```

La configuracion generada y los secretos permanecen en el directorio ignorado
del host; nunca forman parte de la imagen ni del repositorio.
