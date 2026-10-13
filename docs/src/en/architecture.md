# Architecture

The Compose application has two services. `auth` is the only externally
published service. `console` is attached only to the internal network and
provides the fixed WeTTY upstream.

WeTTY 4 selects its local-command mode only while its server process has UID
0. Console avoids the SSH server and fixed-password model used by the historic
reference application. WeTTY starts with only `CHOWN`, `SETUID`, and `SETGID`;
the fixed session wrapper immediately drops all capabilities, changes to
UID/GID 10001, and executes `pk3s ui`. URL-selected commands and remote hosts
are disabled.

This is a deliberately narrow exception. The interactive process is non-root
and the browser terminal never opens a login shell.
