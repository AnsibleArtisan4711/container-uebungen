#!/usr/bin/env bash
# Modul 8: Aufräumen, Sicherung von Daten, Betrieb. Echt: prune, system df, Volume sichern (tar im Container) und wiederherstellen, Prüfsumme.
. "$(dirname "$0")/../lab.sh"
lab_up; mkdir -p "$W/sicherung" && cd "$W"
step "1. Belegung ansehen (system df) und Reste erzeugen"
for i in 1 2 3; do docker run --name rest$i --label p25=1 $B true; done
docker volume create --label p25=1 ungenutzt >/dev/null
docker ps -a --filter label=p25 --format '{{.Names}}: {{.State}}' | sort
docker system df --format '{{.Type}}' | tr '\n' ' ' | sed 's/^/Arten in system df: /'; echo
step "2. Aufräumen: prune entfernt nur Ungenutztes"
docker container prune -f --filter label=p25 >/dev/null
docker ps -a --filter label=p25 -q | wc -l | sed 's/^/Container übrig: /'
docker volume prune -f --filter label=p25 >/dev/null
docker volume ls -q --filter label=p25 | wc -l | sed 's/^/Volumes übrig nach prune (nur anonyme werden entfernt): /'
docker volume prune -f --all --filter label=p25 >/dev/null
docker volume ls -q --filter label=p25 | wc -l | sed 's/^/Volumes übrig nach prune --all: /'
step "3. Daten eines Volumes sichern (tar im Container)"
docker volume create --label p25=1 daten >/dev/null
docker run --rm --label p25=1 -v daten:/d $B sh -c 'echo "Eintrag 1" > /d/a.txt; echo "Eintrag 2" > /d/b.txt; mkdir /d/sub; echo "tief" > /d/sub/c.txt'
docker run --rm --label p25=1 -v daten:/d:ro -v "$W/sicherung:/b" $B tar czf /b/daten.tgz -C /d .
ls sicherung
tar tzf sicherung/daten.tgz | sort | tr '\n' ' '; echo
docker run --rm --label p25=1 -v daten:/d:ro $B sh -c 'cd /d && find . -type f | sort | xargs cat | md5sum' | awk '{print "Prüfsumme vorher: " $1}'
step "4. Datenverlust und Wiederherstellung in ein neues Volume"
docker volume rm daten >/dev/null && echo "Volume daten gelöscht"
docker volume create --label p25=1 daten2 >/dev/null
docker run --rm --label p25=1 -v daten2:/d -v "$W/sicherung:/b:ro" $B tar xzf /b/daten.tgz -C /d
docker run --rm --label p25=1 -v daten2:/d:ro $B sh -c 'cd /d && find . -type f | sort | xargs cat | md5sum' | awk '{print "Prüfsumme nachher: " $1}'
docker run --rm --label p25=1 -v daten2:/d:ro $B cat /d/sub/c.txt
step "5. Neustartrichtlinie und Selbstheilung"
docker run -d --name dienst --label p25=1 --restart on-failure:2 $B sh -c 'exit 1' >/dev/null; sleep 4
docker inspect -f 'Neustarts: {{.RestartCount}}, Zustand: {{.State.Status}}, Richtlinie: {{.HostConfig.RestartPolicy.Name}}:{{.HostConfig.RestartPolicy.MaximumRetryCount}}' dienst
cat <<'T'
Nicht ausgeführt: Sicherung auf einen anderen Rechner, Verschlüsselung der Sicherung, automatischer Zeitplan (cron, systemd-Timer),
Überwachung der Container. Ein Volume im selben Rechner ist keine Sicherung (3-2-1-Regel: siehe Backup-Kurse).
T
