#!/usr/bin/env bash
# Pods, Volumes und Netzwerke (Image aus busybox, erfundene Daten).
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up
step "1. Pod: zwei Container teilen sich das Netzwerk (localhost)"
podman pod create --name pod1 >/dev/null
podman run -d --pod pod1 --name server $IMG sh -c 'mkdir -p /www; echo hallo > /www/index.html; httpd -f -p 8080 -h /www' >/dev/null 2>&1
sleep 1
cmd podman run --rm --pod pod1 --name client $IMG wget -qO- http://localhost:8080/
podman pod ps --format '{{.Name}} {{.Status}} Container: {{.NumberOfContainers}}'
podman pod rm -f -t 0 pod1 >/dev/null 2>&1
step "2. Volume: Daten überleben das Entfernen des Containers"
podman volume create daten1 >/dev/null
podman run --rm -v daten1:/daten $IMG sh -c 'echo wichtig > /daten/notiz.txt'
cmd podman run --rm -v daten1:/daten $IMG cat /daten/notiz.txt
podman volume ls --format '{{.Name}} {{.Driver}}'
step "3. Bind-Mount eines Verzeichnisses (nur lesen, :ro)"
mkdir -p $W/host; echo "vom Host" > $W/host/a.txt
cmd podman run --rm -v $W/host:/host:ro $IMG cat /host/a.txt
podman run --rm -v $W/host:/host:ro $IMG sh -c 'touch /host/neu' 2>&1 | sed 's#^touch: ##'
step "4. Eigenes Netzwerk: Container erreichen sich über den Namen"
podman network create lab >/dev/null
podman run -d --network lab --name srv $IMG sh -c 'mkdir -p /www; echo vom-srv > /www/index.html; httpd -f -p 8080 -h /www' >/dev/null 2>&1
sleep 1
cmd podman run --rm --network lab $IMG wget -qO- http://srv:8080/ 2>&1 | head -3
podman network ls --format '{{.Name}} {{.Driver}}' | sort
lab_down
