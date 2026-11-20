#!/usr/bin/env bash
# Abschlussprojekt (Modul 8): Notiz-Dienst mit Compose (Schreiber, Webserver, Volume), Sicherung, Datenverlust, Wiederherstellung, Abnahme.
. "$(dirname "$0")/../lab.sh"
lab_up; mkdir -p "$W/proj/web" "$W/sicherung" && cd "$W/proj"
cat > compose.yaml <<'Y'
name: p25
services:
  schreiber:
    image: p25/busybox:lab
    labels: { p25: "1" }
    command: sh -c 'echo "Notiz 1" > /daten/index.html; sleep 300'
    volumes: ["notizen:/daten"]
    read_only: true
    cap_drop: [ALL]
    mem_limit: 32m
  web:
    image: p25/busybox:lab
    labels: { p25: "1" }
    command: httpd -f -p 80 -h /daten
    volumes: ["notizen:/daten:ro"]
    ports: ["18088:80"]
    read_only: true
    cap_drop: [ALL]
    healthcheck: { test: ["CMD", "wget", "-qO-", "http://127.0.0.1/"], interval: 1s, retries: 5 }
volumes:
  notizen: { labels: { p25: "1" } }
Y
step "1. Starten und prüfen"
docker compose up -d >/dev/null 2>&1; sleep 3
docker compose ps --format '{{.Service}}: {{.State}} ({{.Health}})' | sort
curl -s http://127.0.0.1:18088/
step "2. Sicherung des Volumes"
docker run --rm --label p25=1 -v p25_notizen:/d:ro -v "$W/sicherung:/b" $B tar czf /b/notizen.tgz -C /d .
tar tzf "$W/sicherung/notizen.tgz" | sort | tr '\n' ' '; echo
step "3. Datenverlust: Projekt samt Volume entfernen"
docker compose down -v >/dev/null 2>&1
curl -s -m 2 http://127.0.0.1:18088/ >/dev/null 2>&1 && echo "Dienst antwortet noch" || echo "Dienst antwortet nicht mehr"
step "4. Wiederherstellung: Volume anlegen, Daten einspielen, Dienst starten (ohne den Schreiber)"
docker volume create --label p25=1 --label com.docker.compose.project=p25 --label com.docker.compose.volume=notizen p25_notizen >/dev/null
docker run --rm --label p25=1 -v p25_notizen:/d -v "$W/sicherung:/b:ro" $B tar xzf /b/notizen.tgz -C /d
docker compose up -d web >/dev/null 2>&1; sleep 3
curl -s http://127.0.0.1:18088/
step "5. Abnahme"
docker inspect -f 'web: read-only={{.HostConfig.ReadonlyRootfs}}, cap_drop={{.HostConfig.CapDrop}}' p25-web-1
docker compose ps --format '{{.Service}}: {{.State}} ({{.Health}})' | sort
