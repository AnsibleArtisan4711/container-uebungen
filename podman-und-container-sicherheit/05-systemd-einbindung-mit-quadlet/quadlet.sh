#!/usr/bin/env bash
# Quadlet: aus .container-, .volume- und .network-Dateien erzeugt der Generator systemd-Units. Hier nur der Probelauf (-dryrun); systemd selbst lief im Container nicht.
cd "$(dirname "$0")" || exit 1
. ../lab.sh
lab_up; mkdir -p $W/q
cat > $W/q/web.container <<'EOF'
[Unit]
Description=Beispiel-Webserver
[Container]
Image=localhost/bb:1
Exec=httpd -f -p 8080 -h /www
PublishPort=8080:8080
Volume=webdaten.volume:/www
Network=lab.network
[Service]
Restart=always
[Install]
WantedBy=multi-user.target
EOF
printf '[Volume]\n' > $W/q/webdaten.volume
printf '[Network]\nSubnet=10.53.0.0/24\n' > $W/q/lab.network
step "1. Probelauf des Generators (Version von Podman: $(podman --version | cut -d' ' -f3))"
QUADLET_UNIT_DIRS=$W/q /usr/libexec/podman/quadlet -dryrun 2>&1 | sed 's#/tmp/p53#<W>#g; s/\[[0-9]*\]//' > $W/out.txt
grep -E "^---|Loading source" $W/out.txt
step "2. Erzeugte Unit web.service (Auszug)"
awk '/^---web.service---/{f=1;next} /^---/{f=0} f' $W/out.txt | grep -E "^(Description|Requires|After|Restart|ExecStart|Type|WantedBy)="
step "3. Erzeugte Unit webdaten-volume.service (Auszug)"
awk '/^---webdaten-volume.service---/{f=1;next} /^---/{f=0} f' $W/out.txt | grep -E "^(ExecStart|Type|RemainAfterExit)="
lab_down
