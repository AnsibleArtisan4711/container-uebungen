#!/usr/bin/env bash
# Modul 6: Ressourcenlimits, Logging und Sicherheit. Echt: --memory (OOM), --pids-limit, --cpus, Logrotation, read-only, cap-drop, user, no-new-privileges.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Speichergrenze: Der Container wird beendet (OOM, Exit-Code 137)"
docker run --name oom --label p25=1 --memory=16m --memory-swap=16m $B sh -c 'x=""; i=0; while [ $i -lt 40 ]; do x="$x$(head -c 1000000 /dev/zero | tr "\0" a)"; i=$((i+1)); done; echo fertig' >/dev/null 2>&1
docker inspect -f 'Exit-Code {{.State.ExitCode}}, OOMKilled: {{.State.OOMKilled}}' oom
step "2. Weitere Grenzen: Prozesse und CPU"
docker run --rm --label p25=1 --pids-limit=8 $B sh -c 'for i in 1 2 3 4 5 6 7 8 9 10 11 12; do sleep 2 & done 2>&1; echo ok' 2>&1 | sed -n '1p'
docker run -d --name cpu --label p25=1 --cpus=0.5 --memory=64m $B sleep 30 >/dev/null
docker inspect -f 'CPU-Grenze (Nano-CPUs): {{.HostConfig.NanoCpus}}, Speicher: {{.HostConfig.Memory}} Bytes' cpu
step "3. Logs: Treiber json-file mit Rotation"
docker run --name log --label p25=1 --log-opt max-size=1k --log-opt max-file=2 $B sh -c 'i=0; while [ $i -lt 300 ]; do echo "Zeile $i"; i=$((i+1)); done' >/dev/null
docker inspect -f 'Treiber: {{.HostConfig.LogConfig.Type}}, Optionen: {{.HostConfig.LogConfig.Config}}' log
ls "$(dirname "$(docker inspect -f '{{.LogPath}}' log)")" | grep -c json.log | sed 's/^/Logdateien: /'
docker logs --tail 2 log
step "4. Schreibschutz und Benutzer"
docker run --rm --label p25=1 --read-only $B sh -c 'echo x > /a' 2>&1 | sed 's/^sh: //'
docker run --rm --label p25=1 --read-only --tmpfs /tmp $B sh -c 'echo ok > /tmp/a; cat /tmp/a'
docker run --rm --label p25=1 --user 1000:1000 $B id
step "5. Rechte entziehen (capabilities) und no-new-privileges"
docker run --rm --label p25=1 $B sh -c 'grep CapEff /proc/self/status'
docker run --rm --label p25=1 --cap-drop ALL $B sh -c 'grep CapEff /proc/self/status'
docker run --rm --label p25=1 --security-opt no-new-privileges $B sh -c 'grep NoNewPrivs /proc/self/status'
docker run --rm --label p25=1 --cap-drop ALL $B sh -c 'chown 1:1 /etc/hostname' 2>&1 | sed 's/^chown: //'
step "6. Was der Daemon voreinstellt"
docker info --format 'Sicherheitsoptionen: {{range .SecurityOptions}}{{.}} {{end}}'
cat <<'T'
Nicht ausgeführt: Rootless-Docker, Schwachstellenscan von Images (kein Scanner im Container), AppArmor- und SELinux-Profile.
Der Zugriff auf den Docker-Socket entspricht root-Rechten auf dem Host (Fachwissen); --privileged und das Einbinden des Sockets
in Container vermeiden.
T
