#!/usr/bin/env bash
# Images bauen (Containerfile, buildah) und prüfen/kopieren (skopeo, lokale Transporte dir: und oci:). Basis: busybox-Image, erfundene Daten.
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up; mkdir -p $W/ctx
echo "Version 1.0" > $W/ctx/version.txt
cat > $W/ctx/Containerfile <<'EOF'
FROM localhost/bb:1
LABEL beschreibung="Beispiel-Image"
COPY version.txt /app/version.txt
ENV MELDUNG=hallo
RUN echo "gebaut" > /app/status.txt
CMD ["cat", "/app/version.txt"]
EOF
step "1. Mit Containerfile bauen und starten"
podman build -q -t localhost/app:1 $W/ctx >/dev/null 2>&1; echo "Exitcode build: $?"
cmd podman run --rm localhost/app:1
step "2. Ebenen (Schichten) und Befehle des Images (podman history, gekürzt)"
podman history --format '{{.CreatedBy}}' localhost/app:1 | cut -c1-60 | sed -E 's#/bin/sh -c \#\(nop\) ##; s#file:[0-9a-f]+[.]*#file:<Hash>#'
step "3. Eigenschaften lesen (inspect)"
podman inspect -f 'Label={{index .Config.Labels "beschreibung"}} Cmd={{.Config.Cmd}}' localhost/app:1
step "4. Dasselbe mit buildah: Container aus Image, Befehl ausführen, als neues Image sichern"
c=$(buildah from localhost/bb:1 2>/dev/null)
buildah run $c -- sh -c 'echo aus-buildah > /datei.txt' 2>/dev/null
buildah commit -q $c localhost/app:2 >/dev/null 2>&1; buildah rm $c >/dev/null
cmd podman run --rm localhost/app:2 cat /datei.txt
step "5. Mit skopeo ohne Registry in ein Verzeichnis bzw. OCI-Layout kopieren und lesen"
skopeo copy -q containers-storage:localhost/app:1 dir:$W/dir_app >/dev/null 2>&1; echo "dir: Exitcode $?"
skopeo copy -q containers-storage:localhost/app:1 oci:$W/oci_app:eins >/dev/null 2>&1; echo "oci: Exitcode $?"
ls $W/oci_app | sort
python3 - <<PY
import json
i = json.load(open("$W/oci_app/index.json"))
print("OCI-Index:", i["manifests"][0]["mediaType"].split(".")[-1], "- Referenzname:", i["manifests"][0]["annotations"]["org.opencontainers.image.ref.name"])
PY
skopeo inspect --config containers-storage:localhost/app:1 2>/dev/null | python3 -c 'import json,sys; c=json.load(sys.stdin); print("Architektur:", c["architecture"], "- Betriebssystem:", c["os"], "- Ebenen (rootfs):", len(c["rootfs"]["diff_ids"]))'
lab_down
