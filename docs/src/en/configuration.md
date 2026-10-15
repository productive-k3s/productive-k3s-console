# Configuration Workspace

Console mounts one operator-owned host directory at `/home/pk3s/config`.
Profile input files and SSH material that must be referenced with paths can be
prepared there without exposing a general-purpose browser shell.

Set the host path in `.env`:

```dotenv
PK3S_CONFIG_DIR=./config
```

Create a dedicated directory and grant it to the fixed non-root Console
identity before startup:

```bash
mkdir -p ./config
sudo chown -R 10001:10001 ./config
sudo chmod 0700 ./config
```

These commands intentionally change ownership. Run them only against the
dedicated directory selected through `PK3S_CONFIG_DIR`. Console checks access
at startup and never changes host ownership automatically.

The browser session selector exposes exactly `Productive K3S`, `Config`, and
`Exit`. The `Config` action starts a purpose-built file workspace as UID/GID
`10001:10001`. It supports `help`, `pwd`, `ls`, `cd`, `view`, `edit`, `touch`,
`mkdir`, `rm`, `rmdir`, and `exit`. It does not execute shell commands.

The workspace applies a Landlock filesystem policy before accepting input.
Only `/home/pk3s/config` can be read or changed; absolute paths, parent
traversal, and symbolic links are rejected as an additional defense. The
process cannot read PK3S state, kubeconfigs, SSH state, cache data, system
files, or image tools. If the host kernel does not provide Landlock, Config
fails closed while the normal PK3S action remains available.

Files are created with mode `0600` and directories with mode `0700`. For
example, create an AWS Profile input file with `edit aws.env`, finish with a
line containing only `.save`, and then use it from PK3S as:

```text
--env-file /home/pk3s/config/aws.env
```

Generated configuration and secret values stay in the ignored host directory;
they are never image content or repository files.
