#!/usr/bin/env bash
# Rootless-Container: Benutzer rl1 ohne Rechte, Benutzer-Namensraum, Zuordnung der Nummern, Speicherort (Image aus busybox, erfundene Daten).
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up; useradd -m $RL
podman save -o $W/bb.tar $IMG >/dev/null 2>&1; chmod 644 $W/bb.tar
mask() { sed -E "s/$(id -u $RL)/<UID>/g; s/$(grep "^$RL:" /etc/subuid | cut -d: -f2)/<SUBUID>/g"; }
step "1. Der Benutzer hat einen Bereich untergeordneter Nummern (/etc/subuid, Nummern ausgeblendet)"
grep "^$RL:" /etc/subuid | mask | sed 's/:65536$/:65536 (Anzahl)/'
step "2. Image für den Benutzer laden und Container starten (ohne Netzwerk)"
rl "podman load -i $W/bb.tar" | tail -1
rl "podman run --rm --network=none $IMG id"
step "3. Zuordnung der Benutzernummern (uid_map): Container-root ist auf dem Host der Benutzer"
rl "podman run --rm --network=none $IMG cat /proc/self/uid_map" | mask
step "4. Auf dem Host läuft der Prozess unter dem Benutzer, nicht unter root"
rl "podman run -d --name s1 --network=none $IMG sleep 20 >/dev/null; ps -o user:12= -C sleep | head -1; podman rm -f -t 0 s1 >/dev/null"
step "5. Eigener Speicher des Benutzers (Pfad unter dem Home-Verzeichnis)"
rl "podman info --format '{{.Store.GraphRoot}}'" | sed "s#/home/$RL#~#"
step "6. Mit Netzwerk scheitert es im Container (kein /dev/net/tun für slirp4netns)"
rl "podman run --rm $IMG true" | grep -q 'dev/net/tun' && echo 'Fehler von slirp4netns: open /dev/net/tun: Permission denied'
lab_down
