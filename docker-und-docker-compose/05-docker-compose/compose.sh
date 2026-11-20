#!/usr/bin/env bash
# Modul 5: Docker Compose. Echt: docker compose (config, up, ps, exec, logs, down), Healthcheck, depends_on, Umgebungsvariablen.
. "$(dirname "$0")/../lab.sh"
lab_up; mkdir -p "$W/stack/www" && cd "$W/stack"
echo "Willkommen" > www/index.html
cat > compose.yaml <<'Y'
name: p25
services:
  web:
    image: p25/busybox:lab
    command: httpd -f -p 80 -h /www
    labels: { p25: "1" }
    volumes: ["./www:/www:ro"]
    environment:
      GREETING: ${GREETING:-Hallo}
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1/"]
      interval: 1s
      retries: 5
    networks: [intern]
  client:
    image: p25/busybox:lab
    labels: { p25: "1" }
    command: sh -c 'wget -qO- http://web/; sleep 60'
    depends_on:
      web: { condition: service_healthy }
    networks: [intern]
networks:
  intern: { labels: { p25: "1" } }
Y
step "1. Datei prüfen (config) und Dienste auflisten"
docker compose config --services | sort
docker compose config -q && echo "Datei gültig"
step "2. Starten (up -d) und Zustand"
docker compose up -d >/dev/null 2>&1
sleep 3
docker compose ps --format '{{.Service}}: {{.State}} ({{.Health}})' | sort
step "3. Abhängigkeit: client wartet, bis web gesund ist; Antwort des Clients"
docker compose logs client --no-log-prefix 2>&1 | head -2
step "4. Befehl im Dienst (exec) und Umgebungsvariable mit Vorgabe"
docker compose exec web sh -c 'echo "GREETING=$GREETING"'
GREETING=Servus docker compose up -d --force-recreate web >/dev/null 2>&1; sleep 2
docker compose exec web sh -c 'echo "GREETING=$GREETING"'
step "5. Netz und Container gehören zum Projekt p25"
docker network ls --filter label=p25 --format 'Netz: {{.Name}}'
docker ps --filter label=p25 --format 'Container: {{.Names}}' | sort
step "6. Beenden (down) entfernt Container und Netz"
docker compose down >/dev/null 2>&1
docker ps -a --filter label=p25 --format '{{.Names}}' | wc -l | sed 's/^/Container übrig: /'
docker network ls --filter label=p25 -q | wc -l | sed 's/^/Netze übrig: /'
