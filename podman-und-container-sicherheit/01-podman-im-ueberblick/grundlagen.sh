#!/usr/bin/env bash
# Erste Container mit Podman: starten, auflisten, Befehl ausführen, Protokoll, Beenden und Exitcode (Image aus busybox, erfundene Daten).
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up
step "1. Image vorhanden (Name und Größe; Kennung und Alter ausgeblendet)"
podman images --format '{{.Repository}}:{{.Tag}} {{.Size}}'
step "2. Einen Befehl im Container ausführen und den Container danach entfernen (--rm)"
cmd podman run --rm $IMG echo "Hallo aus dem Container"
step "3. Dauerhaft laufender Container im Hintergrund (-d), Name, Liste"
podman run -d --name web1 $IMG sh -c 'echo gestartet; sleep 300' >/dev/null
podman ps --format '{{.Names}} {{.Image}} {{.Status}}' | sed -E 's/Up [A-Za-z0-9 ]+/Up .../'
step "4. Befehl in laufendem Container (exec) und Protokoll (logs)"
cmd podman exec web1 hostname | sed -E 's/^[0-9a-f]{12}$/<ID>/'
cmd podman logs web1
step "5. Container beenden, Exitcode, entfernen"
podman stop -t 1 web1 >/dev/null 2>&1; podman ps -a --format '{{.Names}} {{.Status}}' | sed -E 's/\(([0-9]+)\).*/(\1)/;s/ ago//' ; podman inspect -f 'ExitCode={{.State.ExitCode}}' web1
cmd podman rm web1
step "6. Exitcode eines Programms im Container wird weitergegeben"
podman run --rm $IMG sh -c 'exit 3'; echo "Exitcode: $?"
lab_down
