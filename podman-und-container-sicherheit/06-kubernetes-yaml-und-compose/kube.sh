#!/usr/bin/env bash
# Mehrere Container als Einheit: Pod als Kubernetes-YAML erzeugen (podman generate kube) und wieder starten (podman kube play). Podman Compose wurde nicht ausgeführt.
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up
step "1. Pod mit einem Container anlegen"
podman pod create --name blog >/dev/null
podman run -d --pod blog --name blog-web $IMG sleep 300 >/dev/null 2>&1
podman pod ps --format '{{.Name}} {{.Status}} Container: {{.NumberOfContainers}}'
step "2. Als YAML ausgeben (Auszug; Zeitstempel und Kennungen entfernt)"
podman generate kube blog 2>/dev/null > $W/blog.yaml
grep -E "^(apiVersion|kind):|^  name:|^  - name:|^    image:|^    - sleep|^    - \"300\"|^  - image:" $W/blog.yaml | sed -E 's/^( *name: ).*-([a-z]+)$/\1<Name>/' | head -12
step "3. Pod entfernen und aus der YAML-Datei neu erzeugen"
podman pod rm -f -t 0 blog >/dev/null 2>&1
podman kube play $W/blog.yaml >/dev/null 2>&1; echo "Exitcode kube play: $?"
podman pod ps --format '{{.Name}} {{.Status}} Container: {{.NumberOfContainers}}'
step "4. Wieder abbauen"
podman kube down $W/blog.yaml >/dev/null 2>&1; echo "Pods danach: $(podman pod ps -q | wc -l)"
lab_down
