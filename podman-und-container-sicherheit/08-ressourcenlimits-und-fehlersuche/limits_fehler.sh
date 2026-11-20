#!/usr/bin/env bash
# Ressourcenlimits (cgroup v1 im Test-Container) und typische Fehler mit Meldung und Exitcode (Image aus busybox, erfundene Daten).
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up
step "1. Speicherlimit: --memory 64m (Wert aus dem cgroup-Dateisystem im Container)"
podman run --rm --memory 64m $IMG sh -c 'cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || cat /sys/fs/cgroup/memory.max'
step "2. Prozesslimit: --pids-limit 10, danach schlägt das Starten weiterer Prozesse fehl"
podman run --rm --pids-limit 10 $IMG sh -c 'n=0; while [ $n -lt 30 ]; do sleep 5 & n=$((n+1)); done 2>&1; echo fertig' 2>&1 | grep -E "can't fork|Resource temporarily|fertig" | sort -u | head -3
step "3. Speicherlimit überschritten: Container wird beendet (Exitcode 137); Podman meldet trotzdem OOMKilled=false (Beobachtung dieses Laufs)"
podman run --name oom --memory 20m --memory-swap 20m --tmpfs /t:size=100m $IMG sh -c 'dd if=/dev/zero of=/t/f bs=1M count=60' >/dev/null 2>&1; echo "Exitcode: $?"
podman inspect -f 'OOMKilled={{.State.OOMKilled}}' oom; podman rm oom >/dev/null
step "4. Typische Fehler"
echo "Image nicht vorhanden:"; podman run --rm --pull=never localhost/gibtesnicht:1 true 2>&1 | grep -E "^Error" | head -1 | cut -c1-110
echo "Befehl nicht gefunden:"; podman run --rm $IMG gibtesnicht 2>&1 | grep -E "^Error" | head -1 | cut -c1-110; podman run --rm $IMG gibtesnicht >/dev/null 2>&1; echo "Exitcode: $?"
echo "Name schon vergeben:"; podman run -d --name dopp $IMG sleep 30 >/dev/null; podman run -d --name dopp $IMG sleep 30 2>&1 | grep -E "^Error" | sed -E 's/by [0-9a-f]+.*/by <ID>/' | cut -c1-110
podman rm -f -t 0 dopp >/dev/null 2>&1
echo "Programm im Container beendet sich mit Fehler:"; podman run --name f1 $IMG sh -c 'echo Fehlermeldung >&2; exit 2' 2>&1; podman inspect -f 'ExitCode={{.State.ExitCode}}' f1; podman rm f1 >/dev/null
lab_down
