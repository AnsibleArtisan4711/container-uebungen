#!/usr/bin/env bash
# Gemeinsame Hilfen der Übungsreihe (P25). Echt ausgeführt (Ubuntu 24.04, ohne systemd, Cloud-Container): Docker Engine 29.9.2 mit
# Compose 5.7.0 und BuildKit, Registry (Paket docker-registry 2.8.2), Podman 4.9.3 (nur Modul 7). NICHT ausgeführt: Docker Desktop,
# Rootless-Docker, Zugriff auf Docker Hub, Schwachstellenscanner, Hyper-V. Dateien unter /tmp/p25, Docker-Objekte mit Label p25.
# Voraussetzung: laufender Docker-Daemon, Aufruf als root bzw. mit Zugriff auf den Docker-Socket, Paket busybox-static.
W=/tmp/p25; B=p25/busybox:lab
step() { echo; echo "## $*"; }
cmd() { echo "\$ $*"; "$@" 2>&1; return $?; }
mask() { sed -E 's/sha256:[0-9a-f]{64}/sha256:<Prüfsumme>/g; s/\b[0-9a-f]{12}\b/<ID>/g; s/\b[0-9a-f]{64}\b/<ID>/g'; }
need_docker() { docker info >/dev/null 2>&1 || { echo "Docker-Daemon nicht erreichbar (docker info schlägt fehl)"; exit 1; }; }
lab_down() {
  docker compose -p p25 down -v --remove-orphans >/dev/null 2>&1
  docker ps -aq --filter label=p25 | xargs -r docker rm -f >/dev/null 2>&1
  docker volume ls -q --filter label=p25 | xargs -r docker volume rm -f >/dev/null 2>&1
  docker network ls -q --filter label=p25 | xargs -r docker network rm >/dev/null 2>&1
  docker image ls -q --filter 'reference=p25/*' --filter 'reference=localhost:5000/p25/*' | sort -u | xargs -r docker rmi -f >/dev/null 2>&1
  command -v podman >/dev/null 2>&1 && podman rmi -f docker.io/p25/busybox:lab >/dev/null 2>&1
  [ -f "$W/registry.pid" ] && kill "$(cat "$W/registry.pid")" >/dev/null 2>&1
  rm -rf "$W"
}
base_image() {   # Basis-Image aus busybox-static (im Cloud-Container ist Docker Hub nicht erreichbar)
  local r=$W/rootfs; mkdir -p $r/bin; cp /usr/bin/busybox $r/bin/busybox
  for a in $($r/bin/busybox --list); do [ "$a" = busybox ] || ln -sf busybox $r/bin/$a; done
  tar -C $r -c . | docker import - $B >/dev/null
}
lab_up() { need_docker; lab_down; mkdir -p "$W"; base_image; }
trap 'lab_down >/dev/null 2>&1' EXIT
