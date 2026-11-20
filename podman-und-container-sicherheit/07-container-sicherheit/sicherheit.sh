#!/usr/bin/env bash
# Sicherheit: Capabilities, Nur-Lesen, no-new-privileges, seccomp, Richtlinie für Image-Signaturen (Image aus busybox, erfundene Daten).
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up
cap() { podman run --rm "$@" $IMG sh -c 'grep CapEff /proc/self/status | cut -f2'; }
step "1. Capabilities: Standard und alle entfernt (CapEff als Hexzahl)"
echo "Standard:       $(cap)"
echo "--cap-drop=ALL: $(cap --cap-drop=ALL)"
step "2. Eine Capability gezielt entfernen: Ändern des Besitzers (chown) scheitert ohne CAP_CHOWN"
echo "mit Standard-Capabilities: $(podman run --rm $IMG sh -c 'touch /f && chown 1000 /f 2>&1 && echo chown-ok' | tr '\n' ' ')"
echo "ohne CAP_CHOWN:            $(podman run --rm --cap-drop=CHOWN $IMG sh -c 'touch /f && chown 1000 /f 2>&1 && echo chown-ok' | tr '\n' ' ')"
step "3. Dateisystem nur lesbar (--read-only)"
podman run --rm --read-only $IMG sh -c 'touch /x' 2>&1 | sed 's#^touch: ##'
step "4. Keine neuen Rechte (--security-opt no-new-privileges), Wert aus /proc/self/status"
echo "Standard:        NoNewPrivs=$(podman run --rm $IMG sh -c 'grep NoNewPrivs /proc/self/status | cut -f2')"
echo "no-new-privs:    NoNewPrivs=$(podman run --rm --security-opt no-new-privileges $IMG sh -c 'grep NoNewPrivs /proc/self/status | cut -f2')"
step "5. seccomp-Filter: Standardprofil gegen unconfined (Seccomp-Zeile aus /proc/self/status: 2 = Filter aktiv, 0 = aus)"
echo "Standard:   Seccomp=$(podman run --rm $IMG sh -c 'grep ^Seccomp: /proc/self/status | cut -f2')"
echo "unconfined: Seccomp=$(podman run --rm --security-opt seccomp=unconfined $IMG sh -c 'grep ^Seccomp: /proc/self/status | cut -f2')"
step "6. Als Nicht-root im Container laufen (--user)"
podman run --rm --user 1000:1000 $IMG id
step "7. Richtlinie für Image-Signaturen (/etc/containers/policy.json, Auszug)"
python3 -c 'import json; p=json.load(open("/etc/containers/policy.json")); print("Standard:", p["default"][0]["type"])'
lab_down
